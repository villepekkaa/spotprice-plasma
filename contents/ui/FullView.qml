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
    property int currentHour: 0
    signal toggleDay()
    
    implicitWidth: 600
    implicitHeight: 350
    Layout.minimumWidth: 500
    Layout.minimumHeight: 250
    Layout.preferredWidth: 600
    Layout.preferredHeight: 350
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
            
            // Store maxPrice as a property accessible to children
            property real maxPriceValue: {
                var prices = showingTomorrow ? tomorrowPrices : todayPrices
                var max = 0
                for (var i = 0; i < prices.length; i++) {
                    if (prices[i] > max) max = prices[i]
                }
                return Math.max(max, 1)
            }
            
            Row {
                anchors.fill: parent
                anchors.topMargin: 20
                spacing: 4
                
                Repeater {
                    model: showingTomorrow ? tomorrowPrices : todayPrices
                    
                    Column {
                        width: parent.width / 24 - 4
                        height: parent.height
                        spacing: 4
                        
                        // Price label
                        Label {
                            width: parent.width
                            text: modelData.toFixed(1)
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignHCenter
                            visible: modelData > 0
                            font.bold: index === currentHour && !showingTomorrow
                            color: index === currentHour && !showingTomorrow ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                        }
                        
                        // Bar area
                        Item {
                            width: parent.width
                            height: parent.height - 35
                            
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: parent.height * (modelData / parent.parent.parent.parent.maxPriceValue)
                                color: modelData < 10 ? "#4CAF50" : modelData <= 20 ? "#FFC107" : "#F44336"
                                radius: 2
                                border.width: index === currentHour && !showingTomorrow ? 2 : 0
                                border.color: Kirigami.Theme.highlightColor
                            }
                        }
                        
                        // Hour label
                        Label {
                            width: parent.width
                            text: index
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignHCenter
                            font.bold: index === currentHour && !showingTomorrow
                            color: index === currentHour && !showingTomorrow ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                        }
                    }
                }
            }
        }
        
        // Legend
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            
            Row {
                spacing: 6
                Rectangle {
                    width: 14
                    height: 14
                    color: "#4CAF50"
                    radius: 2
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    text: "< 10c"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            
            Row {
                spacing: 6
                Rectangle {
                    width: 14
                    height: 14
                    color: "#FFC107"
                    radius: 2
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    text: "10-20c"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
            
            Row {
                spacing: 6
                Rectangle {
                    width: 14
                    height: 14
                    color: "#F44336"
                    radius: 2
                    anchors.verticalCenter: parent.verticalCenter
                }
                Label {
                    text: "> 20c"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}