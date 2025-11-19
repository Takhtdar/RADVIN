import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    property var profileId
    property string profileType: "sentence"
    property var previousState: null
    property var processingStates: ({})

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
                    // Reset the processing state for the current profile before navigating back
                    if (loader.item && loader.item.profileId !== undefined && loader.item.profileId !== null && loader.item.profileId !== -1) {
                        var currentProfileId = loader.item.profileId;
                        if (explorer.processingStates[currentProfileId]) {
                            explorer.processingStates[currentProfileId] = false;
                            reGenerateButton.isProcessing = false; // Reset the button state
                        }
                    }

                    var profileType = loader.item.profileType || "sentence";
                    if (profileType === "word") {
                        setCurrentView(settings.getValue("explorerView", "Grid"))
                    } else {
                        setCurrentView(settings.getValue("explorerView", "List"))
                    }
                }
            }

            ButtonItem {
                id: reGenerateButton
                backgroundColor: "#e5e7eb"
                hoverColor: "#d2d3d6"
                textColor: "#000"
                Layout.preferredWidth: 160
                text: reGenerateButton.isProcessing ? "Processing..." : "Generate ♻️️"
                Layout.alignment: Qt.AlignVCenter
                enabled: !reGenerateButton.isProcessing

                property bool isProcessing: false

                onClicked: {
                    if (loader.item &&
                            loader.item.profileId !== undefined &&
                            loader.item.profileId !== null &&
                            loader.item.profileId !== -1) {

                        var profileType = loader.item.profileType || "sentence";
                        var profileId = loader.item.profileId;

                        console.log("Regenerating", profileType, "with ID:", profileId);

                        // Set processing state for this specific ID
                        explorer.processingStates[profileId] = true;
                        reGenerateButton.isProcessing = true;

                        // Call the network manager to regenerate content
                        networkManager.regenerateContent(profileId, profileType);
                    }
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
                    if (loader.item &&
                            loader.item.profileId !== undefined &&
                            loader.item.profileId !== null &&
                            loader.item.profileId !== -1) {

                        var profileType = loader.item.profileType || "sentence";
                        console.log("Deleting", profileType, "with ID:", loader.item.profileId);

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
        }

        Item {
            height: 10
        }

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

                    DropDownItem{
                        title: "Synonyms"
                        model:  [
                            { id: 101, word: "unhappy" },
                            { id: 102, word: "miserable" },
                            { id: 103, word: "down" }
                        ]
                    }

                    DropDownItem{
                        title: "Antonyms"
                        model: [{id: 601, word: "different"}]
                    }

                    DropDownItem{
                        title: "Usage Examples"
                        columns: 1
                        model: [{id: 401, word: "aaaaaaa"}]
                    }

                    DropDownItem{
                        title: "Different Ways to say same thing"
                        columns: 1
                        model: [{id: 301, word: "different"}]
                    }

                    DropDownItem{
                        title: "Explanation"
                        columns: 1
                        model: [{
                                id: 201,
                                word: profileType === "word"
                                      ? dbManager.getWordProfile(profileId).ai_response
                                      : dbManager.getSentencesProfile(profileId).ai_response
                            }]
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

        // move this later to Explorer.qml
        explorerNavbar.visible = false

        console.log("Loaded profile with id:", profileId)
        if (profileId !== undefined && profileId !== null && profileId !== -1) {
            if (profileType === "word") {
                var data = dbManager.getWordProfile(profileId)
                originalSentenceText.text = data.word
            } else {
                var data = dbManager.getSentencesProfile(profileId)
                originalSentenceText.text = data.text
            }
        }

        networkManager.contentRegenerationStarted.connect(function(id, type) {
            console.log("Started regenerating", type, "ID:", id);
            explorer.processingStates[id] = true;
            if (loader.item && loader.item.profileId === id) {
                reGenerateButton.isProcessing = true;
            }
        });

        networkManager.contentRegenerated.connect(function(id, type) {
            console.log("Finished regenerating", type, "ID:", id);
            explorer.processingStates[id] = false;

            if (loader.item && loader.item.profileId === id) {
                if (type === "word") {
                    explorer.openProfile(id, "word");
                } else {
                    explorer.openProfile(id, "sentence");
                }
                reGenerateButton.isProcessing = false;
            }
            if (loader.item && loader.item.profileId === id) {
                reGenerateButton.isProcessing = false;
            }
        });

    }
}
