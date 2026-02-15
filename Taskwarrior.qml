import QtQuick
import Quickshell
import Quickshell.Io

Row {
    id: root
    spacing: 8
    anchors.verticalCenter: parent.verticalCenter

    // Data Storage
    property string taskDescription: "No Tasks"
    property string taskDue: ""
    property bool hasTask: false
    
    // Internal buffer for accumulating JSON output chunks
    property string _jsonBuffer: ""

    Process {
        id: taskProc
        
        command: ["task", "(" ,"status:pending", "or", "status:waiting", ")", "sort:due", "limit:1", "export"]
        
        stdout: SplitParser {
            onRead: (data) => {
                // Accumulate data chunks (JSON can be split across signals)
                root._jsonBuffer += data
            }
        }

        onExited: {
            var cleanData = root._jsonBuffer.trim()
            root._jsonBuffer = "" 
            if (cleanData === "" || cleanData === "[]") {
                root.hasTask = false
                root.taskDescription = "Free"
                return
            }

            try {
                var tasks = JSON.parse(cleanData)
                if (tasks.length > 0) {
                    var task = tasks[0]
                    root.hasTask = true
                    root.taskDescription = task.description

                    if (task.due) {
                        // Taskwarrior JSON dates are ISO-8601 compact strings
                        // Format them for JS Date: 20230101T120000Z -> 2023-01-01T12:00:00Z
                        var raw = task.due
                        var iso = raw.substring(0,4) + "-" + raw.substring(4,6) + "-" + raw.substring(6,11) + ":" + raw.substring(11,13) + ":" + raw.substring(13)
                        
                        var dateObj = new Date(iso)
                        root.taskDue = dateObj.toLocaleTimeString(Qt.locale(), "hh:mm")
                    } else {
                        root.taskDue = ""
                    }
                }
            } catch (e) {
                console.log("TaskJSON Error: " + e)
                root.hasTask = false
            }
        }
    }

    Timer {
        interval: 5000 //300000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: taskProc.running = true
    }

    Text {
        text: "" 
        color: root.hasTask ? "#fab387" : "#585b70" 
        font.pixelSize: 16
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: root.taskDescription
        color: root.hasTask ? "#cdd6f4" : "#585b70"
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        visible: root.hasTask && root.taskDue !== ""
        width: timeLabel.width + 10
        height: 20
        radius: 5
        color: "#313244"
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: timeLabel
            text: root.taskDue
            color: "#fab387"
            font.bold: true
            font.pixelSize: 12
            anchors.centerIn: parent
        }
    }
}
