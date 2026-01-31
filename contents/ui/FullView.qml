import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    property var todayPrices: []
    property var tomorrowPrices: []
    property bool showingTomorrow: false
    property bool tomorrowAvailable: false
    property int currentHour: 0
    property real priceMargin: 0.0
    property real transferFee: 0.0
    property real greenThreshold: 10.0
    property real yellowThreshold: 20.0
    property real redThreshold: 30.0
    signal toggleDay()
    signal refreshRequested()

    implicitWidth: 600
    implicitHeight: 400
    Layout.minimumWidth: 400
    Layout.minimumHeight: 280
    Layout.preferredWidth: 600
    Layout.preferredHeight: 400

    Component.onCompleted: {
        refreshRequested()
    }

    // Computed prices with margin/fee applied - updates automatically when margin/fee changes
    property var computedPrices: {
        var prices = showingTomorrow ? tomorrowPrices : todayPrices
        var margin = priceMargin || 0
        var fee = transferFee || 0
        var result = []
        for (var i = 0; i < prices.length; i++) {
            result.push((prices[i] || 0) + margin + fee)
        }
        return result
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // Header with title and day toggle
        RowLayout {
            Layout.fillWidth: true
            
            Label {
                text: showingTomorrow ? i18n("Tomorrow") : i18n("Today")
                font.pixelSize: 18
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            PlasmaComponents.Button {
                text: showingTomorrow ? i18n("Today") : i18n("Tomorrow")
                enabled: true
                opacity: tomorrowAvailable || showingTomorrow ? 1.0 : 0.5
                onClicked: toggleDay()
            }
        }
        
        // Tomorrow not available message
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: showingTomorrow && !tomorrowAvailable
            
            Label {
                anchors.centerIn: parent
                text: i18n("Tomorrow's prices available around 14:15")
                font.pixelSize: 14
                color: Kirigami.Theme.textColor
                font.italic: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
        
        // Price chart
        Item {
            id: chartArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !showingTomorrow || tomorrowAvailable
            
            // Store maxPrice as a property accessible to children (with margin and fee)
            property real maxPriceValue: {
                var prices = showingTomorrow ? tomorrowPrices : todayPrices
                var max = 0
                var margin = FullView.priceMargin || 0
                var fee = FullView.transferFee || 0
                for (var i = 0; i < prices.length; i++) {
                    var price = prices[i] || 0
                    var totalPrice = price + margin + fee
                    if (totalPrice > max) max = totalPrice
                }
                return Math.max(max, 0.1)
            }
            
            Row {
                anchors.fill: parent
                anchors.topMargin: 20
                spacing: 4
                
                Repeater {
                    id: chartRepeater
                    // Use computedPrices which includes margin/fee - updates automatically
                    model: computedPrices

                    Column {
                        id: column
                        width: parent.width / 24 - 4
                        height: parent.height - 20
                        spacing: 4

                        property int hourIndex: index
                        // modelData is already the computed price with margin/fee
                        property real displayPrice: modelData || 0
                        property real maxPrice: chartArea.maxPriceValue
                        
                        // Price label
                        Label {
                            width: parent.width
                            height: 14
                            text: parent.displayPrice.toFixed(1)
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            visible: true
                            font.bold: hourIndex === currentHour && !showingTomorrow
                            color: hourIndex === currentHour && !showingTomorrow ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                        }
                        
                        // Bar area
                        Item {
                            id: barContainer
                            width: parent.width
                            height: parent.height - 32
                            
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: Math.min(parent.height - 2, Math.max(2, parent.height * (column.displayPrice / Math.max(column.maxPrice, 0.1))))
                                color: {
                                    if (hourIndex === currentHour && !showingTomorrow) {
                                        // Current hour bar - use Plasma accent/highlight color
                                        return Kirigami.Theme.highlightColor
                                    }
                                    return column.displayPrice < greenThreshold ? "#4CAF50" : column.displayPrice <= yellowThreshold ? "#FFC107" : "#F44336"
                                }
                                radius: 2
                                border.width: hourIndex === currentHour && !showingTomorrow ? 2 : 0
                                border.color: Kirigami.Theme.highlightColor
                            }
                        }
                        
                        // Hour label
                        Label {
                            width: parent.width
                            height: 14
                            text: hourIndex
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.bold: hourIndex === currentHour && !showingTomorrow
                            color: hourIndex === currentHour && !showingTomorrow ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
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
                    text: "< " + greenThreshold + "c"
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
                    text: greenThreshold + "-" + yellowThreshold + "c"
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
                    text: "> " + yellowThreshold + "c"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }
}
