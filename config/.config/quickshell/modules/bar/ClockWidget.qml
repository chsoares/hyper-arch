import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: 32

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: (event) => {
            if (event.button === Qt.LeftButton) {
                Hyprland.dispatch("global quickshell:calendarMonitorToggle")
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        MaterialSymbol {
            visible: root.showDate
            text: "calendar_today"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: Config.options.bar.weather.enable ? Qt.locale().toString(DateTime.clock.date, "ddd dd/MM") : DateTime.date
        }

        StyledText {
            visible: Config.options.bar.weather.enable
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: " "
        }
        // Weather widget
        MaterialSymbol {
            visible: Config.options.bar.weather.enable
            text: Weather.getWeatherIcon(Weather.data.condition)
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            visible: Config.options.bar.weather.enable
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: Weather.data.temp
        }
        
        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: " "
        }

        MaterialSymbol {
            text: "schedule"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
            text: DateTime.time
        }
        


    }

}
