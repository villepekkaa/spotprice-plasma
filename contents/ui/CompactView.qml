import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    property real price: 0.0
    property string priceColor: "#4CAF50"
    
    signal clicked()
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    Layout.minimumWidth: 110
    Layout.preferredWidth: 115
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: parent.clicked()

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            radius: 4
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 4
                
                Label {
                    text: "⚡\uFE0E"
                    font.pixelSize: 26
                    color: Kirigami.Theme.textColor
                    opacity: mouseArea.containsMouse ? 1.0 : 0.5
                }
                
                Label {
                    text: price.toFixed(2) + " " + i18n("c/kWh")
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Kirigami.Theme.textColor
                }
            }
        }
    }
}