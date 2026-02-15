import QtQuick
import Quickshell
import Quickshell.Hyprland

Row {
    id: root
    spacing: 6

    Repeater {
        model: Hyprland.workspaces

        Rectangle {
            id: wsButton
            width: 25
            height: 25
            radius: 8

            readonly property bool isActive: Hyprland.focusedWorkspace && modelData.id === Hyprland.focusedWorkspace.id

            color: isActive ? "#89b4fa" : "#313244"

            Behavior on color { ColorAnimation {duration: 100} }

            Text {
                anchors.centerIn: parent
                text: modelData.id

                color: wsButton.isActive ? "#11111b" : "#cdd6f4"
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    Hyprland.dispatch("workspace " + modelData.id)
                }
            }
        }
    }
}
