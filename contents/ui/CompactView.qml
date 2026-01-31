import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    property real price: 0.0
    property string priceColor: "#4CAF50"
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    Rectangle {
        anchors.fill: parent
        color: priceColor
        radius: 4
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            
            Label {
                text: "⚡"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                color: "white"
            }
            
            Label {
                text: price.toFixed(1) + "c"
                font.pixelSize: 12
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                color: "white"
            }
        }
    }
}