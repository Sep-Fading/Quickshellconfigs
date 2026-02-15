import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: topBar

    FontLoader {
        id: materialFont
        source: "file:///usr/share/fonts/TTF/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf"
    }

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 30
    color: "#1e1e2e" 

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Auto
    
    Row {
        id: leftModule
        anchors.left: parent.left
        spacing: 10
        anchors.margins: 5

        Workspaces {}

    }

    // Clock
    Text {
        id: timeText
        anchors.centerIn: parent
        color: "#cdd6f4"
        font.bold: true
        font.pixelSize: 14

        function updateTime() {
            text = Qt.formatDateTime(new Date(), "dd MMM | hh:mm")
        }

        Timer {
            interval: 1000 // Update every second
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: timeText.updateTime()
        }
    }

    Tray {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }
}
