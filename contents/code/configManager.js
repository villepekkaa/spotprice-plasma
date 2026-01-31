// Centralized configuration manager for all widget instances
// Settings are stored in ~/.config/spotprices/settings.json

.pragma library

function getHomeDir() {
    // Get home directory from environment
    // In QML .pragma library, we need to access environment differently
    var home = "";
    try {
        // Try to get from standard locations
        if (typeof Qt !== 'undefined' && Qt.environment) {
            home = Qt.environment.HOME || Qt.environment.USERPROFILE;
        }
    } catch (e) {
        console.log("Error getting home dir:", e);
    }
    
    // If still empty, try to detect from current working directory
    if (!home) {
        try {
            var xhr = new XMLHttpRequest();
            xhr.open("GET", "file:///proc/self/environ", false);
            xhr.send();
            if (xhr.status === 200 || xhr.status === 0) {
                var env = xhr.responseText;
                var match = env.match(/HOME=([^\0]+)/);
                if (match) {
                    home = match[1];
                }
            }
        } catch (e) {
            // Fallback
        }
    }
    
    // Hardcoded fallback for testing
    if (!home || home === "/home/user") {
        home = "/home/villepekkaa";
    }
    
    return home;
}

var configDir = getHomeDir() + "/.config/spotprices";
var configFile = configDir + "/settings.json";

// Default values
var defaultSettings = {
    greenThreshold: 10.0,
    yellowThreshold: 20.0,
    redThreshold: 30.0,
    priceMargin: 0.0,
    transferFee: 0.0
};

var currentSettings = {};
var initialized = false;

// Deep copy helper
function deepCopy(obj) {
    return JSON.parse(JSON.stringify(obj));
}

function loadSettings() {
    if (initialized) {
        return deepCopy(currentSettings);
    }
    
    try {
        // Try to read existing config file
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + configFile, false);
        xhr.send();
        
        if (xhr.status === 200 || xhr.status === 0) {
            var loaded = JSON.parse(xhr.responseText);
            // Merge with defaults
            for (var key in defaultSettings) {
                currentSettings[key] = loaded[key] !== undefined ? loaded[key] : defaultSettings[key];
            }
            initialized = true;
            console.log("Settings loaded from:", configFile);
            return deepCopy(currentSettings);
        }
    } catch (e) {
        console.log("No existing config found, using defaults:", e);
    }
    
    // Use defaults if loading failed
    currentSettings = deepCopy(defaultSettings);
    initialized = true;
    
    // Try to save defaults
    saveSettings(currentSettings);
    
    return deepCopy(currentSettings);
}

function saveSettings(settings) {
    try {
        // We can't create directories from QML, so just try to write the file
        // User needs to create ~/.config/spotprices/ manually first time
        var xhr = new XMLHttpRequest();
        xhr.open("PUT", "file://" + configFile, false);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.send(JSON.stringify(settings, null, 2));
        
        currentSettings = deepCopy(settings);
        console.log("Settings saved to:", configFile);
        return true;
    } catch (e) {
        console.log("Failed to save settings:", e);
        // Still update current settings in memory even if save fails
        currentSettings = deepCopy(settings);
        return false;
    }
}

function getSetting(key) {
    if (!initialized) {
        loadSettings();
    }
    return currentSettings[key] !== undefined ? currentSettings[key] : defaultSettings[key];
}

function setSetting(key, value) {
    if (!initialized) {
        loadSettings();
    }
    currentSettings[key] = value;
    saveSettings(currentSettings);
}

function initialize() {
    loadSettings();
}
