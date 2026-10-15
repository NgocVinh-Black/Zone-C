#!/usr/bin/env python3
"""Zone-C backend for xdg-desktop-portal: org.freedesktop.impl.portal.FileChooser.

Each request is written to a JSON file and shown by the shell (`zone-c ipc call portal fileChooser`);
the shell answers in <file>.out. Registered by zonec.portal and the D-Bus activation file.
"""
import json
import mimetypes
import os
import subprocess
import tempfile
import urllib.parse

import gi
gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

BUS_NAME = "org.freedesktop.impl.portal.desktop.zonec"
OBJ_PATH = "/org/freedesktop/portal/desktop"
XML = """
<node>
  <interface name="org.freedesktop.impl.portal.FileChooser">
    <method name="OpenFile">
      <arg type="o" name="handle" direction="in"/><arg type="s" name="app_id" direction="in"/>
      <arg type="s" name="parent_window" direction="in"/><arg type="s" name="title" direction="in"/>
      <arg type="a{sv}" name="options" direction="in"/>
      <arg type="u" name="response" direction="out"/><arg type="a{sv}" name="results" direction="out"/>
    </method>
    <method name="SaveFile">
      <arg type="o" name="handle" direction="in"/><arg type="s" name="app_id" direction="in"/>
      <arg type="s" name="parent_window" direction="in"/><arg type="s" name="title" direction="in"/>
      <arg type="a{sv}" name="options" direction="in"/>
      <arg type="u" name="response" direction="out"/><arg type="a{sv}" name="results" direction="out"/>
    </method>
    <method name="SaveFiles">
      <arg type="o" name="handle" direction="in"/><arg type="s" name="app_id" direction="in"/>
      <arg type="s" name="parent_window" direction="in"/><arg type="s" name="title" direction="in"/>
      <arg type="a{sv}" name="options" direction="in"/>
      <arg type="u" name="response" direction="out"/><arg type="a{sv}" name="results" direction="out"/>
    </method>
    <property name="version" type="u" access="read"/>
  </interface>
</node>
"""
STATE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", tempfile.gettempdir()), "zone-c", "portal")


def app_name(app_id):
    if not app_id:
        return "Ứng dụng"
    info = Gio.DesktopAppInfo.new(app_id + ".desktop")
    return info.get_display_name() if info else app_id.split(".")[-1]


def bytes_path(v):
    """current_folder / current_file are NUL-terminated byte arrays."""
    try:
        return bytes(v).rstrip(b"\0").decode()
    except Exception:
        return ""


def exts_of(options):
    """First filter's glob patterns (type 0) -> extensions; mime types (type 1) via Gio."""
    flt = options.get("current_filter") or (options.get("filters") or [None])[0]
    if not flt:
        return [], ""
    label, rules = flt
    out = []
    for kind, pat in rules:
        if kind == 0 and pat.startswith("*."):
            out.append(pat[2:].lower())
        elif kind == 1:
            out += [e.lstrip(".") for e in mimetypes.guess_all_extensions(pat)]
    return out, label


def handle(invocation, method, params):
    handle_path, app_id, _parent, title, options = params.unpack()
    mode = "save" if method != "OpenFile" else ("folder" if options.get("directory") else "open")
    exts, label = exts_of(options)
    req = {"app": app_name(app_id), "title": title, "mode": mode, "exts": exts,
           "filterLabel": (label + " (" + ", ".join("*." + e for e in exts) + ")") if label and exts else "",
           "folder": bytes_path(options.get("current_folder", b"")) or os.path.expanduser("~"),
           "name": options.get("current_name", "")}
    if method == "SaveFile" and options.get("current_file"):
        cur = bytes_path(options["current_file"])
        req["folder"], req["name"] = os.path.dirname(cur), os.path.basename(cur)
    os.makedirs(STATE, exist_ok=True)
    fd, path = tempfile.mkstemp(prefix="req-", suffix=".json", dir=STATE)
    with os.fdopen(fd, "w") as f:
        json.dump(req, f, ensure_ascii=False)
    subprocess.Popen(["zone-c", "ipc", "call", "portal", "fileChooser", path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def poll():
        out = path + ".out"
        if not os.path.exists(out):
            return True
        try:
            with open(out) as f:
                ans = json.load(f)
        except Exception:
            ans = {"cancel": True}
        for p in (path, out):
            try:
                os.unlink(p)
            except OSError:
                pass
        if ans.get("cancel") or not ans.get("paths"):
            invocation.return_value(GLib.Variant("(ua{sv})", (1, {})))
        else:
            paths = ans["paths"]
            if method == "SaveFiles":
                names = [bytes_path(n) for n in options.get("files", [])]
                paths = [os.path.join(paths[0], n) for n in names]
            uris = ["file://" + urllib.parse.quote(p) for p in paths]
            invocation.return_value(GLib.Variant("(ua{sv})", (0, {"uris": GLib.Variant("as", uris)})))
        return False

    GLib.timeout_add(150, poll)


def on_call(conn, sender, path, iface, method, params, invocation):
    handle(invocation, method, params)


def on_get(conn, sender, path, iface, prop):
    return GLib.Variant("u", 3) if prop == "version" else None


def on_bus(conn, name):
    node = Gio.DBusNodeInfo.new_for_xml(XML)
    conn.register_object(OBJ_PATH, node.interfaces[0], on_call, on_get, None)


def main():
    Gio.bus_own_name(Gio.BusType.SESSION, BUS_NAME, Gio.BusNameOwnerFlags.NONE, on_bus, None, lambda *a: loop.quit())
    loop.run()


loop = GLib.MainLoop()
if __name__ == "__main__":
    main()
