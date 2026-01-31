import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Rectangle {
    property var todayPrices: []
    property var tomorrowPrices: []
    property bool showingTomorrow: false
    property bool tomorrowAvailable: false
    signal toggleDay()
    
    width: 400
    height: 300
    color: Kirigami.ColorUtils.tintWithAlpha(
        Kirigami.Theme.backgroundColor,
        Kirigami.Theme.textColor,
        0.1
    )
    radius: 8
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // Header with title and day toggle
        RowLayout {
            Layout.fillWidth: true
            
            Label {
                text: showingTomorrow ? "Huomenna" : "Tänään"
                font.pixelSize: 18
                font.bold: true
            }
            
            Item { Layout.fillWidth: true }
            
            Button {
                text: showingTomorrow ? "Näytä tänään" : "Näytä huomenna"
                enabled: !showingTomorrow || tomorrowAvailable
                onClicked: toggleDay()
            }
        }
        
        // Tomorrow not available message
        Label {
            visible: showingTomorrow && !tomorrowAvailable
            text: "Huomisen hinnat päivittyvät noin klo 14:15"
            color: Kirigami.Theme.neutralTextColor
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
        }
        
        // Price chart
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !showingTomorrow || tomorrowAvailable
            
            // Calculate max price for scaling
            property real maxPrice: {
                var prices = showingTomorrow ? tomorrowPrices : todayPrices
                var max = 0
                for (var i = 0; i < prices.length; i++) {
                    if (prices[i] > max) max = prices[i]
                }
                return Math.max(max, 1) // Avoid division by zero
            }
            
            RowLayout {
                anchors.fill: parent
                spacing: 2
                
                Repeater {
                    model: showingTomorrow ? tomorrowPrices : todayPrices
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 2
                        
                        // Price label
                        Label {
                            text: modelData.toFixed(1)
                            font.pixelSize: 8
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                            visible: modelData > 0
                        }
                        
                        // Bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.maximumHeight: parent.height * 0.7
                            Layout.minimumHeight: 4
                            Layout.preferredHeight: (modelData / parent.parent.parent.maxPrice) * parent.height * 0.7
                            color: modelData < 10 ? "#4CAF50" : modelData <= 20 ? "#FFC107" : "#F44336"
                            radius: 2
                        }
                        
                        // Hour label
                        Label {
                            text: index
                            font.pixelSize: 8
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }
        }
        
        // Legend
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 16
            
            RowLayout {
                spacing: 4
                Rectangle {
                    width: 12
                    height: 12
                    color: "#4CAF50"
                    radius: 2
                }
                Label {
                    text: "< 10c"
                    font.pixelSize: 10
                }
            }
            
            RowLayout {
                spacing: 4
                Rectangle {
                    width: 12
                    height: 12
                    color: "#FFC107"
                    radius: 2
                }
                Label {
                    text: "10-20c"
                    font.pixelSize: 10
                }
            }
            
            RowLayout {
                spacing: 4
                Rectangle {
                    width: 12
                    height: 12
                    color: "#F44336"
                    radius: 2
                }
                Label {
                    text: "> 20c"
                    font.pixelSize: 10
                }
            }
        }
    }
}