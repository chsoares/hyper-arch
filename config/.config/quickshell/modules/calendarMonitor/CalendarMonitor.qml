import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    readonly property real widgetWidth: Appearance.sizes.mediaControlsWidth
    readonly property real widgetHeight: Appearance.sizes.mediaControlsHeight * 1.8
    readonly property real osdWidth: Appearance.sizes.osdWidth

    GlobalShortcut {
        name: "calendarMonitorToggle"
        description: qsTr("Toggles calendar monitor on press")

        onPressed: {
            calendarMonitorLoader.active = !calendarMonitorLoader.active
        }
    }

    Loader {
        id: calendarMonitorLoader
        active: false

        sourceComponent: PanelWindow {
            id: calendarMonitorRoot
            visible: true

            function hide() {
                calendarMonitorLoader.active = false
            }

            exclusiveZone: 0
            implicitWidth: (
                (calendarMonitorRoot.screen.width / 2) // Middle of screen
                    - (osdWidth / 2)                 // Dodge OSD
                    - (widgetWidth / 2)              // Account for widget width
            ) * 2
            implicitHeight: calendarColumnLayout.implicitHeight
            color: "transparent"
            WlrLayershell.namespace: "quickshell:calendarMonitor"

            anchors {
                top: !Config.options.bar.bottom
                bottom: Config.options.bar.bottom
                right: true
            }
            mask: Region {
                item: calendarColumnLayout
            }

            HyprlandFocusGrab {
                id: grab
                windows: [ calendarMonitorRoot ]
                active: calendarMonitorLoader.active
                onCleared: () => {
                    if (!active) calendarMonitorRoot.hide()
                }
            }

            ColumnLayout {
                id: calendarColumnLayout
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                x: (calendarMonitorRoot.screen.width / 2)  // Middle of screen
                    - (osdWidth / 2)                     // Dodge OSD
                    - (widgetWidth)                      // Account for widget width
                    + (Appearance.sizes.elevationMargin) // It's fine for shadows to overlap
                    - 10
                spacing: -Appearance.sizes.elevationMargin // Shadow overlap okay

                focus: calendarMonitorLoader.active
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Escape) {
                        calendarMonitorRoot.hide();
                    }
                }

                CalendarControl {}
            }
        }
    }
}