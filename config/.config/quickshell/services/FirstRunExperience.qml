pragma Singleton

import "root:/modules/common/functions/file_utils.js" as FileUtils
import "root:/modules/common"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root
    property string firstRunFilePath: `${Directories.state}/user/first_run.txt`
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property string firstRunNotifSummary: "Welcome!"
    property string firstRunNotifBody: "Hit Super+H for a list of keybinds"
    property string defaultWallpaperPath: FileUtils.trimFileProtocol(`${Directories.config}/quickshell/assets/images/default_wallpaper.png`)
    property string welcomeQmlPath: FileUtils.trimFileProtocol(`${Directories.config}/quickshell/welcome.qml`)

    function load() {
        firstRunFileView.reload()
    }

    function enableNextTime() {
        Quickshell.execDetached(["rm", "-f", root.firstRunFilePath])
    }
    function disableNextTime() {
        Quickshell.execDetached(["bash", "-c", `echo '${root.firstRunFileContent}' > '${root.firstRunFilePath}'`])
    }

    function handleFirstRun() {
        // Set random wallpaper using the same script as Super+Ctrl+Alt+T
        Quickshell.execDetached(["bash", `${Directories.config}/hypr/hyprland/scripts/random-wallpaper.sh`])
        // Show welcome notification
        Quickshell.execDetached(["notify-send", root.firstRunNotifSummary, root.firstRunNotifBody, "-i", "welcome"])
        // Open settings for first-time configuration (same as Super+I)
        Quickshell.execDetached(["qs", "-p", "~/.config/quickshell/settings.qml"])
    }

    FileView {
        id: firstRunFileView
        path: Qt.resolvedUrl(firstRunFilePath)
        onLoadFailed: (error) => {
            if (error == FileViewError.FileNotFound) {
                firstRunFileView.setText(root.firstRunFileContent)
                root.handleFirstRun()
            }
        }
    }
}
