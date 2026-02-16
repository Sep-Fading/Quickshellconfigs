import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import QtQuick.Controls
import QtQuick.Controls.Fusion
import Quickshell.Widgets
import "./Taskwarrior.qml"
import "./Icons.js" as Icons
import "./Colors.js" as Colors


Row {
    id: root
    spacing: 20
    anchors.verticalCenter: parent.verticalCenter
    
    property var nmAppletItem: null

    FontLoader {
        id: materialFont
        source: "file:///usr/share/fonts/TTF/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf"
    }

    Taskwarrior {}
    
   // Tray
    Row {
        spacing: 8
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: SystemTray.items
            
            delegate: IconImage {
                id: trayIcon
                required property var modelData

                readonly property bool isNm: modelData.title === "NetworkManager Applet" || modelData.id === "nm-applet"

                visible: !isNm

                width: visible ? 18 : 0
                height: 18

                onIsNmChanged: if (isNm) root.nmAppletItem = modelData
                Component.onCompleted: if (isNm) root.nmAppletItem = modelData
                
                source: modelData ? modelData.icon : ""

                QsMenuOpener {
                    id: trayMenuOpener
                    menu: trayIcon.modelData ? trayIcon.modelData.menu : null
                }

                TrayMenu { 
                    id: itemMenu
                    model: trayMenuOpener.children
                    x: (parent.width - width) / 2 
                    y: 30
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    hoverEnabled: true
                    
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) { 
                            trayIcon.modelData.activate();
                        } else if (mouse.button === Qt.RightButton) {
                            if (itemMenu.opened) {
                                itemMenu.close();
                            } else {
                                itemMenu.open();
                            }
                        }
                    }
                }
            }    
        }
    }

    component TrayMenu: Menu {
        id: trayMenu
        property alias model: iconImageMenuInstantiator.model

        width: 225
        height: 1
        opacity: 0

        popupType: Popup.Window
        clip: true
        
        onAboutToShow: {
            height = 1
            opacity = 0
        }
        
        onClosed: {
            height = 1
            opacity = 0
        }

        enter: Transition {
            SequentialAnimation {
                ScriptAction {
                    script: { trayMenu.height = 1; trayMenu.opacity = 0 } 
                }
                
                ParallelAnimation {
                    NumberAnimation {
                        property: "height"
                        from: 1
                        to: trayMenu.implicitHeight
                        duration: 350
                        easing.type: Easing.OutQuad
                    }

                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 200
                    }
                }
            }
        }

        exit: Transition {
            ParallelAnimation {
                NumberAnimation { property: "height"; to: 1; duration: 150; easing.type: Easing.InQuad }
                NumberAnimation { property: "opacity"; to: 0; duration: 150}
            }
        }

        background: Rectangle {
            color: Colors.background
            radius: 8
            border.color: Colors.foreground
            border.width: 1
        }

        padding: 8
        spacing: 4

        Instantiator {
            id: iconImageMenuInstantiator
            onObjectAdded: (index, object) => {
                if (object instanceof Menu) trayMenu.insertMenu(index, object);
                else trayMenu.insertItem(index, object);
            }
            onObjectRemoved: (index, object) => {
                if (object instanceof Menu) trayMenu.removeMenu(object);
                else trayMenu.removeItem(object);
            }

            delegate: DelegateChooser {
                role: "isSeparator"
                DelegateChoice {
                    roleValue: false
                    delegate: MenuItem {
                        id: menuItem
                        
                        required property QsMenuEntry modelData
                        
                        implicitWidth: 200
                        implicitHeight: 32

                        background: Rectangle {
                            color: menuItem.highlighted ? Colors.color1 : "transparent"
                            radius: 8
                        }

                        contentItem: Text {
                            text: menuItem.modelData ? menuItem.modelData.text : ""
                            color: menuItem.highlighted ? Colors.color5 : Colors.foreground
                            font.bold: true
                            font.pixelSize: 13
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                            elide: Text.ElideRight
                        }
                        
                        onTriggered: modelData.triggered()
                    }
                }
                DelegateChoice {
                    roleValue: true
                    delegate: MenuSeparator {
                        padding: 0
                        verticalPadding: 4
                        contentItem: Rectangle {
                            implicitWidth: 200
                            implicitHeight: 1
                            color: Colors.foreground
                        }
                    }
                }
            }
        }
    }

    // Bluetooth
    Item {
        id: btRow
        height: 20
        anchors.verticalCenter: parent.verticalCenter
        
        Process {
            id: btProc
            property string state: "OFF"
            property string deviceName: ""
            
            property bool isPowered: state === "ON"
            property bool isConnected: deviceName !== ""

            command: ["sh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && (echo -n 'ON '; bluetoothctl devices Connected | head -n1 | cut -d ' ' -f 3-) || echo 'OFF'"]
            
            stdout: SplitParser {
                onRead: (data) => {
                    var line = data.toString().trim()
                    
                    if (line === "OFF") {
                        btProc.state = "OFF"
                        btProc.deviceName = ""
                    } else if (line.startsWith("ON")) {
                        btProc.state = "ON"
                        btProc.deviceName = line.substring(3).trim()
                    }
                }
            }

        }

        Timer {
            interval: 5000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: btProc.running = true
        }

        Text {
            font.family: materialFont.name
            font.pixelSize: 18 
            anchors.verticalCenter: parent.verticalCenter
            
            text: {
                if (!btProc.isPowered) return Icons.btOff
                if (btProc.isConnected) return Icons.btConnected
                return Icons.btOn 
            }

            color: btProc.isPowered ? Colors.blue : Colors.gray
        }

        Text {
            text: btProc.deviceName
            visible: btProc.isPowered && btProc.isConnected
            color: Colors.foreground
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
        
        Process { id: btCommandProc }
        MouseArea {
            anchors.fill : parent

            onClicked: {
                btCommandProc.command = [""]
                btCommandProc.running = true
                btProc.running = true 
            }
        }
    }

    // Volume
    Item {
        id: volWidget
        
        width: volContent.width
        height: 20 
        anchors.verticalCenter: parent.verticalCenter

        Process {
            id: volProc
            property int volume: 0
            property bool isMuted: false

            command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
            
            stdout: SplitParser {
                onRead: (data) => {
                    var line = data.toString().trim()
                    var match = line.match(/Volume:\s+([\d\.]+)(.*)/)
                    if (match && match.length >= 2) {
                        volProc.volume = Math.round(parseFloat(match[1]) * 100)
                        volProc.isMuted = match[2].includes("MUTED")
                    }
                }
            }
        }

        Process { id: volCommandProc }

        Timer {
            interval: 1000 
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: volProc.running = true
        }

        Row {
            id: volContent
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter

            Text {
                font.family: materialFont.name
                font.pixelSize: 22
                color: volProc.isMuted ? Colors.red : Colors.blue
                anchors.verticalCenter: parent.verticalCenter
                
                text: {
                    if (typeof Icons === "undefined") return "Vol" // Safety fallback
                    if (volProc.isMuted) return Icons.volOff
                    if (volProc.volume >= 60) return Icons.volHigh
                    if (volProc.volume >= 30) return Icons.volMed
                    return Icons.volLow
                }
            }

            Text {
                text: volProc.isMuted ? "Muted" : volProc.volume + "%"
                color: Colors.foreground
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            
            onClicked: {
                volCommandProc.command = ["pavucontrol"]
                volCommandProc.running = true
                volProc.running = true 
            }
            
            onWheel: (wheel) => {
                var dir = wheel.angleDelta.y > 0 ? "5%+" : "5%-"
                volCommandProc.command = ["wpctl", "set-volume", "-l", "1.5", "@DEFAULT_AUDIO_SINK@", dir]
                volCommandProc.running = true
                volProc.running = true
            }
        }
    }

    // Wifi 
    Item {
        id: wifiWidget
        anchors.verticalCenter: parent.verticalCenter
        width: wifiRow.width
        height: 20

        QsMenuOpener {
            id: wifiMenuOpener
            menu: root.nmAppletItem ? root.nmAppletItem.menu : null
        }

        TrayMenu {
            id: wifiContextMenu
            model: wifiMenuOpener.children
            x: (parent.width - width) /2
            y: 30
        }
        
        /*
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton

            onClicked: (mouse) => {
                if (mouse.button === Qt.RightButton && root.nmAppletItem) {
                    if (wifiContextMenu.opened){
                        wifiContextMenu.close()
                    } else {
                        wifiContextMenu.open()
                    }
                }
            }
        }
        */

        Process {
            id: wifiProc
            
            property string wifiName: ""
            property int signalStrength: 0
            property bool connected: wifiName !== ""

            command: ["sh", "-c", "nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi | grep '^yes' || echo ''"]
            
            stdout: SplitParser {
                onRead: (data) => {
                    var line = data.toString().trim()
                    if (line === "") {
                        wifiProc.wifiName = ""
                        wifiProc.signalStrength = 0
                        return
                    }

                    var parts = line.split(":")
                    if (parts.length >= 3) {
                        wifiProc.wifiName = parts[1]
                        wifiProc.signalStrength = parseInt(parts[2])
                    }
                }
            }
        }

        Process {
            id: vpnProc
            property bool hasVpn: false

            command: ["sh", "-c", "nmcli --terse --fields TYPE connection show --active | grep -q vpn && echo true || echo false"]

            stdout: SplitParser {
                onRead: (data) => {
                    vpnProc.hasVpn = (data.toString().trim() === "true")
                }
            }
        }

        Timer {
            interval: 2500
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                wifiProc.running = true
                vpnProc.running = true
            }
        }

        Row {
            id: wifiRow
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: wifiIcon
                
                text: {
                    if (!wifiProc.connected) return Icons.wifiOff
                    
                    if (vpnProc.hasVpn) return Icons.wifiSecured       

                    if (wifiProc.signalStrength > 70) return Icons.wifiFull
                    if (wifiProc.signalStrength > 50) return Icons.wifiHalf
                    return Icons.wifiLow
                }

                font.family: materialFont.name
                color: vpnProc.hasVpn ? Colors.green : (wifiProc.connected ? Colors.blue : Colors.gray)
                font.pixelSize: 18
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: wifiProc.connected ? wifiProc.wifiName : "Offline"
                color: Colors.foreground
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    //  Battery
    Row {
        id:batteryRow
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter

        property var bat: UPower.displayDevice

        visible: bat && bat.isPresent
        width: visible ? implicitWidth : 0
    
        Text {
            font.family: materialFont.name
            font.pixelSize: 18
            color: (batteryRow.bat && batteryRow.bat.state === UPowerDeviceState.Charging) 
                   ? Colors.blue 
                   : (batteryRow.bat && batteryRow.bat.percentage <= 0.2) 
                       ? Colors.red
                       : Colors.green
            
            text: {
                if (!batteryRow.visible) return ""
                
                if (batteryRow.bat.state === UPowerDeviceState.Charging) return Icons.batteryCharging

                var p = batteryRow.bat.percentage
                if (p >= 0.9) return Icons.batteryFull
                if (p >= 0.8) return Icons.battery85
                if (p >= 0.6) return Icons.battery70
                if (p >= 0.4) return Icons.batteryHalf
                if (p >= 0.3) return Icons.battery35
                if (p >= 0.2) return Icons.battery20
                return Icons.battery10
            }
        }

        Text {
            // Safety check: prevent error accessing 'percentage' if null
            text: batteryRow.visible ? Math.round(batteryRow.bat.percentage * 100) + "%" : ""
            color: Colors.foreground
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
