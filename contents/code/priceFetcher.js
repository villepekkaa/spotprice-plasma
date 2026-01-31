// PriceFetcher - Handles API calls and caching for spot-hinta.fi
// This module fetches electricity prices and caches them locally
// Update logic: Fetch on startup if no cache, then at 14:15 daily when tomorrow prices become available

var cachedData = null
var cacheDir = ""

function initialize() {
    // Cache directory will be set from QML side
    // For now, we don't need to do anything here
}

function fetchPrices(callback) {
    var cached = loadCachedPrices()
    var now = new Date()
    var currentHour = now.getHours()
    var currentMinute = now.getMinutes()
    
    // Check if we have today's data in cache
    var todayDateStr = formatDate(now)
    var hasTodayData = cached.today.length > 0 && isSameDay(cached.date, todayDateStr)
    
    // Always fetch if no today's data in cache
    if (!hasTodayData) {
        fetchFromAPI(callback)
        return
    }
    
    // If it's after 14:15 and we don't have tomorrow's data, fetch
    var isAfter1415 = currentHour > 14 || (currentHour === 14 && currentMinute >= 15)
    var hasTomorrowData = cached.tomorrow.length > 0
    
    if (isAfter1415 && !hasTomorrowData) {
        fetchFromAPI(callback)
        return
    }
    
    // Use cached data
    callback(cached.today, cached.tomorrow)
}

function isSameDay(dateStr1, dateStr2) {
    if (!dateStr1) return false
    return dateStr1 === dateStr2
}

function fetchFromAPI(callback) {
    var today = []
    var tomorrow = []
    var requestsCompleted = 0
    
    function checkComplete() {
        requestsCompleted++
        if (requestsCompleted >= 2) {
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
                }
            } else {
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
                }
            }
            checkComplete()
        }
    }
    
    tomorrowReq.open("GET", "https://api.spot-hinta.fi/TodayAndDayForward")
    tomorrowReq.send()
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
        // In a real implementation, we'd write to a file
        // For now, we'll just keep it in memory
        cachedData = cache
    } catch (e) {
    }
}

function loadCachedPrices() {
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