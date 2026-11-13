pragma Singleton
import QtQuick

QtObject {
    readonly property bool dark: backend.dark
    readonly property color accent: backend.accentColor
    readonly property color bg: dark ? "#11152B" : "#F4F5FB"
    readonly property color bg2: dark ? "#161B36" : "#FFFFFF"
    readonly property color card: dark ? "#1B2142" : "#FFFFFF"
    readonly property color cardHover: dark ? "#232A55" : "#F0F0FA"
    readonly property color border: dark ? "#2A3166" : "#E2E4F2"
    readonly property color text: dark ? "#E6E8F5" : "#1E2140"
    readonly property color muted: dark ? "#9CA0C8" : "#6B6F90"
    readonly property color sidebar: dark ? "#0E1330" : "#ECEDF7"
    readonly property string font: "Inter"
    readonly property int radius: 18
    readonly property bool pl: backend.polish
    function tr(p, e) { return pl ? p : e }
}
