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
    }
    
    // Full representation (desktop view)
    fullRepresentation: FullView {
        todayPrices: root.todayPrices
        tomorrowPrices: root.tomorrowPrices
        showingTomorrow: root.showingTomorrow
        tomorrowAvailable: root.tomorrowAvailable
        onToggleDay: root.toggleDay()
    }
    
    Component.onCompleted: {
        PriceFetcher.initialize(Plasmoid)
        refreshData()
        
        // Set up timer to refresh every hour
        refreshTimer.start()
    }
    
    Timer {
        id: refreshTimer
        interval: 3600000 // 1 hour in milliseconds
        repeat: true
        onTriggered: refreshData()
    }
    
    function refreshData() {
        PriceFetcher.fetchPrices(function(today, tomorrow) {
            root.todayPrices = today
            root.tomorrowPrices = tomorrow
            root.tomorrowAvailable = tomorrow.length > 0
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