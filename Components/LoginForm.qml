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
    signal loginAttempt(string username, string password, int sessionIndex)
    signal requestActionBarFocus()

    // Public API for external focus management
    function focusUsername() {
        name.forceActiveFocus()
    }

    function showError(message) {
        errorMessage.text = message
        errorMessage.color = theme.colors.warning
    }

    function clearError() {
        errorMessage.text = textConstants.prompt
        errorMessage.color = theme.colors.textColor
    }

    color: "transparent"
    clip: true

    TextConstants { id: textConstants }

    Row {
        anchors {
            fill: parent
            margins: parent.width * layout.formMargins
        }
        spacing: parent.width * layout.formMargins

        // Username column
        Column {
            id: usernameColumn
            width: (parent.width - parent.spacing) * layout.columnSplit
            spacing: parent.height * layout.formColumnSpacing

            Text {
                text: textConstants.userName
                font {
                    family: theme.fonts.family
                    bold: true
                    pixelSize: theme.fonts.normal
                }
                color: theme.colors.textColor
            }

            TextBox {
                id: name
                width: parent.width
                height: parent.parent.height * layout.inputFieldHeight
                text: userModel.lastUser

                // Styling
                font {
                    family: theme.fonts.family
                    pixelSize: theme.fonts.normal
                }
                color: theme.colors.darkBackground
                borderColor: "transparent"
                textColor: theme.colors.textColor

                // Input handling
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.loginAttempt(name.text, password.text, sessionModel.lastIndex)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Tab) {
                        password.forceActiveFocus()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Backtab) {
                        root.requestActionBarFocus()
                        event.accepted = true
                    }
                }
            }

            Text {
                id: errorMessage
                text: textConstants.prompt
                font {
                    family: theme.fonts.family
                    pixelSize: theme.fonts.small
                }
                color: theme.colors.textColor
                wrapMode: Text.WordWrap
                width: parent.width

                // Smooth color transitions
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }
        }

        // Password column
        Column {
            id: passwordColumn
            width: (parent.width - parent.spacing) * layout.columnSplit
            spacing: parent.height * layout.formColumnSpacing

            Text {
                text: textConstants.password
                font {
                    family: theme.fonts.family
                    bold: true
                    pixelSize: theme.fonts.normal
                }
                color: theme.colors.textColor
            }

            PasswordBox {
                id: password
                width: parent.width
                height: parent.parent.height * layout.inputFieldHeight

                // Styling
                font {
                    family: theme.fonts.family
                    pixelSize: theme.fonts.normal
                }
                tooltipBG: theme.colors.darkBackground
                tooltipFG: theme.colors.warning
                image: themeRoot + "Assets/warning_red.png"
                color: theme.colors.darkBackground
                borderColor: "transparent"
                textColor: theme.colors.textColor

                // Input handling
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.loginAttempt(name.text, password.text, sessionModel.lastIndex)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Tab) {
                        loginButton.forceActiveFocus()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Backtab) {
                        name.forceActiveFocus()
                        event.accepted = true
                    }
                }

                onTextChanged: root.clearError()

            }

            Button {
                id: loginButton
                text: textConstants.login
                width: parent.width * layout.loginButtonWidth
                height: parent.parent.height * layout.loginButtonHeight
                anchors.right: parent.right

                // Styling
                color: theme.colors.accent
                disabledColor: theme.colors.disabled
                activeColor: theme.colors.accent
                pressedColor: theme.colors.accentHover
                textColor: theme.colors.lightBackground

                font {
                    family: theme.fonts.family
                    pixelSize: theme.fonts.normal
                }

                // Interaction
                onClicked: {
                    console.log("Login button clicked")
                    root.loginAttempt(name.text, password.text, sessionModel.lastIndex)
                }

                // Navigation
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.loginAttempt(name.text, password.text, sessionModel.lastIndex)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Tab) {
                        root.focusNext()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Backtab) {
                        password.forceActiveFocus()
                        event.accepted = true
                    }
                }

                // Visual feedback
                enabled: name.text.length > 0 && password.text.length > 0

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }
    }

    // Component initialization
    Component.onCompleted: {
        // Set initial focus to username if it's empty, otherwise password
        if (name.text === "") {
            name.forceActiveFocus()
        } else {
            password.forceActiveFocus()
        }
    }
}
