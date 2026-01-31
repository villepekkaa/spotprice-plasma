import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: page
    
    // Layout sizing
    implicitWidth: parent.width
    implicitHeight: childrenRect.height
    spacing: Kirigami.Units.smallSpacing
    
    // Tab title (required by Plasma config system)
    property string title: i18n("General")
    
    // Properties with cfg_ prefix for configuration binding
    property alias cfg_greenThreshold: greenThresholdSpin.value
    property alias cfg_yellowThreshold: yellowThresholdSpin.value
    property alias cfg_redThreshold: redThresholdSpin.value
    property alias cfg_priceMargin: priceMarginSpin.value
    property alias cfg_transferFee: transferFeeSpin.value
    
    // Default values (required by Plasma config system)
    property int cfg_greenThresholdDefault: 100
    property int cfg_yellowThresholdDefault: 200
    property int cfg_redThresholdDefault: 300
    property int cfg_priceMarginDefault: 0
    property int cfg_transferFeeDefault: 0
    property bool cfg_showTitleDefault: true
    
    // Dummy property to satisfy Plasma config requirements
    property bool cfg_showTitle: true
    
    // Page header
    Label {
        text: i18n("General Settings")
        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.5
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
                textFromValue: function(value, locale) {
                    return (value / 10).toFixed(1)
                }
                valueFromText: function(text, locale) {
                    return Math.round(parseFloat(text) * 10)
                }
            }
            
            SpinBox {
                id: yellowThresholdSpin
                Kirigami.FormData.label: i18n("Yellow threshold:")
                from: 0
                to: 1000
                stepSize: 1
                textFromValue: function(value, locale) {
                    return (value / 10).toFixed(1)
                }
                valueFromText: function(text, locale) {
                    return Math.round(parseFloat(text) * 10)
                }
            }
            
            SpinBox {
                id: redThresholdSpin
                Kirigami.FormData.label: i18n("Red threshold:")
                from: 0
                to: 1000
                stepSize: 1
                textFromValue: function(value, locale) {
                    return (value / 10).toFixed(1)
                }
                valueFromText: function(text, locale) {
                    return Math.round(parseFloat(text) * 10)
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
                textFromValue: function(value, locale) {
                    return (value / 100).toFixed(2)
                }
                valueFromText: function(text, locale) {
                    return Math.round(parseFloat(text) * 100)
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
                textFromValue: function(value, locale) {
                    return (value / 100).toFixed(2)
                }
                valueFromText: function(text, locale) {
                    return Math.round(parseFloat(text) * 100)
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
