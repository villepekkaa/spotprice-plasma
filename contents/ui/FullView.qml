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

    implicitWidth: 400
    implicitHeight: 280
    Layout.minimumWidth: 320
    Layout.minimumHeight: 200
    Layout.preferredWidth: 400
    Layout.preferredHeight: 280
    Layout.fillWidth: true
    Layout.fillHeight: true

    Component.onCompleted: {
        console.log("FullView completed - priceMargin:", priceMargin, "transferFee:", transferFee, "greenThreshold:", greenThreshold)
        console.log("FullView - todayPrices count:", todayPrices.length)
        // Set initial model
        chartRepeater.model = showingTomorrow ? tomorrowPrices : todayPrices
        refreshRequested()
    }

    onPriceMarginChanged: {
        console.log("priceMargin changed:", priceMargin)
        // Force chart to update by triggering model refresh
        if (chartRepeater.model) {
            var currentModel = chartRepeater.model
            chartRepeater.model = []
            chartRepeater.model = currentModel
        }
    }
    onTransferFeeChanged: {
        console.log("transferFee changed:", transferFee)
        // Force chart to update by triggering model refresh
        if (chartRepeater.model) {
            var currentModel = chartRepeater.model
            chartRepeater.model = []
            chartRepeater.model = currentModel
        }
    }
    onGreenThresholdChanged: console.log("greenThreshold changed:", greenThreshold)
    onTodayPricesChanged: {
        console.log("FullView todayPrices changed - count:", todayPrices.length)
        // Force repeater to refresh
        if (!showingTomorrow) {
            chartRepeater.model = null
            chartRepeater.model = todayPrices
        }
    }
    onTomorrowPricesChanged: {
        console.log("FullView tomorrowPrices changed - count:", tomorrowPrices.length)
        if (showingTomorrow) {
            chartRepeater.model = null
            chartRepeater.model = tomorrowPrices
        }
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
                console.log("maxPriceValue calculated:", max, "prices count:", prices.length, "margin:", margin, "fee:", fee)
                return Math.max(max, 0.1)
            }
            onMaxPriceValueChanged: console.log("maxPriceValue changed to:", maxPriceValue)
            
            Row {
                anchors.fill: parent
                anchors.topMargin: 20
                spacing: 4
                
                Repeater {
                    id: chartRepeater
                    // Simple model without conditional
                    property var currentPrices: showingTomorrow ? tomorrowPrices : todayPrices
                    model: currentPrices
                    
                    Component.onCompleted: console.log("Chart repeater completed - model count:", model ? model.length : 0)
                    onModelChanged: console.log("Chart repeater model changed - count:", model ? model.length : 0)
                    onCurrentPricesChanged: {
                        console.log("currentPrices changed - updating model, count:", currentPrices.length)
                        model = currentPrices
                    }

                    Column {
                        id: column
                        width: parent.width / 24 - 4
                        height: parent.height - 20 // Account for Row's topMargin
                        spacing: 4

                        property int hourIndex: index
                        property real basePrice: modelData || 0
                        // Safe property access with fallback values
                        property real displayPrice: basePrice + (FullView.priceMargin || 0) + (FullView.transferFee || 0)
                        property real maxPrice: chartArea.maxPriceValue

                        Component.onCompleted: {
                            console.log("Column", hourIndex, "maxPrice:", maxPrice, "displayPrice:", displayPrice, "ratio:", displayPrice / maxPrice)
                        }

                        onDisplayPriceChanged: {
                            if (hourIndex === currentHour && !showingTomorrow) {
                                console.log("Current hour price changed:", displayPrice)
                            }
                        }
                        
                        // Price label
                        Label {
                            width: parent.width
                            height: 14
                            text: parent.displayPrice.toFixed(1)
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            visible: parent.displayPrice > 0
                            font.bold: index === currentHour && !showingTomorrow
                            color: index === currentHour && !showingTomorrow ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
                        }
                        
                        // Bar area
                        Item {
                            id: barContainer
                            width: parent.width
                            height: parent.height - 32 // 14 (price) + 14 (hour) + 4 (spacing)
                            
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: Math.min(parent.height - 2, Math.max(2, parent.height * (column.displayPrice / Math.max(column.maxPrice, 0.1))))
                                color: column.displayPrice < greenThreshold ? "#4CAF50" : column.displayPrice <= yellowThreshold ? "#FFC107" : "#F44336"
                                radius: 2
                                border.width: index === currentHour && !showingTomorrow ? 2 : 0
                                border.color: Kirigami.Theme.highlightColor
                            }
                        }
                        
                        // Hour label
                        Label {
                            width: parent.width
                            height: 14
                            text: index
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
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