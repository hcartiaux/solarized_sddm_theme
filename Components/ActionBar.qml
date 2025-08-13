import QtQuick 2.15
import QtQuick.Controls 2.15
import SddmComponents 2.0

Rectangle {
    id: root

    // Theme and layout objects passed from parent
    property QtObject theme
    property QtObject layout
    property string themeRoot

    // Navigation signals for wrapping focus
    signal requestLoginFocusFirst()
    signal requestLoginFocusLast()

    // Public API for external focus management
    function focusSession() {
        session.forceActiveFocus()
    }

    function focusLast() {
        if (btnShutdown.visible) {
            btnShutdown.forceActiveFocus()
        } else if (btnReboot.visible) {
            btnReboot.forceActiveFocus()
        } else if (layoutBox.visible) {
            layoutBox.forceActiveFocus()
        } else {
            session.forceActiveFocus()
        }
    }

    function getSessionIndex() {
        return session.index
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

            // Key Navigation
            KeyNavigation.tab: layoutBox.visible ? layoutBox : (btnReboot.visible ? btnReboot : btnShutdown)
            Keys.onTabPressed: function(event) {
                if (!layoutBox.visible && !btnReboot.visible && !btnShutdown.visible) {
                    root.requestLoginFocusFirst()
                    event.accepted = true
                }
            }
            Keys.onBacktabPressed: function(event) {
                root.requestLoginFocusLast()
                event.accepted = true
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

            // Key Navigation
            KeyNavigation.tab: btnReboot.visible ? btnReboot : btnShutdown
            Keys.onTabPressed: function(event) {
                if (!btnReboot.visible && !btnShutdown.visible) {
                    root.requestLoginFocusFirst()
                    event.accepted = true
                }
            }
            KeyNavigation.backtab: session
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

            // Key Navigation
            KeyNavigation.tab: btnShutdown
            Keys.onTabPressed: function(event) {
                if (!btnShutdown.visible) {
                    root.requestLoginFocusFirst()
                    event.accepted = true
                }
            }
            KeyNavigation.backtab: layoutBox.visible ? layoutBox : session

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

            // Key Navigation
            Keys.onTabPressed: function(event) {
                root.requestLoginFocusFirst()
                event.accepted = true
            }
            KeyNavigation.backtab: btnReboot.visible ? btnReboot : (layoutBox.visible ? layoutBox : session)


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
