import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "../code/priceFetcher.js" as PriceFetcher

PlasmoidItem {
    id: root
    
    // Configuration properties from Plasma widget configuration
    // These are automatically saved/loaded by Plasma per-widget instance
    property real greenThreshold: (Plasmoid.configuration.greenThreshold || 100) / 10.0
    property real yellowThreshold: (Plasmoid.configuration.yellowThreshold || 200) / 10.0
    property real redThreshold: (Plasmoid.configuration.redThreshold || 300) / 10.0
    property real priceMargin: (Plasmoid.configuration.priceMargin || 0) / 100.0
    property real transferFee: (Plasmoid.configuration.transferFee || 0) / 100.0

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
        if (root.expanded) {
            refreshData(false)
            Qt.callLater(updateCurrentPrice)
        }
    }
    
    // Full representation (desktop/panel popup view)
    fullRepresentation: FullView {
        id: fullView
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
        lastUpdateTime: root.lastUpdateTime
        nextUpdateTime: root.nextUpdateTime
        lastErrorMessage: root.lastErrorMessage
        onToggleDay: root.toggleDay()
        onRefreshRequested: refreshData(false)
    }
    
    // Property for next update time display
    property string nextUpdateTime: ""
    property int lastKnownHour: -1
    property string lastKnownDate: ""
    property string lastUpdateTime: ""
    property string lastErrorMessage: ""
    
    Component.onCompleted: {
        PriceFetcher.initialize()
        var now = new Date()
        lastKnownHour = now.getHours()
        lastKnownDate = formatDate(now)
        updateStatusTimes()
        
        // Check if we need to force refresh (after 14:15 without tomorrow data)
        var isAfter1415 = now.getHours() > 14 || (now.getHours() === 14 && now.getMinutes() >= 15)
        var needsForceRefresh = isAfter1415 && !tomorrowAvailable
        
        refreshData(true)
        updateCurrentPrice()

        // Set up timer to update at next 14:15
        scheduleNextUpdate()
    }
    
    Timer {
        id: refreshTimer
        interval: 0
        repeat: false
        onTriggered: {
            console.log("Timer triggered - refreshing data")
            refreshData(true)  // Force refresh at 14:15
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
            var now = new Date()
            var currentHour = now.getHours()
            var currentDate = formatDate(now)
            
            // Check if day has changed (date string differs)
            if (currentDate !== root.lastKnownDate) {
                console.log("Day changed from", root.lastKnownDate, "to", currentDate, "- fetching new prices")
                root.lastKnownDate = currentDate
                root.lastKnownHour = currentHour
                var rolled = PriceFetcher.rolloverToToday({ date: root.lastKnownDate, today: root.todayPrices, tomorrow: root.tomorrowPrices })
                if (rolled) {
                    root.todayPrices = rolled.today
                    root.tomorrowPrices = rolled.tomorrow
                }
                refreshData(true) // Force refresh on day change
                return
            }
            
            if (currentHour !== root.lastKnownHour) {
                root.lastKnownHour = currentHour
                updateCurrentPrice()
            }
        }
    }
    
    // Monitor configuration changes and update both views
    onPriceMarginChanged: Qt.callLater(updateCurrentPrice)
    onTransferFeeChanged: Qt.callLater(updateCurrentPrice)
    
    function scheduleNextUpdate() {
        var msUntil1415 = PriceFetcher.getMsUntil1415()
        refreshTimer.interval = msUntil1415
        refreshTimer.start()
        
        // Update display with system locale
        var nextUpdate = new Date(Date.now() + msUntil1415)
        root.nextUpdateTime = Qt.formatTime(nextUpdate, Qt.locale().timeFormat(Locale.ShortFormat))
    }
    
    function refreshData(forceRefresh) {
        PriceFetcher.fetchPrices(function(today, tomorrow) {
            console.log("Price data received - today:", today.length, "tomorrow:", tomorrow.length)
            root.todayPrices = today
            root.tomorrowPrices = tomorrow
            updateStatusTimes()
            // Check if tomorrow has actual prices (not just empty/zeros)
            var hasTomorrowPrices = false
            for (var i = 0; i < tomorrow.length; i++) {
                var price = tomorrow[i]
                if (typeof price === 'number' && !isNaN(price)) {
                    hasTomorrowPrices = true
                    break
                }
            }
            root.tomorrowAvailable = hasTomorrowPrices
            console.log("Tomorrow available:", hasTomorrowPrices)
            updateCurrentPrice()
        }, forceRefresh)
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

    function updateStatusTimes() {
        var lastUpdate = PriceFetcher.getLastUpdateTime()
        if (lastUpdate) {
            root.lastUpdateTime = Qt.formatTime(new Date(lastUpdate), Qt.locale().timeFormat(Locale.ShortFormat))
        }
        root.lastErrorMessage = PriceFetcher.getLastError() || ""
    }
    
    function formatDate(date) {
        var year = date.getFullYear()
        var month = String(date.getMonth() + 1).padStart(2, '0')
        var day = String(date.getDate()).padStart(2, '0')
        return year + '-' + month + '-' + day
    }
}
