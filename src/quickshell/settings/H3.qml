import QtQuick
import "../frost"

// `.h3`: section heading (24px above, 10px below; the first one on a page sits flush).
FText {
    property bool first: false
    leftPadding: 4; topPadding: first ? 0 : 24; bottomPadding: 10
    px: 12; weight: Font.DemiBold; color: Fz.sub
    font.letterSpacing: 12 * 0.08; font.capitalization: Font.AllUppercase
}
