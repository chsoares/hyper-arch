import "root:/modules/common"
import "root:/modules/common/widgets"
import "root:/services"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8
        
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(new Date(), "hh:mm:ss")
            font.pixelSize: Appearance.font.pixelSize.huge * 1.2
            font.weight: Font.Bold
            color: Appearance.colors.colOnLayer1
        }
        
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDateTime(new Date(), "dddd, dd MMMM yyyy")
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer1
            opacity: 0.8
        }
    }
    
    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            root.children[0].children[0].text = Qt.formatDateTime(new Date(), "hh:mm:ss")
            root.children[0].children[1].text = Qt.formatDateTime(new Date(), "dddd, dd MMMM yyyy")
        }
    }
}