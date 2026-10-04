#!/usr/bin/env python3
# Agent ghep doi BlueZ cho panel Bluetooth.
# Moi yeu cau xac nhan duoc in ra stdout (JSON moi dong), panel tra loi qua stdin:
#   {"id": 1, "ok": true, "value": "123456"}
import json
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib

AGENT_PATH = "/org/zonec/BtAgent"
CAPABILITY = "KeyboardDisplay"

AGENT_XML = """
<node>
  <interface name="org.bluez.Agent1">
    <method name="Release"/>
    <method name="RequestPinCode">
      <arg type="o" direction="in"/><arg type="s" direction="out"/>
    </method>
    <method name="DisplayPinCode">
      <arg type="o" direction="in"/><arg type="s" direction="in"/>
    </method>
    <method name="RequestPasskey">
      <arg type="o" direction="in"/><arg type="u" direction="out"/>
    </method>
    <method name="DisplayPasskey">
      <arg type="o" direction="in"/><arg type="u" direction="in"/><arg type="q" direction="in"/>
    </method>
    <method name="RequestConfirmation">
      <arg type="o" direction="in"/><arg type="u" direction="in"/>
    </method>
    <method name="RequestAuthorization">
      <arg type="o" direction="in"/>
    </method>
    <method name="AuthorizeService">
      <arg type="o" direction="in"/><arg type="s" direction="in"/>
    </method>
    <method name="Cancel"/>
  </interface>
</node>
"""

bus = Gio.bus_get_sync(Gio.BusType.SYSTEM, None)
pending = {}  # id -> (invocation, type)
next_id = 0


def emit(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def device_prop(path, name):
    try:
        res = bus.call_sync("org.bluez", path, "org.freedesktop.DBus.Properties", "Get",
                            GLib.Variant("(ss)", ("org.bluez.Device1", name)),
                            GLib.VariantType("(v)"), Gio.DBusCallFlags.NONE, 2000, None)
        return res.unpack()[0]
    except GLib.Error:
        return None


def device_info(path):
    address = device_prop(path, "Address") or ""
    name = device_prop(path, "Alias") or address
    return {"device": path, "address": address, "name": name}


def reject(invocation, error="org.bluez.Error.Canceled"):
    invocation.return_dbus_error(error, "Request canceled")


def cancel_all():
    for invocation, _ in pending.values():
        reject(invocation)
    pending.clear()


def ask(invocation, kind, path, **extra):
    global next_id
    # Chi giu mot yeu cau mot luc, yeu cau cu coi nhu bi huy
    cancel_all()
    next_id += 1
    pending[next_id] = (invocation, kind)
    emit({"id": next_id, "type": kind, **device_info(path), **extra})


def on_method_call(conn, sender, obj_path, iface, method, params, invocation):
    args = params.unpack()
    if method == "Release":
        cancel_all()
        invocation.return_value(None)
    elif method == "Cancel":
        cancel_all()
        emit({"type": "cancel"})
        invocation.return_value(None)
    elif method == "RequestPinCode":
        ask(invocation, "pin", args[0])
    elif method == "RequestPasskey":
        ask(invocation, "passkey", args[0])
    elif method == "RequestConfirmation":
        ask(invocation, "confirm", args[0], passkey="%06d" % args[1])
    elif method == "RequestAuthorization":
        ask(invocation, "authorize", args[0])
    elif method == "AuthorizeService":
        # Thiet bi da tin cay thi cho qua luon, giong blueman
        if device_prop(args[0], "Trusted"):
            invocation.return_value(None)
        else:
            ask(invocation, "authorize", args[0])
    elif method == "DisplayPinCode":
        emit({"type": "display", **device_info(args[0]), "passkey": args[1]})
        invocation.return_value(None)
    elif method == "DisplayPasskey":
        emit({"type": "display", **device_info(args[0]), "passkey": "%06d" % args[1], "entered": args[2]})
        invocation.return_value(None)


def on_reply(line):
    try:
        msg = json.loads(line)
    except ValueError:
        return
    entry = pending.pop(msg.get("id"), None)
    if not entry:
        return
    invocation, kind = entry
    if not msg.get("ok"):
        reject(invocation, "org.bluez.Error.Rejected")
        return
    value = str(msg.get("value", "")).strip()
    try:
        if kind == "pin":
            invocation.return_value(GLib.Variant("(s)", (value,)))
        elif kind == "passkey":
            invocation.return_value(GLib.Variant("(u)", (int(value),)))
        else:
            invocation.return_value(None)
    except ValueError:
        reject(invocation, "org.bluez.Error.Rejected")


def on_stdin(channel, condition):
    if condition & (GLib.IO_HUP | GLib.IO_ERR):
        loop.quit()
        return False
    line = sys.stdin.readline()
    if not line:
        loop.quit()
        return False
    on_reply(line)
    return True


def register(*_):
    try:
        for method, args in (("RegisterAgent", GLib.Variant("(os)", (AGENT_PATH, CAPABILITY))),
                             ("RequestDefaultAgent", GLib.Variant("(o)", (AGENT_PATH,)))):
            bus.call_sync("org.bluez", "/org/bluez", "org.bluez.AgentManager1", method,
                          args, None, Gio.DBusCallFlags.NONE, 5000, None)
        emit({"type": "ready"})
    except GLib.Error as e:
        print("bt_agent: register failed: " + e.message, file=sys.stderr)


node = Gio.DBusNodeInfo.new_for_xml(AGENT_XML)
bus.register_object_with_closures2(AGENT_PATH, node.interfaces[0], on_method_call, None, None)

# Dang ky lai moi khi bluetoothd khoi dong lai
Gio.bus_watch_name_on_connection(bus, "org.bluez", Gio.BusNameWatcherFlags.NONE, register, None)

loop = GLib.MainLoop()
GLib.io_add_watch(GLib.IOChannel.unix_new(sys.stdin.fileno()), GLib.PRIORITY_DEFAULT,
                  GLib.IO_IN | GLib.IO_HUP | GLib.IO_ERR, on_stdin)
loop.run()
