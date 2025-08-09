import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

Item {
    id: resourceController
    
    implicitWidth: widgetWidth
    implicitHeight: widgetHeight

    property real widgetWidth: Appearance.sizes.mediaControlsWidth
    property real widgetHeight: Appearance.sizes.mediaControlsHeight * 1.5

    // Background shadow
    StyledRectangularShadow {
        target: backgroundRect
    }

    // Background
    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        anchors.margins: Appearance.sizes.elevationMargin
        color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.25)
        radius: Appearance.rounding.windowRounding

        MouseArea {
            anchors.fill: parent
            onPressed: event => event.accepted = true
        }

        ColumnLayout {
            anchors {
                fill: parent
                margins: 16
            }
            spacing: 12


            // CPU
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                MaterialSymbol {
                    text: "settings_slow_motion"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    Layout.fillWidth: true
                    text: "CPU"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    text: `${Math.round(ResourceUsage.cpuUsage * 100)}%`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    font.weight: Font.Bold
                }
            }

            // Memory
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                MaterialSymbol {
                    text: "memory"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    Layout.fillWidth: true
                    text: "Memory"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    text: `${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    font.weight: Font.Bold
                }
            }

            // Disk
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                MaterialSymbol {
                    text: "hard_drive"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    Layout.fillWidth: true
                    text: "Disk"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    text: `${Math.round((ResourceUsage.diskUsedPercentage ?? 0) * 100)}%`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    font.weight: Font.Bold
                }
            }

            // Temperature
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                MaterialSymbol {
                    text: "thermostat"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    Layout.fillWidth: true
                    text: "Temperature"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    text: `${Math.round(ResourceUsage.cpuTemperature ?? 0)}°C`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    font.weight: Font.Bold
                }
            }

            // Download Speed
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                MaterialSymbol {
                    text: "arrow_downward"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    Layout.fillWidth: true
                    text: "Download"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    text: `${(ResourceUsage.netDownloadSpeed ?? 0).toFixed(1)} KB/s`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    font.weight: Font.Bold
                }
            }

            // Upload Speed
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                
                MaterialSymbol {
                    text: "arrow_upward"
                    iconSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    Layout.fillWidth: true
                    text: "Upload"
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                }
                
                StyledText {
                    text: `${(ResourceUsage.netUploadSpeed ?? 0).toFixed(1)} KB/s`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    font.weight: Font.Bold
                }
            }
        }
    }
}