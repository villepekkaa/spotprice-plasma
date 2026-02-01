// PriceFetcher - Handles API calls and caching for spot-hinta.fi
// This module fetches electricity prices and caches them locally
// Update logic: Fetch on startup if no cache, then at 14:15 daily when tomorrow prices become available

var cachedData = null
var cacheFile = null

function initialize() {
    // Set up cache file path in Plasma's standard cache location
    if (!cacheFile && typeof StandardPaths !== 'undefined') {
        var cacheDir = StandardPaths.writableLocation(StandardPaths.CacheLocation)
        cacheFile = cacheDir + "/spotprices.json"
    }
    // Load existing cache from file
    cachedData = loadCachedPrices()
}

function fetchPrices(callback, forceRefresh) {
    var cached = loadCachedPrices()
    var now = new Date()
    var currentHour = now.getHours()
    var currentMinute = now.getMinutes()
    
    // Check if we have today's data in cache
    var todayDateStr = formatDate(now)
    var hasTodayData = cached.today.length > 0 && isSameDay(cached.date, todayDateStr)
    
    // Always fetch if no today's data in cache
    if (!hasTodayData) {
        console.log("Fetching prices: no today's data in cache")
        fetchFromAPI(callback)
        return
    }
    
    // If it's after 14:15 and we don't have tomorrow's data, fetch
    var isAfter1415 = currentHour > 14 || (currentHour === 14 && currentMinute >= 15)
    var hasTomorrowData = cached.tomorrow.length > 0 && cached.tomorrow.some(function(p) { return p > 0 })
    
    if (isAfter1415 && !hasTomorrowData) {
        console.log("Fetching prices: after 14:15 and no tomorrow data")
        fetchFromAPI(callback)
        return
    }
    
    // Force refresh if requested
    if (forceRefresh) {
        console.log("Fetching prices: forced refresh")
        fetchFromAPI(callback)
        return
    }
    
    // Use cached data
    console.log("Using cached prices - today:", cached.today.length, "tomorrow:", cached.tomorrow.length)
    callback(cached.today, cached.tomorrow)
}

function isSameDay(dateStr1, dateStr2) {
    if (!dateStr1) return false
    return dateStr1 === dateStr2
}

function fetchFromAPI(callback) {
    var today = []
    var tomorrow = []
    
    // Single API call - TodayAndDayForward returns both today's and tomorrow's prices
    var req = new XMLHttpRequest()
    req.onreadystatechange = function() {
        if (req.readyState === XMLHttpRequest.DONE) {
            if (req.status === 200) {
                try {
                    var data = JSON.parse(req.responseText)
                    // Parse today's prices
                    var todayDate = new Date()
                    var todayStr = formatDate(todayDate)
                    today = parsePricesForDate(data, todayStr)
                    
                    // Parse tomorrow's prices
                    var tomorrowDate = new Date()
                    tomorrowDate.setDate(tomorrowDate.getDate() + 1)
                    var tomorrowStr = formatDate(tomorrowDate)
                    tomorrow = parsePricesForDate(data, tomorrowStr)
                } catch (e) {
                    console.error("Error parsing price data:", e)
                }
            } else {
                console.error("API request failed with status:", req.status)
            }
            
            cachePrices(today, tomorrow)
            callback(today, tomorrow)
        }
    }
    
    req.open("GET", "https://api.spot-hinta.fi/TodayAndDayForward")
    req.send()
}

function parsePrices(data) {
    // Get today's date string and delegate to parsePricesForDate
    var today = new Date()
    var todayStr = formatDate(today)
    return parsePricesForDate(data, todayStr)
}

function parsePricesForDate(data, dateStr) {
    var hourlyPrices = []
    var hourGroups = {}
    
    for (var i = 0; i < data.length; i++) {
        var item = data[i]
        var itemDate = item.DateTime.split('T')[0]
        
        if (itemDate === dateStr) {
            var hour = parseInt(item.DateTime.split('T')[1].split(':')[0])
            
            if (!hourGroups[hour]) {
                hourGroups[hour] = []
            }
            
            hourGroups[hour].push(item.PriceWithTax * 100)
        }
    }
    
    // Calculate average for each hour (0-23)
    for (var h = 0; h < 24; h++) {
        if (hourGroups[h] && hourGroups[h].length > 0) {
            var sum = 0
            for (var j = 0; j < hourGroups[h].length; j++) {
                sum += hourGroups[h][j]
            }
            hourlyPrices.push(sum / hourGroups[h].length)
        } else {
            hourlyPrices.push(0)
        }
    }
    
    return hourlyPrices
}

function formatDate(date) {
    var year = date.getFullYear()
    var month = String(date.getMonth() + 1).padStart(2, '0')
    var day = String(date.getDate()).padStart(2, '0')
    return year + '-' + month + '-' + day
}

function cachePrices(today, tomorrow) {
    try {
        var now = new Date()
        var cache = {
            date: formatDate(now),
            timestamp: Date.now(),
            today: today,
            tomorrow: tomorrow
        }
        cachedData = cache
        
        // Persist to file using Plasma's data file mechanism
        if (typeof DataFile !== 'undefined') {
            DataFile.write("spotprices.json", JSON.stringify(cache))
        }
    } catch (e) {
        console.error("Error caching prices:", e)
    }
}

function loadCachedPrices() {
    // Try to load from persisted storage first
    if (typeof DataFile !== 'undefined') {
        try {
            var data = DataFile.read("spotprices.json")
            if (data) {
                var parsed = JSON.parse(data)
                if (parsed && parsed.date) {
                    // Validate that cache is not too old (older than 2 days)
                    var cacheDate = new Date(parsed.date)
                    var now = new Date()
                    var diffDays = (now - cacheDate) / (1000 * 60 * 60 * 24)
                    if (diffDays < 2) {
                        return parsed
                    }
                }
            }
        } catch (e) {
            console.error("Error loading cached prices:", e)
        }
    }
    
    // Fall back to in-memory cache
    if (cachedData && cachedData.date) {
        return cachedData
    }
    return { date: null, today: [], tomorrow: [] }
}

// Get milliseconds until next 14:15
function getMsUntil1415() {
    var now = new Date()
    var target = new Date()
    target.setHours(14, 15, 0, 0)
    
    // If it's already past 14:15 today, target tomorrow
    if (now > target) {
        target.setDate(target.getDate() + 1)
    }
    
    return target - now
}

// Get the time when tomorrow's prices become available
function getNextUpdateTime(locale) {
    var msUntil1415 = getMsUntil1415()
    var nextUpdate = new Date(Date.now() + msUntil1415)
    return nextUpdate.toLocaleTimeString(locale || 'fi-FI', { hour: '2-digit', minute: '2-digit' })
}