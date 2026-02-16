import QtQuick
import Quickshell
import Quickshell.Hyprland
import "./Colors.js" as Colors

Item {
    id: root
    implicitWidth: wsRow.width
    implicitHeight: 25

    Rectangle {
        id: activePill
        width: 25
        height: 25
        radius: 20
        color: Colors.color15

        property int activeIndex: {
            for (var i = 0; i < Hyprland.workspaces.values.length; i++) {
                if (Hyprland.focusedWorkspace && Hyprland.workspaces.values[i].id === Hyprland.focusedWorkspace.id) {
                    return i;
                }
            }
            return 0;
        }

        x: activeIndex * (25 + 6) 

        Behavior on x {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuint // Smooth fast-to-slow slide
            }
        }
    }

    Row {
        id: wsRow
        spacing: 6

        Repeater {
            model: Hyprland.workspaces

            Rectangle {
                id: wsButton
                width: 25
                height: 25
                radius: 20
                color: "transparent" // Color is now handled by the pill

                readonly property bool isActive: Hyprland.focusedWorkspace && modelData.id === Hyprland.focusedWorkspace.id

                Text {
                    anchors.centerIn: parent
                    text: modelData.id
                    
                    color: wsButton.isActive ? Colors.background : Colors.foreground
                    font.bold: true
                    
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
                }
            }
        }
    }
}
