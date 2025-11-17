import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    width: mainScreen.width
    height: mainScreen.height
    z: 3
    id: explorer
    property var previousState: null
    property var processingStates: ({})


    Component.onCompleted: {
        const savedView = settings.getValue("explorerView", "List") // default = "List"
        setCurrentView(savedView)
    }

    function openSentenceProfile(itemId) {
        loader.setSource("ExploreProfile.qml", {
            profileId: itemId,
            profileType: "sentence"
        })
        backButton.visible = true
        reGenerateButton.visible = true
        deleteButton.visible = true
        viewOptions.enabled = false
    }


    function openWordProfile(itemId) {
        loader.setSource("ExploreProfile.qml", {
            profileId: itemId,
            profileType: "word"
        })
        backButton.visible = true
        reGenerateButton.visible = true
        deleteButton.visible = true
        viewOptions.enabled = false
    }

    function setCurrentView(viewName) {
        let fileMap = {
            "List": "ExploreSentences.qml",
            "Grid": "ExploreWords.qml",
        }

        if (fileMap[viewName]) {
            loader.source = fileMap[viewName]
        } else {
            loader.source = "" // or a default
        }
    }

    RowLayout {
        id: explorerNavbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 50
        z: 10
        spacing: 8


        Button {
            id: backButton
            text: "← Back"
            visible: false // only shown in profile view
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 100

            onClicked: {
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

                backButton.visible = false
                reGenerateButton.visible = false
                deleteButton.visible = false
                viewOptions.enabled = true
                // restore filter options
                // if (explorer.previousState) {
                //     viewOptions.currentIndex = explorer.previousState.view
                //     filterOptions.currentIndex = explorer.previousState.filter
                // }
            }
        }

        Button {
            id: reGenerateButton
            text: reGenerateButton.isProcessing ? "Processing..." : "Generate ♻️️"
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 100
            visible: false
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

        Component.onCompleted: {
            networkManager.contentRegenerationStarted.connect(function(id, type) {
                console.log("Started regenerating", type, "ID:", id);
                explorer.processingStates[id] = true;
                // Update the button if it's for this ID
                if (loader.item && loader.item.profileId === id) {
                    reGenerateButton.isProcessing = true;
                }
            });

            networkManager.contentRegenerated.connect(function(id, type) {
                console.log("Finished regenerating", type, "ID:", id);

                // Clear processing state for this specific ID
                explorer.processingStates[id] = false;

                // Only reload the profile if the user is still on the same profile page
                if (loader.item && loader.item.profileId === id) {
                    // Reload the profile after regeneration is complete
                    if (type === "word") {
                        explorer.openWordProfile(id);
                    } else {
                        explorer.openSentenceProfile(id);
                    }

                    // Update the button if it's for this ID
                    reGenerateButton.isProcessing = false;
                }

                // Also update the button state if it's for this ID (in case user navigated away)
                if (loader.item && loader.item.profileId === id) {
                    reGenerateButton.isProcessing = false;
                }
            });
        }


        Button {
            id: deleteButton
            visible: false
            text: "Delete 🗑️"
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 100
            onClicked: {
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

                    // Go back to list view after deletion

                    backButton.visible = false
                    reGenerateButton.visible = false
                    deleteButton.visible = false
                    viewOptions.enabled = true
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            width: 0
        }

        ComboBox {
            id: filterOptions
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 160
            textRole: "display"
            enabled: false
            model: [
                { display: "select a filter" },
                { display: "Nouns" },
                { display: "Verbs" },
                { display: "Idioms" },
            ]

            onCurrentIndexChanged: {
                if (currentIndex >= 0) {
                    // const selected = model[currentIndex].display
                    // settings.setValue("explorerView", selected)
                    // setCurrentView(selected)
                }
            }
        }

        ComboBox {
            id: viewOptions
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 160
            Layout.rightMargin: 10
            textRole: "display"

            model: [
                { display: "List" },
                { display: "Grid" }
            ]

            onCurrentIndexChanged: {
                if (currentIndex >= 0) {
                    const selected = model[currentIndex].display
                    settings.setValue("explorerView", selected)
                    setCurrentView(selected)
                }
            }
        }
    }

    Loader {
        id: loader
        Layout.fillWidth: true
        Layout.fillHeight: true
        anchors.top: explorerNavbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 10
        clip: true
    }
}
