import QtQuick
import Quickshell
import Quickshell.Io
import "./Icons.js" as Icons
import "./Colors.js" as Colors

Row {
    id: root
    spacing: 8
    anchors.verticalCenter: parent.verticalCenter

    property string taskDescription: "No Tasks"
    property string taskDue: ""
    property bool hasTask: false
    
    property string _jsonBuffer: ""

Process {
        id: taskProc
        command: ["task", "(status:pending or status:waiting)", "sort:due", "limit:1", "export"]
        
        stdout: SplitParser {
            onRead: (data) => root._jsonBuffer += data
        }

        onExited: {
            var cleanData = root._jsonBuffer.trim();
            root._jsonBuffer = ""; 
            if (cleanData === "" || cleanData === "[]") {
                root.hasTask = false;
                root.taskDescription = "Free";
                return;
            }

            try {
                var tasks = JSON.parse(cleanData);
                if (tasks.length > 0) {
                    var task = tasks[0];
                    root.hasTask = true;
                    root.taskDescription = task.description;

                    // Better date parsing helper
                    function parseDate(raw) {
                        if (!raw) return null;
                        var iso = raw.substring(0,4) + "-" + raw.substring(4,6) + "-" + 
                                  raw.substring(6,11) + ":" + raw.substring(11,13) + ":" + 
                                  raw.substring(13);
                        return new Date(iso);
                    }

                    var now = new Date();
                    var startObj = parseDate(task.scheduled);
                    var endObj = parseDate(task.due);
                    
                    // Switch logic: Show start time if in the future, else show end time
                    var targetDate = (startObj && now < startObj) ? startObj : endObj;

                    if (targetDate) {
                        var today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
                        var tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
                        var targetDay = new Date(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate());
                        var timeStr = Qt.formatDateTime(targetDate, "hh:mm");

                        if (targetDay.getTime() === today.getTime()) {
                            root.taskDue = "Today " + timeStr;
                        } else if (targetDay.getTime() === tomorrow.getTime()) {
                            root.taskDue = "Tomorrow " + timeStr;
                        } else {
                            root.taskDue = Qt.formatDateTime(targetDate, "ddd hh:mm");
                        }
                    } else {
                        root.taskDue = "";
                    }
                }
            } catch (e) {
                console.log("TaskJSON Error: " + e);
                root.hasTask = false;
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
        text: Icons.taskPending 
        color: root.hasTask ? Colors.yellow : Colors.gray
        font.pixelSize: 16
        anchors.verticalCenter: parent.verticalCenter
    }

    Text {
        text: root.taskDescription
        color: root.hasTask ? Colors.foreground : Colors.gray
        font.bold: true
        anchors.verticalCenter: parent.verticalCenter
    }

    Rectangle {
        visible: root.hasTask && root.taskDue !== ""
        width: timeLabel.width + 12
        height: 20
        radius: 5
        color: Colors.color7
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: timeLabel
            text: root.taskDue
            color: Colors.color9
            font.bold: true
            font.pixelSize: 12
            anchors.centerIn: parent
        }
    }
}
