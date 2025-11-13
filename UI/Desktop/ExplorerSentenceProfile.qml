import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    property var profileId
    property string profileType: "sentence"

    ColumnLayout {
        anchors.fill: parent



        // Rectangle {
        //     Layout.fillWidth: true
        //     height: 1
        //     color: "lightgray"
        // }

        RowLayout{
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 30

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 0
                contentWidth: width  // Important: constrain content width
                contentHeight: contentColumn.implicitHeight
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.DragOverBounds
                clip: true

                ScrollBar.vertical: ScrollBar { }

                Column {
                    id: contentColumn
                    width: parent.width  // Match the Flickable width
                    spacing: 15


                    // Text {
                    //   text: "Sentence Profile"
                    //   font.pixelSize: 20
                    //   font.bold: true
                    //   bottomPadding: 25
                    // }

                    Rectangle {
                        id: textBackground
                        width: parent.width
                        color: "#eff6ff"
                        radius: 8

                        // Height based on text content - automatically adjusts
                        height: originalSentenceText.height + 40  // Add some padding


                        Text {
                            id: originalSentenceText
                            font.pointSize: 12
                            width: parent.width - 40
                            wrapMode: Text.Wrap
                            text: "Original sentence will appear here..."
                            anchors.centerIn: parent
                        }
                    }

                    Text {
                        font.bold: true
                        font.pointSize: 16
                        text: "Your Saved List"
                    }

                    Rectangle{
                        width: parent.width
                        height: 1
                        color: "lightgray"
                        id: bar
                    }





                    /* Component reusable for everything.*/
                    Rectangle {
                        width: parent.width
                        color: "#f9fafb"
                        radius: 8
                        height: Math.max(titleText.height + contentText.height + 60, 80)  // Minimum height

                        Text {
                            id: titleText
                            font.pointSize: 10
                            width: parent.width - 40
                            wrapMode: Text.Wrap
                            text: "Synonym"
                            color: "#2563eb"
                            anchors {
                                top: parent.top
                                horizontalCenter: parent.horizontalCenter
                                topMargin: 20
                            }
                        }

                        Text {
                            id: contentText
                            font.pointSize: 14
                            width: parent.width - 40
                            wrapMode: Text.Wrap
                            text: "Impossible"
                            anchors {
                                top: titleText.bottom
                                horizontalCenter: parent.horizontalCenter
                                topMargin: 10
                            }
                        }
                    }












                }
            }





        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 0
            contentWidth: width  // Important: constrain content width
            contentHeight: aiContentColumn.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.DragOverBounds
            clip: true

            ScrollBar.vertical: ScrollBar { }

            Column {
                id: aiContentColumn
                width: parent.width - 20  // Match the Flickable width
                anchors.margins: 10
                spacing: 15

                // Text {
                //     id: aiResponseText
                //     font.pointSize: 12
                //     width: parent.width
                //     wrapMode: Text.Wrap
                //     text: "AI response will appear here..."
                //     textFormat: Text.MarkdownText  // Changed from MarkdownText for better compatibility
                // }


                Column {
                    width: parent.width
                    spacing: 0

                    /* Dropdown Header */
                    Rectangle {
                        id: dropdownHeader
                        width: parent.width
                        color: "#f3f4f6"
                        radius: 8
                        height: 60

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                font.pointSize: 12
                                wrapMode: Text.Wrap
                                text: "Synonyms"
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                height: parent.height
                                width: parent.width - 30  // Reserve space for the arrow
                            }

                            Text {
                                id: arrow
                                text: ">"
                                font.pointSize: 12
                                verticalAlignment: Text.AlignVCenter
                                height: parent.height
                                rotation: dropdownContent.visible ? 90 : 0  // Rotate arrow when open
                                Behavior on rotation { NumberAnimation { duration: 200 } }
                            }
                        }

                        // Click handler
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                dropdownContent.visible = !dropdownContent.visible
                                dropdownHeader.bottomLeftRadius = dropdownContent.visible ? 0 : 8
                                dropdownHeader.bottomRightRadius = dropdownContent.visible ? 0 : 8

                            }
                        }
                    }

                    /* Dropdown Content - NO EXTRA SPACE */
                    Rectangle {
                        id: dropdownContent
                        width: parent.width
                        color: "#f9fafb"
                        radius: 8
                        height: contentContainer.height  // Exact height, no extra space!
                        visible: false

                        Behavior on height {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }

                        Item {
                            id: contentContainer
                            width: parent.width
                            height: grid.height + 20  // Only add padding if you want some

                            Grid {
                                id: grid
                                columns: 2
                                spacing: 10
                                width: parent.width - 20
                                anchors.top: parent.top
                                anchors.topMargin: 10
                                anchors.horizontalCenter: parent.horizontalCenter

                                Repeater {
                                    model: 4
                                    Rectangle {
                                        width: (parent.width - parent.spacing) / 2
                                        height: 30
                                        color: "#e5e7eb"
                                        radius: 4

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                console.log("to be saved...")
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Item " + (index + 1)
                                            font.pointSize: 10
                                        }
                                    }
                                }
                            }
                        }
                    }


                }


                /* Component reusable for everything.*/
                Rectangle {
                    width: parent.width
                    color: "#f3f4f6"
                    radius: 8
                    height: originalSentenceText.height + 40  // Add some padding

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            font.pointSize: 12
                            wrapMode: Text.Wrap
                            text: "Antonyms"
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                            height: parent.height
                            width: parent.width - 30  // Reserve space for the arrow
                        }

                        Text {
                            text: ">"
                            font.pointSize: 12
                            verticalAlignment: Text.AlignVCenter
                            height: parent.height
                        }
                    }
                }

                /* Component reusable for everything.*/
                Rectangle {
                    width: parent.width
                    color: "#f3f4f6"
                    radius: 8
                    height: originalSentenceText.height + 40  // Add some padding

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            font.pointSize: 12
                            wrapMode: Text.Wrap
                            text: "Usage Examples"
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                            height: parent.height
                            width: parent.width - 30  // Reserve space for the arrow
                        }

                        Text {
                            text: ">"
                            font.pointSize: 12
                            verticalAlignment: Text.AlignVCenter
                            height: parent.height
                        }
                    }
                }

                /* Component reusable for everything.*/
                Rectangle {
                    width: parent.width
                    color: "#f3f4f6"
                    radius: 8
                    height: originalSentenceText.height + 40  // Add some padding

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            font.pointSize: 12
                            wrapMode: Text.Wrap
                            text: "Different ways to say same thing"
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                            height: parent.height
                            width: parent.width - 30  // Reserve space for the arrow
                        }

                        Text {
                            text: ">"
                            font.pointSize: 12
                            verticalAlignment: Text.AlignVCenter
                            height: parent.height
                        }
                    }
                }


                /* Component reusable for everything.*/
                Rectangle {
                    width: parent.width
                    color: "#f3f4f6"
                    radius: 8
                    height: originalSentenceText.height + 40  // Add some padding

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            font.pointSize: 12
                            wrapMode: Text.Wrap
                            text: "Explanation"
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                            height: parent.height
                            width: parent.width - 30  // Reserve space for the arrow
                        }

                        Text {
                            text: ">"
                            font.pointSize: 12
                            verticalAlignment: Text.AlignVCenter
                            height: parent.height
                        }
                    }
                }

                Item {
                    width: 1
                    height: 10  // This creates space below the rectangle
                }





                }
            }
        }
    }


    Component.onCompleted: {
        console.log("Loaded profile with id:", profileId)
        if (profileId !== undefined && profileId !== null && profileId !== -1) {
            var sentenceData = dbManager.getSentencesProfile(profileId);
            console.log("Sentence data:", sentenceData["text"]);

            originalSentenceText.text = sentenceData.text.replace(/\*\*/g, '');
            aiResponseText.text = sentenceData.ai_response || "No AI analysis yet...";
        }
    }
}
