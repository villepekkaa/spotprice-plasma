// PriceFetcher - Handles API calls and caching for spot-hinta.fi
// This module fetches electricity prices and caches them locally

var plasmoid = null
var cacheDir = ""
var lastFetchTime = 0
var CACHE_DURATION = 3600000 // 1 hour in milliseconds

function initialize(plasmoidRef) {
    plasmoid = plasmoidRef
    cacheDir = plasmoid.file("cache")
}

function fetchPrices(callback) {
    var now = Date.now()
    
    // Check if we have cached data that's still fresh
    if (now - lastFetchTime < CACHE_DURATION) {
        var cached = loadCachedPrices()
        if (cached.today.length > 0) {
            callback(cached.today, cached.tomorrow)
            return
        }
    }
    
    // Fetch fresh data from API
    fetchFromAPI(callback)
}

function fetchFromAPI(callback) {
    var today = []
    var tomorrow = []
    var requestsCompleted = 0
    
    function checkComplete() {
        requestsCompleted++
        if (requestsCompleted >= 2) {
            lastFetchTime = Date.now()
            cachePrices(today, tomorrow)
            callback(today, tomorrow)
        }
    }
    
    // Fetch today's prices
    var todayReq = new XMLHttpRequest()
    todayReq.onreadystatechange = function() {
        if (todayReq.readyState === XMLHttpRequest.DONE) {
            if (todayReq.status === 200) {
                try {
                    var data = JSON.parse(todayReq.responseText)
                    today = parsePrices(data)
                } catch (e) {
                    console.log("Error parsing today's prices:", e)
                }
            }
            checkComplete()
        }
    }
    
    var today = new Date()
    var dateStr = formatDate(today)
    todayReq.open("GET", "https://api.spot-hinta.fi/TodayAndDayForward")
    todayReq.send()
    
    // Fetch tomorrow's prices (if available after 14:15)
    var tomorrowReq = new XMLHttpRequest()
    tomorrowReq.onreadystatechange = function() {
        if (tomorrowReq.readyState === XMLHttpRequest.DONE) {
            if (tomorrowReq.status === 200) {
                try {
                    var data = JSON.parse(tomorrowReq.responseText)
                    // Filter for tomorrow's date
                    var tomorrowDate = new Date()
                    tomorrowDate.setDate(tomorrowDate.getDate() + 1)
                    var tomorrowStr = formatDate(tomorrowDate)
                    tomorrow = parsePricesForDate(data, tomorrowStr)
                } catch (e) {
                    console.log("Error parsing tomorrow's prices:", e)
                }
            }
            checkComplete()
        }
    }
    
    tomorrowReq.open("GET", "https://api.spot-hinta.fi/TodayAndDayForward")
    tomorrowReq.send()
}

function parsePrices(data) {
    var prices = []
    
    // spot-hinta.fi API returns array of price objects
    // Sort by hour to ensure correct order
    var sorted = data.sort(function(a, b) {
        return new Date(a.DateTime) - new Date(b.DateTime)
    })
    
    for (var i = 0; i < sorted.length; i++) {
        // Price is in EUR/MWh, convert to c/kWh
        // 1 EUR/MWh = 0.1 c/kWh
        var price = sorted[i].PriceWithTax * 0.1
        prices.push(price)
    }
    
    return prices
}

function parsePricesForDate(data, dateStr) {
    var prices = []
    
    for (var i = 0; i < data.length; i++) {
        var item = data[i]
        var itemDate = item.DateTime.split('T')[0]
        
        if (itemDate === dateStr) {
            var price = item.PriceWithTax * 0.1
            prices.push(price)
        }
    }
    
    return prices
}

function formatDate(date) {
    var year = date.getFullYear()
    var month = String(date.getMonth() + 1).padStart(2, '0')
    var day = String(date.getDate()).padStart(2, '0')
    return year + '-' + month + '-' + day
}

function cachePrices(today, tomorrow) {
    try {
        var cache = {
            timestamp: Date.now(),
            today: today,
            tomorrow: tomorrow
        }
        // In a real implementation, we'd write to a file
        // For now, we'll just keep it in memory
        cachedData = cache
    } catch (e) {
        console.log("Error caching prices:", e)
    }
}

var cachedData = null

function loadCachedPrices() {
    if (cachedData && (Date.now() - cachedData.timestamp) < CACHE_DURATION) {
        return cachedData
    }
    return { today: [], tomorrow: [] }
}