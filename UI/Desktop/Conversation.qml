import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40 // Fixed height for header
            color: "#eff2f5" // Light grey/blue background from image
            topRightRadius: 8
            topLeftRadius: 8


            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15

                // Header Text
                Text {
                    text: " 🎓️ Interactive Studying Mode"
                    font.pixelSize: 16
                    font.bold: true
                    color: "black"
                    Layout.alignment: Qt.AlignVCenter // Centers text vertically
                }

                // Spacer to push everything else to the left
                Item { Layout.fillWidth: true; }

            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            border.color: scrollView.activeFocus ? "#2196F3" : "#EBEEF3"
            border.width: 1



            // Messages area
            ScrollView {
                id: scrollView
                anchors.fill: parent
                anchors.margins: 1 // Keep content inside the border
                clip: true // Prevents text from bleeding over rounded corners


                ListView {
                    id: messageList
                    anchors.fill: parent

                    header: Item { height: 15 }

                    model: ListModel {
                        ListElement { text: "Hello! How can I help you?"; isUser: false }
                        ListElement { text: "Can you design a chat window?"; isUser: true }
                        ListElement { text: "Yes, here's a simple design!"; isUser: false }
                    }

                    delegate: Rectangle {
                        width: messageList.width
                        height: messageBubble.height + 30
                        color: "transparent"

                        Rectangle {
                            id: messageBubble
                            width: Math.min(messageText.contentWidth + 20, parent.width * 0.8)
                            height: messageText.contentHeight + 15
                            radius: 10
                            color: isUser ? "#007AFF" : "#E5E5EA"


                            // This creates the actual "padding" outside the bubble
                                    anchors.topMargin: 15    // Space above bubble
                                    anchors.bottomMargin: 15 // Space below bubble

                            anchors {
                                left: isUser ? undefined : parent.left
                                right: isUser ? parent.right : undefined
                            }

                            anchors.margins: 10



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
