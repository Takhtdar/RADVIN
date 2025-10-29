// UI/Desktop/Main.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.platform

ApplicationWindow {
    id: mainWindow
    width: 800
    height: 500
    visible: true
    color: "white"
    title: "RADVIN Reader"

    property bool isClipboardEnabled: settings.getValue("clipboard_enabled", false)

    StackView {
        id: stackView
        anchors.fill: parent

        Component.onCompleted: {
            console.log("🔓 Auto-login with existing token")
            if (deviceType == "Phone") {
                stackView.push("/UI/Android/Home.qml")
            } else {
                stackView.push("/UI/Desktop/Home.qml")
                // screenLoader.source = "Queue.qml"
            }
        }
    }

    SystemTrayIcon {
        id: systemTrayIcon
        visible: true
        icon.source: isClipboardEnabled ?
                        "qrc:/icons/book-green.svg" : "qrc:/icons/book-red.svg"

        onActivated: {
            mainWindow.show()
            mainWindow.raise()
            mainWindow.requestActivate()
        }

        menu: Menu {
            MenuItem {
                id: toggleMenuItem
                text: isClipboardEnabled ? qsTr("Disable Clipboard") : qsTr("Enable Clipboard")
                onTriggered: {
                    var newValue = !isClipboardEnabled
                    settings.setValue("clipboard_enabled", newValue)
                    isClipboardEnabled = newValue
                    clipboardListener.setEnabled(newValue)
                    console.log("📎 Clipboard monitoring switched:", newValue ? "ON" : "OFF")
                }
            }
            MenuItem {
                text: qsTr("Quit")
                onTriggered: Qt.quit()
            }
        }
    }

    Connections {
        target: settings
        function onSettingChanged(key) {
            if (key === "clipboard_enabled") {
                isClipboardEnabled = settings.getValue("clipboard_enabled", false)
            }
        }
    }
}
