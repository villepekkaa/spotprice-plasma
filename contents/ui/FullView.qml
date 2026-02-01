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
    property string lastUpdateTime: ""
    property string nextUpdateTime: ""
    property string lastErrorMessage: ""
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
            var price = prices[i]
            if (typeof price === 'number' && !isNaN(price)) {
                result.push(price + margin + fee)
            } else {
                result.push(null)
            }
        }
        return result
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // Header with title, status info and day toggle
        RowLayout {
            Layout.fillWidth: true
            Layout.minimumHeight: 50
            spacing: 8
            
            // Left side: status info
            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter
                
                Label {
                    text: lastUpdateTime ? i18n("Last update %1", lastUpdateTime) : ""
                    font.pixelSize: 10
                    color: Kirigami.Theme.textColor
                    visible: lastUpdateTime.length > 0
                }
                
                Label {
                    text: nextUpdateTime ? i18n("Next update %1", nextUpdateTime) : ""
                    font.pixelSize: 10
                    color: Kirigami.Theme.textColor
                    visible: nextUpdateTime.length > 0
                }
            }

            Item { Layout.fillWidth: true }

            // Center: Title
            Label {
                text: showingTomorrow ? i18n("Tomorrow") : i18n("Today")
                font.pixelSize: 18
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            // Right side: Toggle button
            PlasmaComponents.Button {
                text: showingTomorrow ? i18n("Today") : i18n("Tomorrow")
                enabled: true
                opacity: tomorrowAvailable || showingTomorrow ? 1.0 : 0.5
                onClicked: toggleDay()
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // Error message with fixed height to prevent layout jumping
        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: lastErrorMessage.length > 0 ? 20 : 0
            Layout.maximumHeight: lastErrorMessage.length > 0 ? 40 : 0
            
            Label {
                anchors.fill: parent
                text: lastErrorMessage ? i18n("Update failed (%1), using cached prices", lastErrorMessage) : ""
                font.pixelSize: 11
                color: Kirigami.Theme.negativeTextColor
                wrapMode: Text.Wrap
                visible: lastErrorMessage.length > 0
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Min/Max price info - centered
        // Wrapped in Item with fixed height to prevent layout jumping
        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: minMaxRow.visible ? 70 : 0
            Layout.maximumHeight: minMaxRow.visible ? 70 : 0
            
            Row {
                id: minMaxRow
                anchors.centerIn: parent
                spacing: 24
                visible: computedPrices.length > 0 && (!showingTomorrow || tomorrowAvailable)

            // Calculate min, max and averages (24h and 7-23 daytime)
            property var minMaxInfo: {
                var prices = computedPrices
                var minPrice = Infinity
                var maxPrice = -Infinity
                var minHour = -1
                var maxHour = -1
                var sum24h = 0
                var sumDaytime = 0
                var count24h = 0
                var countDaytime = 0

                for (var i = 0; i < prices.length; i++) {
                    var price = prices[i]
                    if (typeof price !== 'number' || isNaN(price)) {
                        continue
                    }
                    sum24h += price
                    count24h++
                    // Daytime hours: 7-23 (inclusive)
                    if (i >= 7 && i <= 23) {
                        sumDaytime += price
                        countDaytime++
                    }
                    if (price < minPrice) {
                        minPrice = price
                        minHour = i
                    }
                    if (price > maxPrice) {
                        maxPrice = price
                        maxHour = i
                    }
                }

                return {
                    minPrice: minPrice === Infinity ? 0 : minPrice,
                    maxPrice: maxPrice === -Infinity ? 0 : maxPrice,
                    avgPrice24h: count24h > 0 ? sum24h / count24h : 0,
                    avgPriceDaytime: countDaytime > 0 ? sumDaytime / countDaytime : 0,
                    minHour: minHour,
                    maxHour: maxHour
                }
            }

            // Cheapest hour
            Rectangle {
                width: minCol.width + 16
                height: minCol.height + 12
                color: Qt.rgba(0.29, 0.68, 0.31, 0.15)  // #4CAF50 with 15% opacity
                radius: 6
                border.width: 1
                border.color: Qt.rgba(0.29, 0.68, 0.31, 0.3)

                Column {
                    id: minCol
                    anchors.centerIn: parent
                    spacing: 2

                    Label {
                        text: i18n("Cheapest")
                        font.pixelSize: 10
                        color: "#388E3C"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Row {
                        spacing: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                    Label {
                        text: minMaxRow.minMaxInfo.minHour + " - " + (minMaxRow.minMaxInfo.minHour + 1)
                        font.pixelSize: 12
                        font.bold: true
                        color: "#2E7D32"
                    }
                        Label {
                            text: "•"
                            font.pixelSize: 12
                            color: "#388E3C"
                        }
                        Label {
                            text: minMaxRow.minMaxInfo.minPrice.toFixed(1) + " c/kWh"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#2E7D32"
                        }
                    }
                }
            }

            // Daytime average (7-23)
            Rectangle {
                width: avgDayCol.width + 16
                height: avgDayCol.height + 12
                color: Qt.rgba(0.13, 0.59, 0.95, 0.15)  // #2196F3 with 15% opacity
                radius: 6
                border.width: 1
                border.color: Qt.rgba(0.13, 0.59, 0.95, 0.3)

                Column {
                    id: avgDayCol
                    anchors.centerIn: parent
                    spacing: 2

                    Label {
                        text: i18n("Average 7-23")
                        font.pixelSize: 10
                        color: "#1976D2"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Row {
                        spacing: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        Label {
                            text: minMaxRow.minMaxInfo.avgPriceDaytime.toFixed(1) + " c/kWh"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#1565C0"
                        }
                    }
                }
            }

            // 24h average
            Rectangle {
                width: avg24Col.width + 16
                height: avg24Col.height + 12
                color: Qt.rgba(0.13, 0.59, 0.95, 0.10)  // Lighter blue for secondary avg
                radius: 6
                border.width: 1
                border.color: Qt.rgba(0.13, 0.59, 0.95, 0.2)

                Column {
                    id: avg24Col
                    anchors.centerIn: parent
                    spacing: 2

                    Label {
                        text: i18n("Average 24h")
                        font.pixelSize: 10
                        color: "#1976D2"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Row {
                        spacing: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                        Label {
                            text: minMaxRow.minMaxInfo.avgPrice24h.toFixed(1) + " c/kWh"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#1565C0"
                        }
                    }
                }
            }

            // Most expensive hour
            Rectangle {
                width: maxCol.width + 16
                height: maxCol.height + 12
                color: Qt.rgba(0.96, 0.26, 0.21, 0.15)  // #F44336 with 15% opacity
                radius: 6
                border.width: 1
                border.color: Qt.rgba(0.96, 0.26, 0.21, 0.3)

                Column {
                    id: maxCol
                    anchors.centerIn: parent
                    spacing: 2

                    Label {
                        text: i18n("Most expensive")
                        font.pixelSize: 10
                        color: "#D32F2F"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Row {
                        spacing: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                    Label {
                        text: minMaxRow.minMaxInfo.maxHour + " - " + (minMaxRow.minMaxInfo.maxHour + 1)
                        font.pixelSize: 12
                        font.bold: true
                        color: "#C62828"
                    }
                        Label {
                            text: "•"
                            font.pixelSize: 12
                            color: "#D32F2F"
                        }
                        Label {
                            text: minMaxRow.minMaxInfo.maxPrice.toFixed(1) + " c/kWh"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#C62828"
                        }
                    }
                }
            }
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
                    var price = prices[i]
                    if (typeof price !== 'number' || isNaN(price)) {
                        continue
                    }
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
                        property real displayPrice: (typeof modelData === 'number' && !isNaN(modelData)) ? modelData : 0
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
