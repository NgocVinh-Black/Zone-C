.pragma library

function getScale(mw, mh, userScale) {
    return (userScale !== undefined && userScale !== null) ? userScale : 1.0;
}

function s(val, scale) {
    return Math.round(val * scale);
}

function getWidgetLauncherEntries(i18n) {
    function tr(key, fallback) {
        if (i18n && typeof i18n.t === "function") {
            let res = i18n.t(key);
            if (res && res !== key) return res;
        }
        return fallback;
    }

    return [
        {
            id: "wallpaper",
            name: tr("widgets.wallpaper.name", "Wallpaper Picker"),
            description: tr("widgets.wallpaper.desc", "Browse and set desktop wallpaper"),
            icon: "preferences-desktop-wallpaper",
            fontIcon: "󰸉"
        },
        {
            id: "network",
            name: tr("widgets.network.name", "Network Settings"),
            description: tr("widgets.network.desc", "Manage WiFi, Ethernet, and network connections"),
            icon: "network-wireless",
            fontIcon: "󰤨"
        },
        {
            id: "volume",
            name: tr("widgets.volume.name", "Volume & Audio"),
            description: tr("widgets.volume.desc", "Manage sound devices and volume levels"),
            icon: "audio-volume-high",
            fontIcon: "󰕾"
        },
        {
            id: "guide",
            name: tr("widgets.guide.name", "Settings"),
            description: tr("widgets.guide.desc", "Zone-C settings"),
            icon: "help-browser",
            fontIcon: "󰋖"
        },
        {
            id: "calendar",
            name: tr("widgets.calendar.name", "Calendar & Clock"),
            description: tr("widgets.calendar.desc", "View date, time, and schedule"),
            icon: "x-office-calendar",
            fontIcon: "󰸗"
        },
        {
            id: "music",
            name: tr("widgets.music.name", "Media Player"),
            description: tr("widgets.music.desc", "Control music and media playback"),
            icon: "multimedia-audio-player",
            fontIcon: "󰝚"
        },
        {
            id: "system",
            name: tr("widgets.system.name", "System Controls"),
            description: tr("widgets.system.desc", "Performance monitor, power, and quick settings"),
            icon: "preferences-system",
            fontIcon: "󰒓"
        }
    ];
}

function getLayout(name, mx, my, mw, mh, userScale, barPosition) {
    let scale = (userScale !== undefined && userScale !== null) ? userScale : 1.0;
    if (!barPosition) barPosition = "top";

    let base = {
        "network": { 
            w: 430, h: 600, comp: "network/FrostNetwork.qml", 
            pos: { 
                "top": { anchor: "top-right", mt: 58, mr: 120 }, 
                "bottom": { anchor: "bottom-right", mb: 58, mr: 120 }, 
                "left": { anchor: "bottom-left", ml: 70, mb: 10 }, 
                "right": { anchor: "bottom-right", mr: 70, mb: 10 } 
            } 
        },
        "volume": { 
            w: 420, h: 580, comp: "volume/FrostVolume.qml", 
            pos: { 
                "top": { anchor: "top-right", mt: 58, mr: 60 }, 
                "bottom": { anchor: "bottom-right", mb: 58, mr: 60 }, 
                "left": { anchor: "bottom-left", ml: 70, mb: 10 }, 
                "right": { anchor: "bottom-right", mr: 70, mb: 10 } 
            } 
        },
        "calendar": { 
            w: 1360, h: 560, comp: "calendar/FrostCalendar.qml", 
            pos: { 
                "top": { anchor: "top-center", mt: 60 }, 
                "bottom": { anchor: "bottom-center", mb: 58 }, 
                "left": { anchor: "top-center", mt: 12 }, 
                "right": { anchor: "top-center", mt: 12 } 
            } 
        },
        "wallpaper": { 
            w: "fill", h: "fill", comp: "wallpaper/FrostWallpaper.qml", 
            pos: { 
                "top": { anchor: "fill", mt: 52 }, 
                "bottom": { anchor: "fill", mb: 52 }, 
                "left": { anchor: "fill", ml: 60 }, 
                "right": { anchor: "fill", mr: 60 } 
            } 
        },
        "music": { 
            w: 600, h: 320, comp: "media/FrostMusic.qml", 
            pos: { 
                "top": { anchor: "top-left", mt: 60, ml: 12 }, 
                "bottom": { anchor: "bottom-left", mb: 58, ml: 12 }, 
                "left": { anchor: "top-left", mt: 10, ml: 70 }, 
                "right": { anchor: "top-right", mt: 10, mr: 70 } 
            } 
        },
        "notifications": { 
            w: 500, h: "fill", comp: "notifications/NotificationCenter.qml", 
            pos: { 
                "top": { anchor: "left" }, 
                "bottom": { anchor: "left" }, 
                "left": { anchor: "left" }, 
                "right": { anchor: "left" } 
            } 
        },
        "system": { 
            w: 456, h: "fill", comp: "syspanel/FrostSystemPanel.qml", 
            pos: { 
                "top": { anchor: "top-right", mt: 58, mb: 10, mr: 10 }, 
                "bottom": { anchor: "top-right", mt: 10, mb: 58, mr: 10 }, 
                "left": { anchor: "top-right", mt: 10, mb: 10, mr: 10 }, 
                "right": { anchor: "top-left", mt: 10, mb: 10, ml: 10 } 
            } 
        },
        "hidden": { 
            w: 1, h: 1, comp: "", 
            pos: { 
                "top": { anchor: "hidden" }, 
                "bottom": { anchor: "hidden" }, 
                "left": { anchor: "hidden" }, 
                "right": { anchor: "hidden" } 
            } 
        }
    };

    if (!base[name]) return null;
    let t = base[name];
    let p = t.pos[barPosition] || t.pos["top"];

    let finalW = t.w === "fill" ? mw - s(p.ml || 0, scale) - s(p.mr || 0, scale) : s(t.w, scale);
    let finalH = t.h === "fill" ? mh - s(p.mt || 0, scale) - s(p.mb || 0, scale) : s(t.h, scale);

    let rx = 0;
    let ry = 0;

    switch (p.anchor) {
        case "center":
            rx = Math.floor((mw / 2) - (finalW / 2));
            ry = Math.floor((mh / 2) - (finalH / 2));
            break;
        case "top-right":
            rx = mw - finalW - s(p.mr || 0, scale);
            ry = s(p.mt || 0, scale);
            break;
        case "bottom-right":
            rx = mw - finalW - s(p.mr || 0, scale);
            ry = mh - finalH - s(p.mb || 0, scale);
            break;
        case "top-left":
            rx = s(p.ml || 0, scale);
            ry = s(p.mt || 0, scale);
            break;
        case "bottom-left":
            rx = s(p.ml || 0, scale);
            ry = mh - finalH - s(p.mb || 0, scale);
            break;
        case "top-center":
            rx = Math.floor((mw / 2) - (finalW / 2));
            ry = s(p.mt || 0, scale);
            break;
        case "bottom-center":
            rx = Math.floor((mw / 2) - (finalW / 2));
            ry = mh - finalH - s(p.mb || 0, scale);
            break;
        case "left":
            rx = s(p.ml || 0, scale);
            ry = Math.floor((mh / 2) - (finalH / 2));
            break;
        case "right":
            rx = mw - finalW - s(p.mr || 0, scale);
            ry = Math.floor((mh / 2) - (finalH / 2));
            break;
        case "center-left":
            rx = s(p.ml || 0, scale);
            ry = Math.floor((mh / 2) - (finalH / 2));
            break;
        case "center-right":
            rx = mw - finalW - s(p.mr || 0, scale);
            ry = Math.floor((mh / 2) - (finalH / 2));
            break;
        case "fill":
            rx = s(p.ml || 0, scale);
            ry = s(p.mt || 0, scale);
            break;
        case "hidden":
            rx = -5000;
            ry = -5000;
            break;
    }

    return { w: finalW, h: finalH, rx: mx + rx, ry: my + ry, comp: t.comp, draggable: Boolean(t.draggable) };
}

function getPopupLayout(mw, mh, userScale) {
    let scale = (userScale !== undefined && userScale !== null) ? userScale : 1.0;
    return {
        w: s(350, scale), marginTop: s(52, scale), marginRight: s(20, scale),
        spacing: s(12, scale), radius: s(14, scale), padding: s(12, scale)
    };
}
