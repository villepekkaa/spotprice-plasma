import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../code/priceFetcher.js" as PriceFetcher
import "../code/configManager.js" as ConfigManager

PlasmoidItem {
    id: root
    
    // Configuration properties loaded from centralized config
    property real greenThreshold: ConfigManager.getSetting("greenThreshold")
    property real yellowThreshold: ConfigManager.getSetting("yellowThreshold")
    property real redThreshold: ConfigManager.getSetting("redThreshold")
    property real priceMargin: ConfigManager.getSetting("priceMargin")
    property real transferFee: ConfigManager.getSetting("transferFee")

    // Watch for configuration changes
    onPriceMarginChanged: console.log("Main priceMargin changed:", priceMargin)
    onTransferFeeChanged: console.log("Main transferFee changed:", transferFee)
    onGreenThresholdChanged: console.log("Main greenThreshold changed:", greenThreshold)
    
    // Properties to share between views
    property var todayPrices: []
    property var tomorrowPrices: []
    property real currentPrice: 0.0
    property real displayPrice: 0.0
    property bool showingTomorrow: false
    property bool tomorrowAvailable: false
    property string currentPriceColor: "#4CAF50"
    
    // Compact representation (taskbar view)
    compactRepresentation: CompactView {
        price: root.displayPrice
        priceColor: root.currentPriceColor
        onClicked: {
            if (root.expanded) {
                root.expanded = false
            } else {
                // Reset to today view when opening
                root.showingTomorrow = false
                root.expanded = true
                // Ensure price is updated when opening
                Qt.callLater(updateCurrentPrice)
            }
        }
    }

    // Track expanded state to sync data
    onExpandedChanged: {
        if (expanded) {
            console.log("Widget expanded - syncing data, todayPrices:", root.todayPrices.length)
            Qt.callLater(updateCurrentPrice)
        }
    }
    
    // Full representation (desktop/panel popup view)
    fullRepresentation: FullView {
        todayPrices: root.todayPrices
        tomorrowPrices: root.tomorrowPrices
        showingTomorrow: root.showingTomorrow
        tomorrowAvailable: root.tomorrowAvailable
        currentHour: root.lastKnownHour
        priceMargin: root.priceMargin
        transferFee: root.transferFee
        greenThreshold: root.greenThreshold
        yellowThreshold: root.yellowThreshold
        redThreshold: root.redThreshold
        onToggleDay: root.toggleDay()
        onRefreshRequested: {
            console.log("Refresh requested from FullView")
            updateCurrentPrice()
        }
        Component.onCompleted: {
            console.log("FullView (fullRepresentation) created - todayPrices:", todayPrices.length)
        }
    }
    
    // Property for next update time display
    property string nextUpdateTime: ""
    property int lastKnownHour: -1
    
    Component.onCompleted: {
        console.log("Main widget completed")
        ConfigManager.initialize()
        reloadSettings()
        console.log("Settings - priceMargin:", priceMargin, "transferFee:", transferFee)
        console.log("Settings - greenThreshold:", greenThreshold, "yellowThreshold:", yellowThreshold, "redThreshold:", redThreshold)
        PriceFetcher.initialize()
        lastKnownHour = new Date().getHours()
        refreshData()

        // Set up timer to update at next 14:15
        scheduleNextUpdate()
    }
    
    // Reload settings from centralized config
    function reloadSettings() {
        greenThreshold = ConfigManager.getSetting("greenThreshold")
        yellowThreshold = ConfigManager.getSetting("yellowThreshold")
        redThreshold = ConfigManager.getSetting("redThreshold")
        priceMargin = ConfigManager.getSetting("priceMargin")
        transferFee = ConfigManager.getSetting("transferFee")
        console.log("Settings reloaded from centralized config")
    }
    
    // Timer to check for config file changes (every 2 seconds)
    Timer {
        id: configCheckTimer
        interval: 2000
        repeat: true
        running: true
        property var lastConfigHash: ""
        onTriggered: {
            var settings = ConfigManager.loadSettings()
            var configHash = JSON.stringify(settings)
            if (configHash !== lastConfigHash) {
                lastConfigHash = configHash
                console.log("Config file changed, reloading...")
                root.reloadSettings()
            }
        }
    }
    
    Timer {
        id: refreshTimer
        interval: 0
        repeat: false
        onTriggered: {
            refreshData()
            // After first update at 14:15, schedule next one for tomorrow
            scheduleNextUpdate()
        }
    }
    
    // Timer to check for hour changes every minute
    Timer {
        id: hourCheckTimer
        interval: 60000 // Check every minute
        repeat: true
        running: true
        onTriggered: {
            var currentHour = new Date().getHours()
            if (currentHour !== root.lastKnownHour) {
                console.log("Hour changed from", root.lastKnownHour, "to", currentHour)
                root.lastKnownHour = currentHour
                updateCurrentPrice()
            }
        }
    }
    
    function scheduleNextUpdate() {
        var msUntil1415 = PriceFetcher.getMsUntil1415()
        refreshTimer.interval = msUntil1415
        refreshTimer.start()
        
        // Update display with system locale
        var nextUpdate = new Date(Date.now() + msUntil1415)
        root.nextUpdateTime = nextUpdate.toLocaleTimeString(Qt.locale(), { hour: '2-digit', minute: '2-digit' })
        console.log("Next price update scheduled at:", root.nextUpdateTime)
    }
    
    function refreshData() {
        console.log("Starting data refresh...")
        PriceFetcher.fetchPrices(function(today, tomorrow) {
            console.log("Data received - today:", today.length, "tomorrow:", tomorrow.length)
            root.todayPrices = today
            root.tomorrowPrices = tomorrow
            // Check if tomorrow has actual prices (not just empty/zeros)
            var hasTomorrowPrices = false
            for (var i = 0; i < tomorrow.length; i++) {
                if (tomorrow[i] > 0) {
                    hasTomorrowPrices = true
                    break
                }
            }
            root.tomorrowAvailable = hasTomorrowPrices
            console.log("Current hour:", new Date().getHours(), "Price:", today[new Date().getHours()])
            updateCurrentPrice()
        })
    }
    
    function updateCurrentPrice() {
        var currentHour = new Date().getHours()
        // Compact view always shows today's current hour price
        var prices = root.todayPrices

        if (prices.length > currentHour) {
            root.currentPrice = prices[currentHour]
            root.displayPrice = root.currentPrice + root.priceMargin + root.transferFee
            updatePriceColor(root.displayPrice)
        }
    }
    
    function updatePriceColor(price) {
        if (price < root.greenThreshold) {
            root.currentPriceColor = "#4CAF50" // Green
        } else if (price <= root.yellowThreshold) {
            root.currentPriceColor = "#FFC107" // Yellow
        } else {
            root.currentPriceColor = "#F44336" // Red
        }
    }
    
    function toggleDay() {
        root.showingTomorrow = !root.showingTomorrow
        updateCurrentPrice()
    }
}