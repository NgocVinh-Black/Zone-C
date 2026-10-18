import QtQuick
import Quickshell
import Quickshell.Io
import "../"
import "../../"
import "../../frost"

// Ngôn ngữ & vùng: system LANG and the formats region (localectl, polkit), with a live preview.
Column {
    id: page
    property var app
    width: parent ? parent.width : 0

    property var d: ({})
    property var locales: []
    Process {
        id: probe
        running: true
        command: ["bash", "-c", "localectl status 2>/dev/null | sed -n 's/.*System Locale: //p' | tr ' ' '\\n'; echo '#'; locale -a 2>/dev/null | grep -i utf"]
        stdout: StdioCollector {
            onStreamFinished: {
                let p = this.text.split("#\n"), o = {};
                p[0].split("\n").forEach(l => { let i = l.indexOf("="); if (i > 0) o[l.slice(0, i).trim()] = l.slice(i + 1).trim(); });
                page.d = o;
                page.locales = (p[1] || "").trim().split("\n").filter(x => x && !/^C\./i.test(x)).map(x => x.replace(/\.utf8$/i, ".UTF-8"));
            }
        }
    }
    Process { id: run; onExited: probe.running = true }
    readonly property var names: ({ "vi_VN": Fz.tr("Tiếng Việt"), "en_US": "English (US)", "en_GB": "English (UK)", "de_DE": "Deutsch", "fr_FR": Fz.tr("Français"), "ja_JP": "日本語", "ko_KR": "한국어", "zh_CN": "中文 (简体)" })
    readonly property var regions: ({ "vi_VN": Fz.tr("Việt Nam"), "en_US": Fz.tr("Hoa Kỳ"), "en_GB": Fz.tr("Anh"), "de_DE": Fz.tr("Đức"), "fr_FR": Fz.tr("Pháp"), "ja_JP": Fz.tr("Nhật Bản"), "ko_KR": Fz.tr("Hàn Quốc"), "zh_CN": Fz.tr("Trung Quốc") })
    function base(l) { return (l || "").split(".")[0]; }
    readonly property string lang: d.LANG || "en_US.UTF-8"
    readonly property string region: d.LC_TIME || d.LC_NUMERIC || lang
    readonly property var options: { let s = {}; return [lang].concat(locales).filter(l => l && !s[base(l)] && (s[base(l)] = true)); }
    readonly property bool hasVi: locales.some(l => base(l) === "vi_VN")
    function regionFmt(n, frac) { let vi = base(region) === "vi_VN" || /^(de|fr|es|it|pt|ru)/.test(region); let s = n.toFixed(frac).split("."); let i = s[0].replace(/\B(?=(\d{3})+(?!\d))/g, vi ? "." : ","); return frac ? i + (vi ? "," : ".") + s[1] : i; }

    Grp {
        width: parent.width
        SRow {
            title: Fz.tr("Ngôn ngữ của Zone-C"); sub: Fz.tr("Thanh bar, bảng, ứng dụng và cài đặt · đổi ngay")
            CfgSeg { key: "general.language"; def: "vi"; options: [Fz.tr("Tiếng Việt"), "English"]; values: ["vi", "en"] }
        }
    }
    Item { width: 1; height: 12 }
    Grp {
        width: parent.width
        SRow {
            title: Fz.tr("Ngôn ngữ hệ thống"); sub: "LANG=" + page.lang; subMono: true
            FSelect {
                options: page.options.map(l => page.names[page.base(l)] || page.base(l))
                current: 0
                onPicked: (i) => { run.command = ["localectl", "set-locale", "LANG=" + page.options[i]]; run.running = true; }
            }
        }
        SRow {
            title: Fz.tr("Vùng định dạng"); sub: page.hasVi ? "" : Fz.tr("Bật vi_VN.UTF-8 trong /etc/locale.gen để có định dạng Việt Nam")
            FSelect {
                options: page.options.map(l => page.regions[page.base(l)] || page.base(l))
                current: Math.max(0, page.options.findIndex(l => page.base(l) === page.base(page.region)))
                onPicked: (i) => { let l = page.options[i]; run.command = ["localectl", "set-locale", "LANG=" + page.lang, "LC_TIME=" + l, "LC_NUMERIC=" + l, "LC_MONETARY=" + l, "LC_PAPER=" + l]; run.running = true; }
            }
        }
    }

    H3 { text: Fz.tr("Xem trước") }
    Grp {
        width: parent.width
        SRow { title: Fz.tr("Ngày"); FText { text: page.base(page.region) === "en_US" ? Qt.formatDate(DateTime.now, "MM/dd/yyyy") : Qt.formatDate(DateTime.now, "dd/MM/yyyy"); mono: true; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter } }
        SRow { title: Fz.tr("Số"); FText { text: page.regionFmt(1234567.89, 2); mono: true; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter } }
        SRow { title: Fz.tr("Tiền tệ"); FText { text: page.base(page.region) === "vi_VN" ? page.regionFmt(1234567, 0) + " ₫" : page.base(page.region) === "en_US" ? "$" + page.regionFmt(1234567, 0) : page.regionFmt(1234567, 0); mono: true; px: 13.5; color: Fz.sub; anchors.verticalCenter: parent.verticalCenter } }
    }
}
