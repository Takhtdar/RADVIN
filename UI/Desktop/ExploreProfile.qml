import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: exploreProfile
    property int profileId
    property string profileType: "sentence"
    property var previousState: null
    property var parentExplorer: null


    ColumnLayout {
        anchors.fill: parent

        RowLayout{
            id: exploreProfileNavbar
            Layout.fillWidth: true
            height: exploreProfileNavbar.visible ? 50 : 0
            spacing: 8

            ButtonItem {
                id: backButton
                backgroundColor: "#e5e7eb"
                hoverColor: "#d2d3d6"
                textColor: "#000"
                text: "← Back"
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 160

                onClicked: {
                    explorerNavbar.visible = true
                    exploreProfileNavbar.visible = false

                    if (profileType === "word") {
                        setCurrentView(settings.getValue("explorerView", "Grid"))
                    } else {
                        setCurrentView(settings.getValue("explorerView", "List"))
                    }
                }
            }

            ButtonItem {
                // to be fixed
                id: reGenerateButton
                backgroundColor: "#e5e7eb"
                hoverColor: "#d2d3d6"
                textColor: "#000"
                Layout.preferredWidth: 160
                Layout.alignment: Qt.AlignVCenter
                text: explorer.processingStates[loader.item.profileId] ? "Processing..." : "Generate ♻️️"
                enabled: !explorer.processingStates[loader.item.profileId]

                onClicked: {
                    explorer.processingStates[profileId] = true
                    reGenerateButton.text = "Processing..."
                    reGenerateButton.enabled = false
                    console.log("Regenerating", profileType, "with ID:", profileId);
                    networkManager.regenerateContent(profileId, profileType);
                }
            }

            ButtonItem {
                id: deleteButton
                backgroundColor: "#de525c"
                hoverColor: "#b53841"
                text: "Delete 🗑️"
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 160
                onClicked: {
                    explorerNavbar.visible = true
                    exploreProfileNavbar.visible = false

                    if (profileType === "word") {
                        dbManager.deleteWord(loader.item.profileId);
                        setCurrentView(settings.getValue("explorerView", "Grid"))
                    } else {
                        dbManager.deleteSentence(loader.item.profileId);
                        setCurrentView(settings.getValue("explorerView", "List"))
                    }
                }
            }

            // ButtonItem {
            //     id: editAIResponseButton
            //     text: "Edit JSON️"
            //     backgroundColor: "#e5e7eb"
            //     hoverColor: "#d2d3d6"
            //     textColor: "#000"
            //     Layout.alignment: Qt.AlignVCenter
            //     Layout.preferredWidth: 160
            //     onClicked: {
            //         /*
            //         explorerNavbar.visible = true
            //         exploreProfileNavbar.visible = false
            //         */

            //         if (profileType === "word") {
            //             ai_response = dbManager.getWordProfile(profileId).ai_response;
            //         } else {
            //             // later get the ai response for sentences and show it.
            //         }
            //     }
            // }
        }

        Item { height: 10 }

        RowLayout{
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 30


            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 0
                contentWidth: width
                contentHeight: contentColumn.implicitHeight
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.DragOverBounds
                clip: true

                ScrollBar.vertical: ScrollBar { }

                Column {
                    id: contentColumn
                    width: parent.width
                    spacing: 15

                    Rectangle {
                        id: textBackground
                        width: parent.width
                        color: "#eff6ff"
                        radius: 8

                        height: originalSentenceText.height + 40  // Add some padding

                        Text {
                            id: originalSentenceText
                            font.pointSize: 12
                            width: parent.width - 40
                            wrapMode: Text.Wrap
                            text: "Original sentence will appear here..."
                            anchors.centerIn: parent
                            textFormat: Text.MarkdownText
                        }
                    }

                    RowLayout {
                        spacing: 10
                        width: parent.width

                        Text {
                            font.bold: true
                            font.pointSize: 16
                            text: "Your Saved List"
                            verticalAlignment: Text.AlignVCenter
                        }

                        Item {
                            Layout.fillWidth: true
                            height: 1
                        }

                        Button {
                            text: "➕"
                            width: 35
                            height: 35
                            // Remove button styling to make it appear transparent
                            background: Rectangle {
                                color: "transparent"
                            }

                            onClicked: {
                                console.log("add a note widget or something! and save it to database as user notes!")
                            }

                        }
                    }



                    Rectangle{
                        width: parent.width
                        height: 1
                        color: "lightgray"
                        id: bar
                    }

                    // Rectangle {
                    //     width: parent.width
                    //     color: "#f9fafb"
                    //     radius: 8
                    //     height: Math.max(titleText.height + contentText.height + 60, 80)  // Minimum height

                    //     Text {
                    //         id: titleText
                    //         font.pointSize: 10
                    //         width: parent.width - 40
                    //         wrapMode: Text.Wrap
                    //         text: "Synonym"
                    //         color: "#2563eb"
                    //         anchors {
                    //             top: parent.top
                    //             horizontalCenter: parent.horizontalCenter
                    //             topMargin: 20
                    //         }
                    //     }

                    //     Text {
                    //         id: contentText
                    //         font.pointSize: 14
                    //         width: parent.width - 40
                    //         wrapMode: Text.Wrap
                    //         text: "Impossible"
                    //         anchors {
                    //             top: titleText.bottom
                    //             horizontalCenter: parent.horizontalCenter
                    //             topMargin: 10
                    //         }
                    //     }
                    // }


                    // add user notes here.
                }
            }


            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 0
                contentWidth: width  // Important: constrain content width
                contentHeight: Math.max(aiContentColumn.implicitHeight, height) // Ensure content height is at least Flickable height
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.DragOverBounds
                clip: true

                ScrollBar.vertical: ScrollBar { }

                ColumnLayout {
                    id: aiContentColumn
                    width: parent.width - 20
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    spacing: 15

                    DynamicJsonViewer {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        jsonData: {
                            var response = ""
                            if (profileType === "word"){
                                response = dbManager.getWordProfile(profileId).ai_response;
                            }
                            else {
                                response = dbManager.getSentencesProfile(profileId).ai_response;
                            }

                            // Parse the JSON string to an object before returning
                            if (typeof response === "string" && response.trim() !== "") {
                                try {
                                    return JSON.parse(response);
                                } catch (e) {
                                    console.log("JSON parsing error:", e);
                                    console.log("Response was:", response);
                                    return {}; // Return empty object if parsing fails
                                }
                            }
                            return response;
                        }
                    }

                    Item { Layout.preferredHeight: 50 } // Bottom padding
                }
            }
        }
    }

    Component.onCompleted: {
        // move this later to Explorer.qml
        explorerNavbar.visible = false

        console.log("Loaded profile with id:", profileId)
            let data = ""
            if (profileType === "word") {
                data = dbManager.getWordProfile(profileId).context
                if(!data){
                data = dbManager.getWordProfile(profileId).word
                }
            } else {
                data = dbManager.getSentencesProfile(profileId).text
            }
            originalSentenceText.text = data

        networkManager.contentRegenerationStarted.connect(function(id, type) {
            console.log("Started regenerating", type, "ID:", id);

        });

        networkManager.contentRegenerated.connect(function(id, type) {
            console.log("Finished regenerating", type, "ID:", id);

        });
    }
}
