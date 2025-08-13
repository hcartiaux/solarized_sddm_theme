import QtQuick 2.15
import QtQuick.Controls 2.15
import SddmComponents 2.0

Rectangle {
    id: root

    // Theme and layout objects passed from parent
    property QtObject theme
    property QtObject layout
    property string themeRoot

    // Navigation signals
    signal focusNext()
    signal focusPrevious()
    signal requestLoginFocus()

    // Public API for external focus management
    function focusSession() {
        session.forceActiveFocus()
    }

    function getSessionIndex() {
        return session.index
    }

    // Focus order management - left to right, top to bottom
    property var focusOrder: {
        var order = [session]
        if (layoutBox.visible) {
            order.push(layoutBox)
        }
        if (btnReboot.visible) {
            order.push(btnReboot)
        }
        if (btnShutdown.visible) {
            order.push(btnShutdown)
        }
        return order
    }

    function focusNextInOrder() {
        var currentIndex = getCurrentFocusIndex()
        var nextIndex = (currentIndex + 1) % focusOrder.length

        // If we're at the last item, signal to move to login form
        if (currentIndex === focusOrder.length - 1) {
            root.requestLoginFocus()
        } else {
            focusOrder[nextIndex].forceActiveFocus()
        }
    }

    function focusPreviousInOrder() {
        var currentIndex = getCurrentFocusIndex()
        if (currentIndex === 0) {
            // Focus last item in action bar
            focusOrder[focusOrder.length - 1].forceActiveFocus()
        } else {
            focusOrder[currentIndex - 1].forceActiveFocus()
        }
    }

    function getCurrentFocusIndex() {
        for (var i = 0; i < focusOrder.length; i++) {
            if (focusOrder[i].activeFocus) {
                return i
            }
        }
        return 0 // Default to first item
    }

    color: "transparent"

    Row {
        id: leftControls
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
        height: parent.height
        spacing: parent.width * layout.standardSpacing

        // Session selector with icon
        Text {
            text: "\uF108"
            font {
                family: theme.fonts.family
                pixelSize: theme.fonts.icon
                bold: true
            }
            verticalAlignment: Text.AlignVCenter
            color: theme.colors.highlight
        }

        ComboBox {
            id: session
            width: parent.parent.width * layout.sessionSelectorWidth
            height: parent.height * layout.comboBoxHeight
            model: sessionModel
            index: sessionModel.lastIndex

            // Styling
            color: theme.colors.primaryBackground
            textColor: theme.colors.highlight
            borderColor: "transparent"
            hoverColor: theme.colors.darkBackground
            arrowColor: theme.colors.primaryBackground
            arrowIcon: themeRoot + "Assets/angle-down.svg"

            font {
                family: theme.fonts.family
                pixelSize: theme.fonts.small
            }

            // Navigation
            Keys.onTabPressed: function() {
                root.focusNextInOrder()
            }
            Keys.onBacktabPressed: function() {
                root.focusPreviousInOrder()
            }
        }

        // Keyboard layout selector with icon
        Text {
            text: "\uF11C"
            font {
                family: theme.fonts.family
                pixelSize: theme.fonts.icon
                bold: true
            }
            verticalAlignment: Text.AlignVCenter
            color: theme.colors.highlight
            visible: layoutBox.visible
        }

        ComboBox {
            id: layoutBox
            model: keyboard.layouts
            index: keyboard.currentLayout
            width: parent.parent.width * layout.layoutSelectorWidth
            height: parent.height * layout.comboBoxHeight
            visible: keyboard.layouts.count > 1

            // Styling
            color: theme.colors.primaryBackground
            textColor: theme.colors.highlight
            borderColor: "transparent"
            hoverColor: theme.colors.darkBackground
            arrowColor: theme.colors.primaryBackground

            onValueChanged: keyboard.currentLayout = id

            Connections {
                target: keyboard
                function onCurrentLayoutChanged() {
                    layoutBox.index = keyboard.currentLayout
                }
            }

            rowDelegate: Rectangle {
                color: "transparent"
                Text {
                    anchors {
                        margins: parent.width * layout.textIconSpacing
                        top: parent.top
                        bottom: parent.bottom
                    }
                    verticalAlignment: Text.AlignVCenter
                    text: modelItem ? modelItem.modelData.shortName : ""
                    font {
                        family: theme.fonts.family
                        pixelSize: theme.fonts.small
                    }
                    color: theme.colors.highlight
                }
            }

            // Navigation
            Keys.onTabPressed: function() {
                root.focusNextInOrder()
            }
            Keys.onBacktabPressed: function() {
                root.focusPreviousInOrder()
            }
        }
    }

    // Power buttons
    Row {
        id: rightControls
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: parent.height
        spacing: parent.width * layout.standardSpacing

        ImageButton {
            id: btnReboot
            height: parent.height * layout.powerButtonSize
            width: height
            smooth: true
            antialiasing: true
            source: themeRoot + "Assets/reboot.svg"
            visible: sddm.canReboot

            onClicked: {
                console.log("Reboot requested")
                sddm.reboot()
            }

            // Navigation
            Keys.onTabPressed: function() {
                root.focusNextInOrder()
            }
            Keys.onBacktabPressed: function() {
                root.focusPreviousInOrder()
            }

            // Error handling
            onStatusChanged: {
                if (status === Image.Error) {
                    console.warn("Failed to load reboot icon")
                }
            }
        }

        ImageButton {
            id: btnShutdown
            height: parent.height * layout.powerButtonSize
            width: height
            smooth: true
            antialiasing: true
            source: themeRoot + "Assets/shutdown.svg"
            visible: sddm.canPowerOff

            onClicked: {
                console.log("Shutdown requested")
                sddm.powerOff()
            }

            // Navigation
            Keys.onTabPressed: function() {
                root.focusNextInOrder()
            }
            Keys.onBacktabPressed: function() {
                root.focusPreviousInOrder()
            }

            // Error handling
            onStatusChanged: {
                if (status === Image.Error) {
                    console.warn("Failed to load shutdown icon")
                }
            }
        }
    }

    // Component initialization
    Component.onCompleted: {
        // Set initial focus to session selector
        session.forceActiveFocus()
    }
}
