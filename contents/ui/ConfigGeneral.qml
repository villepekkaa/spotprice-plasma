import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami
import "../code/configManager.js" as ConfigManager

ColumnLayout {
    id: page
    
    // Layout sizing
    implicitWidth: parent.width
    implicitHeight: childrenRect.height
    spacing: Kirigami.Units.smallSpacing
    
    // Tab title (required by Plasma config system)
    property string title: i18n("General")
    
    // Dummy cfg_ properties required by Plasma config system
    // These are not used but must exist for compatibility
    property int cfg_greenThreshold: 100
    property int cfg_yellowThreshold: 200
    property int cfg_redThreshold: 300
    property int cfg_priceMargin: 0
    property int cfg_transferFee: 0
    
    // Page header - left aligned like About page title
    Label {
        text: i18n("General Settings (Shared)")
        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
        Layout.fillWidth: true
        Layout.leftMargin: Kirigami.Units.largeSpacing
        Layout.topMargin: Kirigami.Units.largeSpacing * 2
        Layout.bottomMargin: Kirigami.Units.largeSpacing
    }
    
    // Centered content container
    Item {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: formContainer.implicitWidth
        implicitHeight: formContainer.implicitHeight
        
        Kirigami.FormLayout {
            id: formContainer
            anchors.centerIn: parent
            
            // Price thresholds group
            Label {
                Kirigami.FormData.label: i18n("Price Thresholds (c/kWh)")
                text: ""
                font.bold: true
            }
            
            SpinBox {
                id: greenThresholdSpin
                Kirigami.FormData.label: i18n("Green threshold:")
                from: 0
                to: 1000
                stepSize: 1
                value: Math.round(ConfigManager.getSetting("greenThreshold") * 10)
                textFromValue: function(value, locale) {
                    return (value / 10).toFixed(1)
                }
                valueFromText: function(text, locale) {
                    return Math.round(parseFloat(text) * 10)
                }
                onValueModified: {
                    ConfigManager.setSetting("greenThreshold", value / 10)
                }
            }
            
            SpinBox {
                id: yellowThresholdSpin
                Kirigami.FormData.label: i18n("Yellow threshold:")
                from: 0
                to: 1000
                stepSize: 1
                value: Math.round(ConfigManager.getSetting("yellowThreshold") * 10)
                textFromValue: function(value, locale) {
                    return (value / 10).toFixed(1)
                }
                valueFromText: function(text, locale) {
                    return Math.round(parseFloat(text) * 10)
                }
                onValueModified: {
                    ConfigManager.setSetting("yellowThreshold", value / 10)
                }
            }
            
            SpinBox {
                id: redThresholdSpin
                Kirigami.FormData.label: i18n("Red threshold:")
                from: 0
                to: 1000
                stepSize: 1
                value: Math.round(ConfigManager.getSetting("redThreshold") * 10)
                textFromValue: function(value, locale) {
                    return (value / 10).toFixed(1)
                }
                valueFromText: function(text, locale) {
                    return Math.round(parseFloat(text) * 10)
                }
                onValueModified: {
                    ConfigManager.setSetting("redThreshold", value / 10)
                }
            }
            
            // Price margin group
            Label {
                Kirigami.FormData.label: i18n("Price Margin")
                text: ""
                font.bold: true
            }
            
            SpinBox {
                id: priceMarginSpin
                Kirigami.FormData.label: i18n("Margin (c/kWh):")
                from: 0
                to: 10000
                stepSize: 1
                value: Math.round(ConfigManager.getSetting("priceMargin") * 100)
                textFromValue: function(value, locale) {
                    return (value / 100).toFixed(2)
                }
                valueFromText: function(text, locale) {
                    return Math.round(parseFloat(text) * 100)
                }
                onValueModified: {
                    ConfigManager.setSetting("priceMargin", value / 100)
                }
            }
            
            Label {
                text: i18n("This margin is added to all displayed prices")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7
            }
            
            // Transfer fee group
            Label {
                Kirigami.FormData.label: i18n("Transfer Fee")
                text: ""
                font.bold: true
            }
            
            SpinBox {
                id: transferFeeSpin
                Kirigami.FormData.label: i18n("Transfer fee (c/kWh):")
                from: 0
                to: 10000
                stepSize: 1
                value: Math.round(ConfigManager.getSetting("transferFee") * 100)
                textFromValue: function(value, locale) {
                    return (value / 100).toFixed(2)
                }
                valueFromText: function(text, locale) {
                    return Math.round(parseFloat(text) * 100)
                }
                onValueModified: {
                    ConfigManager.setSetting("transferFee", value / 100)
                }
            }
            
            Label {
                text: i18n("This transfer fee is added to all displayed prices")
                font.pointSize: Kirigami.Theme.smallFont.pointSize
                opacity: 0.7
            }
        }
    }
    
    Item { Layout.fillHeight: true }
}
