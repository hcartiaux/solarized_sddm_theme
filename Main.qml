/***************************************************************************
* Copyright (c) 2025 Hyacinthe Cartiaux <hyacinthe@cartiaux.net>
* Copyright (c) 2015 Víctor Granda García <victorgrandagarcia@gmail.com>
* Copyright (c) 2015 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
* Copyright (c) 2013 Abdurrahman AVCI <abdurrahmanavci@gmail.com>
*
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify, merge,
* publish, distribute, sublicense, and/or sell copies of the Software,
* and to permit persons to whom the Software is furnished to do so,
* subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included
* in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
* OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
* OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
* ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
* OR OTHER DEALINGS IN THE SOFTWARE.
*
***************************************************************************/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQml 2.15
import SddmComponents 2.0
import "Components"

Rectangle {
    id: container

    // Theme configuration object
    readonly property QtObject theme: QtObject {
        readonly property QtObject colors: QtObject {
            readonly property color textColor:         "#839496"   // Primary text color
            readonly property color lightBackground:   "#fdf6e3"   // Light backgrounds and button text
            readonly property color darkBackground:    "#073642"   // Input fields and hover states
            readonly property color primaryBackground: "#002b36"   // Main UI elements background
            readonly property color accent:            "#268bd2"   // Primary action color (blue)
            readonly property color accentHover:       "#2aa198"   // Accent hover state (cyan)
            readonly property color warning:           "#dc322f"   // Error states and warnings
            readonly property color highlight:         "#b58900"   // Icons and highlights (yellow)
            readonly property color disabled:          "#586e75"   // Disabled state (base01 - muted)
        }

        readonly property QtObject fonts: QtObject {
            property string family: config.displayFont
            property int small:  Math.max(10, baseFontSize * scaleFactor * 0.8)
            property int normal: Math.max(12, baseFontSize * scaleFactor)
            property int large:  Math.max(16, baseFontSize * scaleFactor * 1.2)
            property int clock:  Math.max(32, baseFontSize * scaleFactor * 5)
            property int date:   Math.max(16, baseFontSize * scaleFactor * 2)
            property int icon:   Math.max(12, baseFontSize * scaleFactor * 1)
        }
    }

    // Layout configuration object
    readonly property QtObject layout: QtObject {
        readonly property real actionBarHeight: 0.05        // 5% of screen height
        readonly property real rightPanelWidth: 0.4         // 40% of screen width
        readonly property real rightPanelHeight: 0.6        // 60% of screen height
        readonly property real clockHeight: 0.4             // 40% of right panel
        readonly property real loginFormHeight: 0.5         // 50% of right panel
        readonly property real standardSpacing: 0.01        // Standard spacing unit
        readonly property real componentMargin: 0.01        // Standard margin
        readonly property real sessionSelectorWidth: 0.15   // Session dropdown width
        readonly property real layoutSelectorWidth: 0.035   // Layout dropdown width
        readonly property real powerButtonSize: 0.3         // Power button size relative to bar

        // ActionBar specific layouts
        readonly property real comboBoxHeight: 0.6          // ComboBox height relative to bar

        // LoginForm specific layouts
        readonly property real formColumnSpacing: 0.08      // Vertical spacing in form columns
        readonly property real formMargins: 0.05            // Form content margins
        readonly property real inputFieldHeight: 0.15       // Input field height relative to form
        readonly property real loginButtonHeight: 0.16      // Login button height relative to form
        readonly property real loginButtonWidth: 0.7        // Login button width relative to column
        readonly property real columnSplit: 0.48            // Each column takes 48% (with spacing)
        readonly property real clockSpacingMultiplier: 5    // Clock spacing = standardSpacing * 5
        readonly property real textIconSpacing: 0.08        // Text spacing in combo delegates
    }

    LayoutMirroring.enabled: Qt.locale().textDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property string themeRoot: Qt.resolvedUrl(".")
    property string backgroundsPath: Qt.resolvedUrl("Backgrounds/")

    // Font sizing system
    property real scaleFactor: Math.min(width / 1024, height / 768)
    readonly property int baseFontSize: 12

    // Navigation management - simplified focus handling
    signal loginAttempt(string username, string password, int sessionIndex)

    TextConstants { id: textConstants }

    // Global error handling for login
    Connections {
        target: sddm
        function onLoginFailed() {
            loginForm.showError(textConstants.loginFailed)
        }
    }

    // Background with error handling
    Repeater {
        model: screenModel
        Background {
            x: geometry.x; y: geometry.y
            width: geometry.width; height: geometry.height
            source: {
                if (config.background && Qt.resolvedUrl(config.background).toString() !== "")
                    return container.backgroundsPath + config.background
                return container.backgroundsPath + "background.png"
            }
            fillMode: Image.PreserveAspectCrop
            onStatusChanged: {
                if (status === Image.Error) {
                    console.warn("Failed to load background image:", source)
                    if (source !== container.backgroundsPath + "background.png") {
                        source = container.backgroundsPath + "background.png"
                    }
                }
            }
        }
    }

    // Top action bar
    ActionBar {
        id: actionBar
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: parent.width * layout.componentMargin
        }
        height: parent.height * layout.actionBarHeight

        theme: container.theme
        layout: container.layout
        themeRoot: container.themeRoot

        onRequestLoginFocus: loginForm.focusNonInitial()
        // Component initialization
        Component.onCompleted: {
            // Set initial focus based on username presence
            loginForm.focusInitial()
        }

    }

    // Main content area
    Item {
        anchors {
            fill: parent
            topMargin: actionBar.height + (parent.height * layout.componentMargin)
        }

        // Right-side container for clock and login form
        Item {
            id: rightContainer
            width: parent.width * layout.rightPanelWidth
            height: parent.height * layout.rightPanelHeight
            anchors {
                right: parent.right
                bottom: parent.bottom
            }

            // Clock with error handling
            Clock {
                id: sddmClock
                width: parent.width
                height: parent.height * layout.clockHeight
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                }
                timeFont {
                    family: theme.fonts.family
                    pixelSize: theme.fonts.clock
                    bold: true
                }
                dateFont {
                    family: theme.fonts.family
                    pixelSize: theme.fonts.date
                }
                color: theme.colors.textColor
            }

            // Login form
            LoginForm {
                id: loginForm
                width: parent.width
                height: parent.height * layout.loginFormHeight
                anchors {
                    top: sddmClock.bottom
                    topMargin: parent.height * layout.standardSpacing * layout.clockSpacingMultiplier
                    horizontalCenter: parent.horizontalCenter
                }

                theme: container.theme
                layout: container.layout
                themeRoot: container.themeRoot

                onFocusNext: actionBar.focusSession()
                onLoginAttempt: function(username, password, sessionIndex) {
                    container.loginAttempt(username, password, sessionIndex)
                    sddm.login(username, password, actionBar.getSessionIndex())
                }
                onRequestActionBarFocus: actionBar.focusSession()
            }
        }
    }

    focus: true
}
