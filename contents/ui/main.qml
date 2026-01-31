import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "code/priceFetcher.js" as PriceFetcher

PlasmoidItem {
    id: root
    
    // Properties to share between views
    property var todayPrices: []
    property var tomorrowPrices: []
    property real currentPrice: 0.0
    property bool showingTomorrow: false
    property bool tomorrowAvailable: false
    property string currentPriceColor: "#4CAF50"
    
    // Compact representation (taskbar view)
    compactRepresentation: CompactView {
        price: root.currentPrice
        priceColor: root.currentPriceColor
        onClicked: root.expanded = !root.expanded
    }
    
    // Full representation (desktop view)
    fullRepresentation: FullView {
        todayPrices: root.todayPrices
        tomorrowPrices: root.tomorrowPrices
        showingTomorrow: root.showingTomorrow
        tomorrowAvailable: root.tomorrowAvailable
        currentHour: root.lastKnownHour
        onToggleDay: root.toggleDay()
    }
    
    // Property for next update time display
    property string nextUpdateTime: ""
    property int lastKnownHour: -1
    
    Component.onCompleted: {
        PriceFetcher.initialize()
        lastKnownHour = new Date().getHours()
        refreshData()
        
        // Set up timer to update at next 14:15
        scheduleNextUpdate()
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
        
        // Update display
        var nextUpdate = new Date(Date.now() + msUntil1415)
        root.nextUpdateTime = nextUpdate.toLocaleTimeString('fi-FI', { hour: '2-digit', minute: '2-digit' })
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
        var prices = root.showingTomorrow && root.tomorrowAvailable 
            ? root.tomorrowPrices 
            : root.todayPrices
        
        if (prices.length > currentHour) {
            root.currentPrice = prices[currentHour]
            updatePriceColor(root.currentPrice)
        }
    }
    
    function updatePriceColor(price) {
        if (price < 10.0) {
            root.currentPriceColor = "#4CAF50" // Green
        } else if (price <= 20.0) {
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