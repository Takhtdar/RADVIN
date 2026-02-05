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
        //Layout.fillWidth: true
        //Layout.fillHeight: true

        // buttons at top
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

        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                // text to study
                Rectangle {
                    Layout.fillWidth: true
                    z: 100
                    id: textBackground
                    width: parent.width
                    color: "#eff6ff"
                    radius: 8
                    implicitHeight: originalSentenceText.implicitHeight + 40

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

                Item { height: 10 }

                Conversation {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Item { height: 10 }
            }

            Item { width: 10 }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true

                WordDetails {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }


                // What can I add here to visually seperate two box from each other?
                Item { height: 20 } // other than space

                Panel {
                    Layout.fillWidth: true
                    // Layout.fillHeight: true
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
