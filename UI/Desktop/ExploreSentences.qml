import QtQuick
import QtQuick.Controls

Item {
    anchors.fill: parent
    property var sentenceList: dbManager.getExplorerEntries(100)

    ScrollView {
        anchors.fill: parent
        anchors.margins: 10

        ListView {
            id: sentenceListView
            model: sentenceList
            spacing: 2

            delegate: ItemDelegate {
                width: ListView.view.width
                height: contentText.implicitHeight + 20

                Text {
                    id: contentText
                    anchors.fill: parent
                    anchors.margins: 10
                    text: modelData.text
                    wrapMode: Text.Wrap
                    font.pixelSize: 14
                    textFormat: Text.MarkdownText
                }

                onClicked: {
                    explorer.previousState = {
                        view: viewOptions.currentIndex,
                        filter: filterOptions.currentIndex
                    }
                    explorer.openSentenceProfile(modelData.id)
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "lightgray"
                }
            }
        }
    }
}
