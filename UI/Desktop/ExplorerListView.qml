// ListView.qml
import QtQuick
import QtQuick.Controls // For Button, ScrollView, etc., if needed

Item { // Use Item as a flexible root, or Rectangle if you want a background
    // Assuming you want this to fill its parent
    anchors.fill: parent


    // Model: Use the method from your DatabaseManager exposed as 'dbManager'
    // This assumes you want to fetch unsent sentences initially.
    // You might need to trigger this or update it based on your app logic.
    property var sentenceList: dbManager.getExplorerEntries(100) // Fetch up to 100, adjust as needed
    // only show items with more than one word! idioms, collocations, sentences and such! not one word!

    // ScrollView provides scrolling functionality
    ScrollView {
        anchors.fill: parent // Fill the Item
        anchors.margins: 10 // Add some padding if desired

        // The ListView inside the ScrollView
        ListView {


            id: sentenceListView
            // Use the sentenceList property as the model
            model: sentenceList

            // Delegate: How each item in the model should be displayed
            delegate: ItemDelegate { // Or Rectangle, or whatever you prefer for styling
                width: ListView.view.width // Full width of the list view
                height: contentText.implicitHeight + 20 // Height based on text + padding

                // Display the 'text' field from your model item (which is a QVariantMap)
                Text {
                    id: contentText
                    anchors.fill: parent
                    anchors.margins: 10
                    text: modelData.text // modelData refers to the current item in the model (a QVariantMap)
                    wrapMode: Text.Wrap // Wrap text if it's long
                    font.pixelSize: 14 // Adjust font size as needed
                    textFormat: Text.MarkdownText
                }

                onClicked: {
                    explorer.previousState = {
                        view: viewOptions.currentIndex,
                        filter: filterOptions.currentIndex
                    }
                    explorer.openSentenceProfile(modelData.id)
                }

                // Optional: Add a separator
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "lightgray"
                }
            }

            // Optional: Add spacing between items
            spacing: 2

            // Optional: Show a header or footer if needed
            // header: Text { text: "My Sentences"; font.bold: true; padding: 10 }
        }
    }


}
