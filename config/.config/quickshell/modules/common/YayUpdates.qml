import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    
    property int updateCount: 0
    property bool isChecking: false
    property bool hasUpdates: updateCount > 0
    
    Process {
        id: yayProcess
        command: ["yay", "-Qu"]
        running: false
        
        stdout: SplitParser {
            onRead: data => {
                const output = data.trim();
                if (output) {
                    const lines = output.split('\n').filter(line => line.trim() !== '')
                    root.updateCount = lines.length
                } else {
                    root.updateCount = 0
                }
            }
        }
        
        stderr: SplitParser {
            onRead: errorData => {
                const errorOutput = errorData.trim();
                if (errorOutput) {
                    console.warn(`YayUpdates (Process stderr): ERROR = "${errorOutput}"`);
                }
            }
        }
        
        onExited: (exitCode, exitStatus) => {
            root.isChecking = false
            if (exitCode !== 0) {
                root.updateCount = 0
            }
        }
        
        onStarted: {
            root.isChecking = true
        }
    }
    
    function checkUpdates() {
        if (!yayProcess.running) {
            yayProcess.running = true
        }
    }
    
    Timer {
        id: refreshTimer
        interval: 300000 // 5 minutos
        running: true
        repeat: true
        onTriggered: {
            yayProcess.running = false
            yayProcess.running = true
        }
    }
    
    Component.onCompleted: {
        checkUpdates()
    }
}