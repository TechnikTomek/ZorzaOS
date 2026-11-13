// Zorza OS – domyślny układ pulpitu:
// minimalistyczny górny pasek + pływający dock na dole.

var wallpaper = "file:///usr/share/wallpapers/Mgla/";

// --- Pulpity: tapeta ---------------------------------------------------------
desktopsArray = desktopsForActivity(currentActivity());
for (var j = 0; j < desktopsArray.length; j++) {
    var d = desktopsArray[j];
    d.wallpaperPlugin = "org.kde.image";
    d.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    d.writeConfig("Image", wallpaper);
    d.writeConfig("FillMode", "2");
}

// --- Górny pasek -------------------------------------------------------------
var top = new Panel;
top.location = "top";
top.height = Math.round(gridUnit * 1.6);
top.floating = false;
top.hiding = "none";

var launcher = top.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "zorza");
launcher.writeConfig("favoritesPortedToKAstats", "true");
launcher.writeConfig("favorites", "preferred://browser,org.kde.dolphin.desktop,org.kde.konsole.desktop,org.zorza.SystemCenter.desktop,org.zorza.Effects.desktop,org.kde.discover.desktop,systemsettings.desktop");

var title = top.addWidget("org.kde.plasma.pager");

top.addWidget("org.kde.plasma.panelspacer");

var clock = top.addWidget("org.kde.plasma.digitalclock");
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", "true");
clock.writeConfig("dateDisplayFormat", "BesideTime");
clock.writeConfig("dateFormat", "longDate");
clock.writeConfig("use24hFormat", "2");

top.addWidget("org.kde.plasma.panelspacer");

top.addWidget("org.kde.plasma.systemtray");

// --- Pływający dock ----------------------------------------------------------
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 3.4);
dock.alignment = "center";
dock.lengthMode = "fit";
dock.hiding = "dodgewindows";
dock.floating = true;

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", [
    "applications:org.kde.dolphin.desktop",
    "applications:firefox-esr.desktop",
    "applications:org.kde.konsole.desktop",
    "applications:org.kde.kate.desktop",
    "applications:libreoffice-writer.desktop",
    "applications:org.kde.elisa.desktop",
    "applications:org.kde.gwenview.desktop",
    "applications:org.kde.discover.desktop",
    "applications:org.zorza.SystemCenter.desktop"
].join(","));
tasks.writeConfig("showOnlyCurrentDesktop", "false");
tasks.writeConfig("iconSpacing", "2");
tasks.writeConfig("maxStripes", "1");

dock.addWidget("org.kde.plasma.marginsseparator");
dock.addWidget("org.kde.plasma.trash");
