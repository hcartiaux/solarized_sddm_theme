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

Rectangle {
    id: container
    readonly property color base0: "#839496"
    readonly property color base3: "#fdf6e3"
    readonly property color base02: "#073642"
    readonly property color base03: "#002b36"
    readonly property color blue: "#268bd2"
    readonly property color cyan: "#2aa198"
    readonly property color red: "#dc322f"
    readonly property color yellow: "#b58900"

    LayoutMirroring.enabled: Qt.locale().textDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    property string themeRoot: Qt.resolvedUrl(".")
    property string fontFamily: config.displayFont || textFont.name

    // Font sizing system
    property real scaleFactor: Math.min(width / 1024, height / 768)
    readonly property int baseFontSize:   12
    readonly property int smallFontSize:  Math.max(10, baseFontSize * scaleFactor * 0.8)
    readonly property int normalFontSize: Math.max(12, baseFontSize * scaleFactor)
    readonly property int largeFontSize:  Math.max(16, baseFontSize * scaleFactor * 1.2)
    readonly property int clockFontSize:  Math.max(32, baseFontSize * scaleFactor * 5)
    readonly property int dateFontSize:   Math.max(16, baseFontSize * scaleFactor * 2)
    readonly property int iconFontSize:   Math.max(12, baseFontSize * scaleFactor * 1)

    TextConstants { id: textConstants }

    FontLoader {
        id: textFont
        source: config.displayFont ? (config.displayFont.includes('/') ? config.displayFont : themeRoot + config.displayFont + ".ttf") : themeRoot + "DejaVuSans.ttf"
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorMessage.color = red
            errorMessage.text = textConstants.loginFailed
        }
    }

    // Background for all screens
    Repeater {
        model: screenModel
        Background {
            x: geometry.x; y: geometry.y
            width: geometry.width; height: geometry.height
            source: {
                if (config.background && Qt.resolvedUrl(config.background).toString() !== "")
                    return config.background
                return themeRoot + "background.png"
            }
            fillMode: Image.PreserveAspectCrop
            onStatusChanged: if (status === Image.Error && source !== themeRoot + "background.png")
                source = themeRoot + "background.png"
        }
    }

    // Top action bar with session and layout selectors + power buttons
    Rectangle {
        id: actionBar
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: parent.width * 0.01 }
        height: parent.height * 0.05
        color: "transparent"

        Row {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            height: parent.height
            spacing: parent.width * 0.01

            // Session selector
            Text {
                text: "\uF108"
                font { family: fontFamily; pixelSize: iconFontSize; bold: true }
                verticalAlignment: Text.AlignVCenter
                color: yellow
            }
            ComboBox {
                id: session
                width: parent.parent.width * 0.15
                height: parent.height * 0.6
                model: sessionModel; index: sessionModel.lastIndex
                color: base03; textColor: yellow; borderColor: "transparent"
                hoverColor: base02; arrowColor: base03
                arrowIcon: themeRoot + "angle-down.svg"
                font { family: fontFamily; pixelSize: smallFontSize }
                KeyNavigation.backtab: btnShutdown; KeyNavigation.tab: layoutBox
            }

            // Keyboard layout selector
            Text {
                text: "\uF11C"
                font { family: fontFamily; pixelSize: iconFontSize; bold: true }
                verticalAlignment: Text.AlignVCenter
                color: yellow
                visible: keyboard.layouts.count > 1 && (keyboard.layouts.count === 0 && keyboard.layouts.get(0).shortName !== "zz")
            }
            ComboBox {
                id: layoutBox
                model: keyboard.layouts; index: keyboard.currentLayout
                width: parent.parent.width * 0.035
                height: parent.height * 0.6
                visible: keyboard.layouts.count > 1 && (keyboard.layouts.count === 0 || keyboard.layouts.get(0).shortName !== "zz")
                color: base03; textColor: yellow; borderColor: "transparent"
                hoverColor: base02; arrowColor: base03
                onValueChanged: keyboard.currentLayout = id
                Connections {
                    target: keyboard
                    function onCurrentLayoutChanged() { layoutBox.index = keyboard.currentLayout }
                }
                rowDelegate: Rectangle {
                    color: "transparent"
                    Text {
                        anchors { margins: parent.width * 0.08; top: parent.top; bottom: parent.bottom }
                        verticalAlignment: Text.AlignVCenter
                        text: modelItem ? modelItem.modelData.shortName : ""
                        font { family: fontFamily; pixelSize: smallFontSize }
                        color: yellow
                    }
                }
                KeyNavigation.backtab: session; KeyNavigation.tab: name
            }
        }

        // Power buttons
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            height: parent.height
            spacing: parent.width * 0.01

            ImageButton {
                id: btnReboot
                height: parent.height * 0.3
                width: height
                smooth: true
                antialiasing: true
                source: themeRoot + "reboot.svg"
                visible: sddm.canReboot
                onClicked: sddm.reboot()
                KeyNavigation.backtab: loginButton; KeyNavigation.tab: btnShutdown
            }

            ImageButton {
                id: btnShutdown
                height: parent.height * 0.3
                smooth: true
                antialiasing: true
                width: height
                source: themeRoot + "shutdown.svg"
                visible: sddm.canPowerOff
                onClicked: sddm.powerOff()
                KeyNavigation.backtab: btnReboot; KeyNavigation.tab: session
            }
        }
    }

    // Main content area
    Item {
        anchors { fill: parent; topMargin: actionBar.height }

        // Right-side container for clock and login form
        Item {
            id: rightContainer
            width: parent.width * 0.4
            height: parent.height * 0.6
            anchors {
                right: parent.right
                bottom: parent.bottom
            }

            // Clock
            Clock {
                id: sddmClock
                width: parent.width
                height: parent.height * 0.4
                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                }
                timeFont {
                    family: fontFamily
                    pixelSize: clockFontSize
                    bold: true
                }
                dateFont {
                    family: fontFamily
                    pixelSize: dateFontSize
                }
                color: base0

            }


            // Login form - positioned below the clock
            Rectangle {
                width: parent.width
                height: parent.height * 0.5
                anchors {
                    top: sddmClock.bottom
                    topMargin: parent.height * 0.05
                    horizontalCenter: parent.horizontalCenter
                }
                color: "transparent"
                clip: true

                Row {
                    anchors { fill: parent; margins: parent.width * 0.05 }
                    spacing: parent.width * 0.05

                    // Username column
                    Column {
                        width: (parent.width - parent.spacing) * 0.48
                        spacing: parent.height * 0.08

                        Text {
                            text: textConstants.userName
                            font {
                                family: fontFamily
                                bold: true
                                pixelSize: normalFontSize
                            }
                            color: base0
                        }

                        TextBox {
                            id: name
                            width: parent.width
                            height: parent.parent.height * 0.15
                            text: userModel.lastUser
                            font { family: fontFamily; pixelSize: normalFontSize }
                            color: base02
                            borderColor: "transparent"
                            textColor: base0
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    sddm.login(name.text, password.text, session.index)
                                    event.accepted = true
                                }
                            }
                            KeyNavigation.backtab: layoutBox; KeyNavigation.tab: password
                        }

                        Text {
                            id: errorMessage
                            text: textConstants.prompt
                            font {
                                family: fontFamily
                                pixelSize: smallFontSize
                            }
                            color: base0
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }

                    // Password column
                    Column {
                        width: (parent.width - parent.spacing) * 0.48
                        spacing: parent.height * 0.08

                        Text {
                            text: textConstants.password
                            font {
                                family: fontFamily
                                bold: true
                                pixelSize: normalFontSize
                            }
                            color: base0
                        }

                        PasswordBox {
                            id: password
                            width: parent.width
                            height: parent.parent.height * 0.15
                            font { family: fontFamily; pixelSize: normalFontSize }
                            tooltipBG: base02; tooltipFG: red
                            image: themeRoot + "warning_red.png"
                            color: base02
                            borderColor: "transparent"
                            textColor: base0
                            Keys.onPressed: function(event) {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    sddm.login(name.text, password.text, session.index)
                                    event.accepted = true
                                }
                            }
                            KeyNavigation.backtab: name; KeyNavigation.tab: loginButton
                        }

                        Button {
                            id: loginButton
                            text: textConstants.login
                            width: parent.width * 0.7
                            height: parent.parent.height * 0.16
                            anchors.right: parent.right
                            color: blue; disabledColor: red
                            activeColor: blue; pressedColor: cyan
                            textColor: base3
                            font {
                                family: fontFamily
                                pixelSize: normalFontSize
                            }
                            onClicked: sddm.login(name.text, password.text, session.index)
                            KeyNavigation.backtab: password; KeyNavigation.tab: btnReboot
                        }
                    }
                }
            }
        }
    }
}
