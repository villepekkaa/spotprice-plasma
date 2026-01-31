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
    Layout.minimumWidth: 85
    Layout.preferredWidth: 90
    
    MouseArea {
        anchors.fill: parent
        onClicked: parent.clicked()
    }
    
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
            }
            
            Label {
                text: price < 1 ? price.toFixed(2) + "c" : price.toFixed(1) + "c"
                font.pixelSize: 14
                font.weight: Font.Medium
                color: Kirigami.Theme.textColor
            }
        }
    }
}