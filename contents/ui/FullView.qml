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
    Layout.minimumWidth: 600
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

    property bool hasCurrentPrice: !showingTomorrow
        && currentHour >= 0
        && currentHour < computedPrices.length
        && typeof computedPrices[currentHour] === "number"
        && !isNaN(computedPrices[currentHour])
    property real currentDisplayPrice: hasCurrentPrice ? computedPrices[currentHour] : 0
    property var currentPriceStyle: hasCurrentPrice ? priceStyle(currentDisplayPrice) : ({
        bg: "transparent",
        border: "transparent",
        text: Kirigami.Theme.textColor
    })

    function priceStyle(price) {
        if (price < 0) {
            return {
                bg: Qt.rgba(0.13, 0.59, 0.95, 0.12),
                border: Qt.rgba(0.13, 0.59, 0.95, 0.25),
                text: "#1565C0"
            }
        }
        if (price < greenThreshold) {
            return {
                bg: Qt.rgba(0.29, 0.68, 0.31, 0.12),
                border: Qt.rgba(0.29, 0.68, 0.31, 0.3),
                text: "#2E7D32"
            }
        }
        if (price <= yellowThreshold) {
            return {
                bg: Qt.rgba(1, 0.76, 0.03, 0.14),
                border: Qt.rgba(1, 0.76, 0.03, 0.35),
                text: "#F57F17"
            }
        }
        return {
            bg: Qt.rgba(0.96, 0.26, 0.21, 0.12),
            border: Qt.rgba(0.96, 0.26, 0.21, 0.3),
            text: "#C62828"
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        
        // Header: Now with current hour and price (centered)
        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: 50

            // Center: Now with current hour and price (in bordered box)
            Rectangle {
                visible: !showingTomorrow && hasCurrentPrice
                color: currentPriceStyle.bg
                border.color: currentPriceStyle.border
                border.width: 2
                radius: 8
                anchors.centerIn: parent
                 implicitWidth: nowPriceCol.width + 12
                implicitHeight: nowPriceCol.height + 8

                Column {
                    id: nowPriceCol
                    spacing: 2
                    anchors.centerIn: parent

                    // Current hour info: "Now 9 - 10"
                    Label {
                        text: i18n("Price %1 - %2", currentHour, currentHour + 1)
                        font.pixelSize: 12
                        color: Kirigami.Theme.textColor
                        opacity: 0.7
                        horizontalAlignment: Text.AlignHCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    // Price
                    Row {
                        spacing: 6
                        anchors.horizontalCenter: parent.horizontalCenter

                        Label {
                            text: currentDisplayPrice.toFixed(2)
                            font.pixelSize: 16
                            font.bold: true
                            color: currentPriceStyle.text
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: i18n("c/kWh")
                            font.pixelSize: 12
                            color: Kirigami.Theme.textColor
                            opacity: 0.7
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: 2
                        }
                    }
                }
            }

            // Tomorrow title (centered when showing tomorrow)
            Label {
                text: i18n("Tomorrow")
                font.pixelSize: 18
                font.bold: true
                anchors.centerIn: parent
                visible: showingTomorrow
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
                color: Qt.rgba(0.13, 0.59, 0.95, 0.10)
                radius: 6
                border.width: 1
                border.color: Qt.rgba(0.13, 0.59, 0.95, 0.2)

                Column {
                    id: minCol
                    anchors.centerIn: parent
                    spacing: 2

                    Label {
                        text: i18n("Cheapest")
                        font.pixelSize: 10
                        color: "#1976D2"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Row {
                        spacing: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                    Label {
                        text: minMaxRow.minMaxInfo.minHour + " - " + (minMaxRow.minMaxInfo.minHour + 1)
                        font.pixelSize: 12
                        font.bold: true
                        color: "#1565C0"
                    }
                        Label {
                            text: "•"
                            font.pixelSize: 12
                            color: "#1976D2"
                        }
                        Label {
                            text: minMaxRow.minMaxInfo.minPrice.toFixed(2) + " c/kWh"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#1565C0"
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
                            text: minMaxRow.minMaxInfo.avgPriceDaytime.toFixed(2) + " c/kWh"
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
                            text: minMaxRow.minMaxInfo.avgPrice24h.toFixed(2) + " c/kWh"
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
                color: Qt.rgba(0.13, 0.59, 0.95, 0.10)
                radius: 6
                border.width: 1
                border.color: Qt.rgba(0.13, 0.59, 0.95, 0.2)

                Column {
                    id: maxCol
                    anchors.centerIn: parent
                    spacing: 2

                    Label {
                        text: i18n("Most expensive")
                        font.pixelSize: 10
                        color: "#1976D2"
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Row {
                        spacing: 4
                        anchors.horizontalCenter: parent.horizontalCenter
                    Label {
                        text: minMaxRow.minMaxInfo.maxHour + " - " + (minMaxRow.minMaxInfo.maxHour + 1)
                        font.pixelSize: 12
                        font.bold: true
                        color: "#1565C0"
                    }
                        Label {
                            text: "•"
                            font.pixelSize: 12
                            color: "#1976D2"
                        }
                        Label {
                            text: minMaxRow.minMaxInfo.maxPrice.toFixed(2) + " c/kWh"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#1565C0"
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

            property int axisWidth: 44
            property int axisGap: 8
            property int chartPadding: 12
            property int barSpacing: 4
            property int idealBarWidth: 14
            property real desiredPlotWidth: 24 * idealBarWidth + 23 * barSpacing
            property real maxPlotWidth: Math.max(0, width - 2 * (chartPadding + axisWidth + axisGap))
            property real plotWidth: Math.min(desiredPlotWidth, maxPlotWidth)

            property var scaleInfo: {
                var prices = computedPrices
                var min = Infinity
                var max = -Infinity
                for (var i = 0; i < prices.length; i++) {
                    var price = prices[i]
                    if (typeof price !== 'number' || isNaN(price)) {
                        continue
                    }
                    if (price < min) min = price
                    if (price > max) max = price
                }
                if (min === Infinity) {
                    min = 0
                    max = 1
                }

                var minScale = Math.min(0, min)
                var maxScale = Math.max(0, max)
                if (minScale === maxScale) {
                    maxScale = minScale + 1
                }

                var range = maxScale - minScale
                var step = 5
                if (range <= 20) {
                    step = 2
                } else if (range <= 40) {
                    step = 5
                } else if (range <= 80) {
                    step = 10
                } else {
                    step = 20
                }

                var start = Math.floor(minScale / step) * step
                var end = Math.ceil(maxScale / step) * step
                var ticks = []
                for (var v = start; v <= end + 0.0001; v += step) {
                    ticks.push(v)
                }

                return { minScale: start, maxScale: end, step: step, ticks: ticks }
            }

            function valueToY(value, height) {
                var minScale = scaleInfo.minScale
                var maxScale = scaleInfo.maxScale
                return (maxScale - value) / (maxScale - minScale) * height
            }

            function zeroY(height) {
                return valueToY(0, height)
            }

            Item {
                id: chartContent
                anchors.fill: parent

                Item {
                    id: yAxis
                    width: chartArea.axisWidth
                    anchors.right: plotArea.left
                    anchors.rightMargin: chartArea.axisGap
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    Repeater {
                        model: chartArea.scaleInfo.ticks.length
                        Label {
                            text: chartArea.scaleInfo.ticks[index].toFixed(0)
                            font.pixelSize: 9
                            color: Kirigami.Theme.textColor
                            anchors.right: parent.right
                            rightPadding: 4
                            y: barArea.y + chartArea.valueToY(chartArea.scaleInfo.ticks[index], barArea.height) - height / 2
                        }
                    }
                }

                Item {
                    id: plotArea
                    width: chartArea.plotWidth
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom

                    Item {
                        id: barArea
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: xAxis.top
                        anchors.bottomMargin: 6

                        property real barWidth: (width - 23 * chartArea.barSpacing) / 24

                        Repeater {
                            model: chartArea.scaleInfo.ticks.length
                            Rectangle {
                                width: parent.width
                                height: 1
                                color: Kirigami.Theme.textColor
                                opacity: 0.1
                                y: chartArea.valueToY(chartArea.scaleInfo.ticks[index], barArea.height)
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Kirigami.Theme.textColor
                            opacity: 0.25
                            y: chartArea.zeroY(barArea.height)
                            visible: chartArea.scaleInfo.minScale < 0 && chartArea.scaleInfo.maxScale > 0
                        }

                        Row {
                            anchors.fill: parent
                            spacing: chartArea.barSpacing

                            Repeater {
                                id: chartRepeater
                                model: computedPrices

                                Item {
                                    width: barArea.barWidth
                                    height: parent.height

                                    property int hourIndex: index
                                    property real displayPrice: (typeof modelData === 'number' && !isNaN(modelData)) ? modelData : 0
                                    property real zeroLineY: chartArea.zeroY(parent.height)
                                    property real valueY: chartArea.valueToY(displayPrice, parent.height)

                                    Rectangle {
                                        width: parent.width
                                        height: Math.max(2, Math.abs(parent.zeroLineY - parent.valueY))
                                        y: parent.displayPrice >= 0 ? parent.valueY : parent.zeroLineY
                                        color: {
                                            if (parent.hourIndex === currentHour && !showingTomorrow) {
                                                return Kirigami.Theme.highlightColor
                                            }
                                            if (parent.displayPrice < 0) {
                                                return "#2196F3"
                                            }
                                            return parent.displayPrice < greenThreshold ? "#4CAF50" : parent.displayPrice <= yellowThreshold ? "#FFC107" : "#F44336"
                                        }
                                        radius: 2
                                        border.width: parent.hourIndex === currentHour && !showingTomorrow ? 2 : 0
                                        border.color: Kirigami.Theme.highlightColor
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        id: xAxis
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 14

                        Repeater {
                            model: 24
                            Item {
                                width: barArea.barWidth
                                height: parent.height
                                x: index * (barArea.barWidth + chartArea.barSpacing)
                                visible: index % 2 === 0

                                Label {
                                    anchors.centerIn: parent
                                    text: index
                                    font.pixelSize: 9
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: Kirigami.Theme.textColor
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // Legend + status (bottom row)
        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: Math.max(legendRow.height, statusColumn.implicitHeight)

            ColumnLayout {
                id: statusColumn
                spacing: 2
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: lastUpdateTime.length > 0 || nextUpdateTime.length > 0

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

            Row {
                id: legendRow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
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

            // Toggle button (bottom right)
            PlasmaComponents.Button {
                text: showingTomorrow ? i18n("Today") : i18n("Tomorrow")
                enabled: true
                opacity: tomorrowAvailable || showingTomorrow ? 1.0 : 0.5
                onClicked: toggleDay()
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
