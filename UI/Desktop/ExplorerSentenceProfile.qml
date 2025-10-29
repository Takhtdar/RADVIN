import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    property var profileId
    property string profileType: "sentence"

    ColumnLayout {
        anchors.fill: parent

        Label {
          text: "Sentence Profile"
          font.pixelSize: 20
          font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: "lightgray"
        }

        RowLayout{
            Layout.fillWidth: true
            Layout.fillHeight: true

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
                    anchors.margins: 10

                    Text {
                        id: originalSentenceText
                        font.pointSize: 12
                        width: parent.width
                        wrapMode: Text.Wrap
                        text: "Original sentence will appear here..."
                    }
                }
            }


        // Thin separator
        Rectangle {
            Layout.preferredWidth: 2
            color: "lightgray"
            Layout.fillHeight: true
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
                width: parent.width  // Match the Flickable width
                anchors.margins: 10

                Text {
                    id: aiResponseText
                    font.pointSize: 12
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: "AI response will appear here..."
                    textFormat: Text.MarkdownText  // Changed from MarkdownText for better compatibility
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
