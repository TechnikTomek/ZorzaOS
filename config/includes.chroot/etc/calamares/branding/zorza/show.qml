// Zorza OS – slajdy wyświetlane podczas instalacji
import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: presentation
    readonly property bool pl: Qt.locale().name.indexOf("pl") === 0
    function tr(p, e) { return pl ? p : e }

    Timer {
        id: advanceTimer
        interval: 9000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    component ZSlide: Slide {
        property string img
        property string heading
        property string body
        Image {
            anchors.fill: parent
            source: img
            fillMode: Image.PreserveAspectCrop
        }
        Column {
            anchors.left: parent.left
            anchors.leftMargin: 48
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width * 0.62
            spacing: 14
            Text {
                text: heading
                color: "#FFFFFF"
                font.family: "Inter"; font.pixelSize: 30; font.weight: Font.Bold
                wrapMode: Text.WordWrap; width: parent.width
            }
            Rectangle { width: 64; height: 4; radius: 2; color: "#FF6FA3" }
            Text {
                text: body
                color: "#E6E8F5"
                font.family: "Inter"; font.pixelSize: 16
                wrapMode: Text.WordWrap; width: parent.width
                lineHeight: 1.25
            }
        }
    }

    ZSlide {
        img: "slide1.jpg"
        heading: tr("Witaj w Zorza OS", "Welcome to Zorza OS")
        body: tr("Szybki, piękny i przyjazny system oparty na Debianie 13 i KDE Plasma 6. Instalacja potrwa kilka minut – w tym czasie poznaj, co Cię czeka.",
                 "A fast, beautiful and friendly system built on Debian 13 and KDE Plasma 6. Installation takes a few minutes – meanwhile, here is what awaits you.")
    }
    ZSlide {
        img: "slide2.jpg"
        heading: tr("Twój styl", "Your style")
        body: tr("Jasny lub ciemny motyw, sześć kolorów akcentu, tapety dzień/noc i pływający dock. Wszystko zmienisz jednym kliknięciem w System Center.",
                 "Light or dark theme, six accent colours, day/night wallpapers and a floating dock. Change everything with one click in System Center.")
    }
    ZSlide {
        img: "slide3.jpg"
        heading: tr("Tysiące aplikacji", "Thousands of apps")
        body: tr("Discover łączy repozytoria Debiana i Flathub. Firefox, LibreOffice, GIMP, Inkscape i VLC są gotowe od pierwszego uruchomienia.",
                 "Discover combines Debian repositories and Flathub. Firefox, LibreOffice, GIMP, Inkscape and VLC are ready from the first boot.")
    }
    ZSlide {
        img: "slide4.jpg"
        heading: tr("Bezpieczny i stabilny", "Safe and stable")
        body: tr("Fundament Debiana oznacza długie wsparcie i regularne poprawki bezpieczeństwa. Aktualizacje instalujesz jednym przyciskiem.",
                 "A Debian foundation means long support and regular security fixes. Install updates with a single button.")
    }
    ZSlide {
        img: "slide5.jpg"
        heading: tr("Działa wszędzie", "Runs everywhere")
        body: tr("PC z Intel/AMD, Mac z Apple Silicon w VirtualBox, laptopy i stacje robocze – ten sam system, ta sama wygoda.",
                 "Intel/AMD PCs, Apple Silicon Macs in VirtualBox, laptops and workstations – the same system, the same comfort.")
    }
    ZSlide {
        img: "slide6.jpg"
        heading: tr("Prawie gotowe", "Almost there")
        body: tr("Po ponownym uruchomieniu powita Cię aplikacja Witaj. Dziękujemy za wybór Zorza OS!",
                 "After the restart the Welcome app will greet you. Thank you for choosing Zorza OS!")
    }

    function onActivate() { presentation.currentSlide = 0 }
    function onLeave() { }
}
