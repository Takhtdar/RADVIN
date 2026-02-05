import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Messages area
        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: messageList
                anchors.fill: parent

                model: ListModel {
                    ListElement { text: "Hello! How can I help you?"; isUser: false }
                    ListElement { text: "Can you design a chat window?"; isUser: true }
                    ListElement { text: "Yes, here's a simple design!"; isUser: false }
                }

                delegate: Rectangle {
                    width: messageList.width
                    height: messageBubble.height + 10
                    color: "transparent"

                    Rectangle {
                        id: messageBubble
                        width: Math.min(messageText.contentWidth + 20, parent.width * 0.8)
                        height: messageText.contentHeight + 15
                        radius: 10
                        color: isUser ? "#007AFF" : "#E5E5EA"
                        anchors {
                            left: isUser ? undefined : parent.left
                            right: isUser ? parent.right : undefined
                        }

                        Text {
                            id: messageText
                            text: model.text
                            wrapMode: Text.WordWrap
                            width: parent.width - 20
                            anchors.centerIn: parent
                            color: isUser ? "white" : "black"
                            font.pixelSize: 16
                        }
                    }
                }
            }
        }

        // Input area
        RowLayout {
            Layout.fillWidth: true

            TextField {
                id: messageInput
                Layout.fillWidth: true
                placeholderText: "Type your message..."
                onAccepted: sendMessage()
            }
        }
    }

    function sendMessage() {
        if (messageInput.text.trim() === "") return

        messageList.model.append({
            text: messageInput.text,
            isUser: true
        })

        messageInput.text = ""

        // Scroll to bottom
        Qt.callLater(function() {
            messageList.positionViewAtEnd()
        })

        // Simulate AI response after 1 second
        timer.start()
    }

    Timer {
        id: timer
        interval: 1000
        onTriggered: {
            messageList.model.append({
                text: "This is an AI response to: " + messageList.model.get(messageList.model.count-2).text,
                isUser: false
            })
            messageList.positionViewAtEnd()
        }
    }
}
