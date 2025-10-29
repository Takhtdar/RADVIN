import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    width: mainScreen.width
    height: mainScreen.height
    z: 3

    property int currentSentenceId: -1
    property string currentSentenceText: ""
    property int unsentCount: 0
    property string formattedSentenceText: "" // ✅ holds formatted (bolded) text

    ListView {
        id: sentenceList
        anchors.fill: parent
        spacing: 8
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
                    "text": sentences[i].text
                });
            }
            unsentCount = dbManager.getQueueCount();
            if (sentences.length > 0) {
                loadSentenceIntoOverlay(sentences[0].id, sentences[0].text);
            } else {
                loadSentenceIntoOverlay(-1, "No sentence left! read more.");
            }
        }

        function loadSentenceIntoOverlay(id, text) {
            currentSentenceId = id;
            currentSentenceText = text;
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
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 0    // Forces equal distribution
            Layout.alignment: Qt.AlignLeft  // Aligns to left half of row


            Text {
                id: numberOfItemsInQueue
                wrapMode: Text.WrapAnywhere
                horizontalAlignment: Text.AlignJustify
                text: "📋 Queue: " + unsentCount + " sentences left"
                font.pointSize: 14

                Component.onCompleted: {
                    sentenceList.loadSentences();
                }
            }


            Rectangle {
                id: textContainer
                radius: 8
                color: "white"
                border.color: "lightgray"
                border.width: 1
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
                                var tempText = Qt.createQmlObject('import QtQuick 2.15; Text { text: "' + word.replace(/"/g, '\\"') + ' "; font.pointSize: 14; visible: false; }', paragraphContainer);
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

            RowLayout {
                id: buttons
                Layout.fillWidth: true  // Use Layout.fillWidth instead of anchors
                height: 50

                Button {
                    id: discardButton
                    text: "🗑️ Discard"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft

                    onClicked: {
                        console.log("Discard ID:", currentSentenceId);
                        if (currentSentenceId !== -1) {
                            dbManager.discardSentence(currentSentenceId);
                            sentenceList.loadSentences();
                        }
                    }
                }

                Item {Layout.fillWidth: true}

                Button {
                    id: passButton
                    text: "🚀 Explore it"
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                    onClicked: {
                        if (currentSentenceId !== -1) {
                            console.log("Passing formatted:", formattedSentenceText);
                            dbManager.markToProcessSentence(currentSentenceId, formattedSentenceText);
                            sentenceList.loadSentences();
                        }
                    }
                }
            }
        }

        ColumnLayout{
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 0    // Forces equal distribution
            Layout.alignment: Qt.AlignRight // Aligns to right half of row

            Text {
                id: metadataLabel
                Layout.fillWidth: true  // Takes 50% of available space
                text: "Metadata Options"
                font.pointSize: 14
                horizontalAlignment: Text.AlignHCenter
                z: 100
            }

            Rectangle {
                id: containerMetadata
                radius: 8
                border.color: "lightgray"
                border.width: 1
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
