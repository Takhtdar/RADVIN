import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    width: mainScreen.width
    height: mainScreen.height
    z: 3

    property int currentSentenceId: -1
    property string currentSentenceText: ""
    property string currentSentenceType: ""
    property int unsentCount: 0
    property string formattedSentenceText: ""

    ListView {
        id: sentenceList
        anchors.fill: parent
        // spacing: 8
        clip: true
        interactive: false
        model: ListModel {}
        width: parent.width

        Component.onCompleted: {
            loadSentences()
        }

        Connections {
            target: dbManager
            function onQueueChanged() {
                sentenceList.loadSentences();
            }
        }

        function loadSentences() {
            unsentCount = dbManager.getQueueCount();
            var sentences = dbManager.getQueueEntries(5);
            model.clear();
            for (var i = 0; i < sentences.length; i++) {
                model.append({
                    "id": sentences[i].id,
                    "text": sentences[i].text,
                    "type": sentences[i].type
                });
            }
            unsentCount = dbManager.getQueueCount();
            if (sentences.length > 0) {
                loadSentenceIntoOverlay(sentences[0].id, sentences[0].text, sentences[0].type);
            } else {
                loadSentenceIntoOverlay(-1, "No sentence left! read more.", "");
            }
        }

        function loadSentenceIntoOverlay(id, text, type) {
            currentSentenceId = id;
            currentSentenceText = text;
            currentSentenceType = type;
            formattedSentenceText = text;
            paragraphContainer.generateWords();
        }
    }


    RowLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        z: 10

        ColumnLayout{
            Layout.preferredWidth: parent.width * 4 / 7  // Two-thirds of the RowLayout width
            Layout.fillHeight: true

            Text {
                id: numberOfItemsInQueue
                wrapMode: Text.WrapAnywhere
                horizontalAlignment: Text.AlignJustify
                text: "📋 Queue: " + unsentCount + " sentences left"
                font.bold: true
                bottomPadding: 20
                topPadding: 25
                font.pointSize: 14

                Component.onCompleted: {
                    sentenceList.loadSentences();
                }
            }


            Rectangle {
                id: textContainer
                radius: 8
                color: "#f9fafb"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 1

                ScrollView {
                    anchors.fill: parent
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded


                    Item {
                        id: paragraphContainer
                        width: textContainer.width
                        implicitHeight: paragraphContainer.height


                        property var wordData: [] // keeps {word, bold}
                        property var wordItems: []

                        function generateWords() {
                            // clear old
                            for (var i = 0; i < wordItems.length; i++) {
                                wordItems[i].destroy();
                            }
                            wordItems = [];

                            if (currentSentenceText === "")
                                return;

                            wordData = [];
                            var words = currentSentenceText.split(/\s+/);
                            var yPos = 0;
                            var xPos = 10;
                            var maxWidth = textContainer.width - 20;
                            var lineHeight = 26;

                            for (var w = 0; w < words.length; w++) {
                                var word = words[w];
                                var tempText = Qt.createQmlObject('import QtQuick 2.15; Text { text: "' + word.replace(/"/g, '\\"') + ' "; font.pointSize: 14; visible: false;  }', paragraphContainer);
                                tempText.width; // force measure
                                var wordWidth = tempText.contentWidth;
                                tempText.destroy();

                                if (xPos + wordWidth > maxWidth) {
                                    xPos = 10;
                                    yPos += lineHeight;
                                }

                                var textObj = Qt.createQmlObject(`
                                    import QtQuick 2.15;
                                    Text {
                                        text: "${word.replace(/"/g, '\\"')}";
                                        x: ${xPos};
                                        y: ${yPos};
                                        font.pointSize: 14;
                                        color: "black";
                                        width: ${maxWidth};
                                        wrapMode: Text.WrapAnywhere;
                                        topPadding: 15
                                        rightPadding: 15
                                        leftPadding: 15
                                        MouseArea {
                                            anchors.fill: parent;
                                            hoverEnabled: true;
                                            onClicked: {
                                                parent.font.bold = !parent.font.bold;
                                                paragraphContainer.updateFormattedText();
                                            }
                                        }
                                    }
                                `, paragraphContainer);
                                paragraphContainer.wordData.push({ word: word, bold: false });
                                paragraphContainer.wordItems.push(textObj);
                                xPos += wordWidth + 5;
                            }
                            paragraphContainer.height = yPos + lineHeight + 10;
                            updateFormattedText();
                        }

                        function updateFormattedText() {
                            var boldStates = [];
                            var formatted = "";
                            for (var i = 0; i < wordItems.length; i++) {
                                var textObj = wordItems[i];
                                var isBold = textObj.font.bold;
                                var word = textObj.text;
                                boldStates.push(isBold);
                                if (isBold) {
                                    formatted += "**" + word + "** ";
                                } else {
                                    formatted += word + " ";
                                }
                            }
                            formattedSentenceText = formatted.trim();
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true; height: 100 }


            RowLayout {
                id: buttons
                Layout.fillWidth: true
                height: 150
                Layout.bottomMargin: 20

                // maybe disable button when there is no item in queue!

                ButtonItem {
                    id: discardButton
                    text: "🗑️ Discard"
                    backgroundColor: "#e63946"
                    hoverColor: "#bd2130"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft

                    onClicked: {
                        console.log("Discard ID:", currentSentenceId);
                        if (currentSentenceId !== -1) {
                            dbManager.discardQueueItem(currentSentenceId, currentSentenceType);
                            sentenceList.loadSentences();
                        }
                    }
                }



                Item {Layout.fillWidth: true}

                ButtonItem {
                    id: passButton
                    text: "🚀 Explore it"
                    backgroundColor: "#28a745"
                    hoverColor: "#218838"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight

                    onClicked: {
                        if (currentSentenceId !== -1) {
                            console.log("Passing formatted:", formattedSentenceText);
                            dbManager.markQueueItemToProcess(currentSentenceId, formattedSentenceText, currentSentenceType);
                            sentenceList.loadSentences();
                        }
                    }
                }
            }
        }

        ColumnLayout{
            Layout.fillHeight: true
            Layout.preferredWidth: parent.width * 3 / 7      // One-third of the RowLayout width

            Rectangle {
                id: containerMetadata
                radius: 8
                color: "#f9fafb"
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 1

                ScrollView {
                    anchors.fill: parent
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    Item {
                        width: textContainer.width
                        Column {
                            anchors.fill: parent
                            ColumnLayout { }
                        }
                    }
                }
            }
        }
    }




}
