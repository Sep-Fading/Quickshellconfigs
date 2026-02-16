import QtQuick
import Quickshell
import Quickshell.Wayland
import "./Colors.js" as Colors

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

    margins {
        top: 10
        left: 10
        right: 10
    }

    implicitHeight: 34
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.exclusionMode: ExclusionMode.Auto

    Rectangle {
        id: leftIsland
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        width: leftContent.width + 20
        height: 33
        radius: 20
        color: Colors.background

    
        Row {
            id: leftContent
            anchors.centerIn: parent
            Workspaces {}
        }
    }

    // Clock
    Rectangle {
        id: midIsland
        anchors.centerIn: parent
        width: timeText.width + 30
        height: 33
        radius: 20
        color: Colors.background

        Text {
            id: timeText
            anchors.centerIn: parent
            color: Colors.foreground
            font.bold: true
            font.pixelSize: 14

            function updateTime() {
                text = Qt.formatDateTime(new Date(), "dd MMM | hh:mm")
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: timeText.updateTime()
            }
        }
    }

    Rectangle {
        id: rightIsland
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        
        width: trayModule.width + 20
        height: 33
        radius: 20
        color: Colors.background

        Item {
            id: trayModule
            anchors.centerIn: parent
            width: trayInternal.width
            height: parent.height

            Tray {
                id: trayInternal
                anchors.centerIn: parent
            }
        }
    }
}
