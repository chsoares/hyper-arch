import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    property bool showDate: Config.options.bar.verbose
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: 32

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
            text: DateTime.date
        }

        StyledText {
            visible: root.showDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: ""
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
