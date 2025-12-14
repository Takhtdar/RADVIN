import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs


Item {
    width: mainScreen.width
    height: mainScreen.height
    z: 3

    property int currentSentenceId: -1
    property string currentSentenceText: ""
    property string currentSentenceType: ""
    property int unsentCount: 0
    property string formattedSentenceText: ""
    property bool isMarkdownView: false // Add this property at the top


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
                editor.enabled = true
            } else {
                loadSentenceIntoOverlay(-1, "No sentence left! read more.", "");
                editor.enabled = false
            }
        }

        function loadSentenceIntoOverlay(id, text, type) {
            currentSentenceId = id;
            currentSentenceText = text;
            currentSentenceType = type;
            formattedSentenceText = text;
            editor.text = text;
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

                        TextArea {
                                id: editor
                                width: textContainer.width
                                wrapMode: TextArea.WrapAtWordBoundaryOrAnywhere
                                textFormat: isMarkdownView ? TextEdit.MarkdownText : TextEdit.PlainText

                                font.pointSize: 14
                                text: currentSentenceText
                                onTextChanged: { formattedSentenceText = text }

                                Keys.onPressed: (event) => {
                                    if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_B) {
                                        event.accepted = true;
                                        formatSelectionWithStars();
                                    }
                                    if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_E) {
                                        event.accepted = true;

                                        var savedPos = editor.cursorPosition;

                                        // Count ** patterns before cursor in current text
                                        var currentText = text;
                                        var textUpToCursor = currentText.substring(0, savedPos);
                                        var starsCount = (textUpToCursor.match(/\*\*/g) || []).length * 2;

                                        // Toggle the view
                                        isMarkdownView = !isMarkdownView;

                                        // Adjust cursor based on transition direction
                                        if (isMarkdownView) { // Switching to markdown - stars get "hidden"
                                            editor.cursorPosition = savedPos - starsCount;
                                        } else { // Switching to plain - stars become visible
                                            editor.cursorPosition = savedPos + starsCount;
                                        }
                                    }
                                }

                                function formatSelectionWithStars() {
                                    // SAVE CURSOR + SELECTION EARLY
                                    var oldCursor = cursorPosition;
                                    var oldAnchor = selectionStart;

                                    // Read current selection (read-only properties but readable)
                                    var selStart = selectionStart;
                                    var selEnd = selectionEnd;

                                    // If nothing selected, expand to word under cursor
                                    if (selStart === selEnd) {
                                        var txt = text;
                                        var pos = cursorPosition;
                                        if (pos < 0) pos = 0;
                                        if (pos > txt.length) pos = txt.length;

                                        var s = pos;
                                        while (s > 0 && !/\s/.test(txt.charAt(s-1))) s--;
                                        var e = pos;
                                        while (e < txt.length && !/\s/.test(txt.charAt(e))) e++;
                                        selStart = s;
                                        selEnd = e;
                                        if (selStart === selEnd) return; // nothing to format
                                    }

                                    var before = text.substring(0, selStart);
                                    var sel = text.substring(selStart, selEnd);
                                    var after = text.substring(selEnd);

                                    // Case A: text inside selection is already **wrapped**
                                    if (sel.length >= 4 && sel.indexOf("**") === 0 && sel.lastIndexOf("**") === sel.length - 2) {
                                        var newSel = sel.substring(2, sel.length - 2);
                                        text = before + newSel + after;

                                        // Only adjust cursor in PlainText mode
                                        if (!isMarkdownView) {
                                            cursorPosition = oldCursor - 2;
                                        } else {
                                            cursorPosition = oldCursor; // In Markdown mode, rendered position stays same
                                        }
                                        return;
                                    }

                                    // Case B: selection is surrounded by stars outside
                                    if (before.length >= 2 && before.slice(-2) === "**" && after.length >= 2 && after.slice(0,2) === "**") {
                                        var newBefore = before.slice(0, -2);
                                        var newAfter = after.slice(2);
                                        text = newBefore + sel + newAfter;

                                        // Only adjust cursor in PlainText mode
                                        if (!isMarkdownView) {
                                            cursorPosition = oldCursor - 2;
                                        } else {
                                            cursorPosition = oldCursor; // In Markdown mode, rendered position stays same
                                        }
                                        return;
                                    }

                                    // Else: wrap selection with **
                                    var wrapped = "**" + sel + "**";
                                    var newText = before + wrapped + after;
                                    text = newText;

                                    // Only adjust cursor in PlainText mode
                                    if (!isMarkdownView) {
                                        cursorPosition = oldCursor + 2;
                                    } else {
                                        cursorPosition = oldCursor; // In Markdown mode, rendered position stays same
                                    }
                                }
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
                            ColumnLayout {
                                // I like for my button to appear here.
                                Button {
                                    text: "Import text file"
                                    Layout.fillWidth: true

                                    onClicked: {
                                        fileDialog.open()
                                    }
                                }

                                FileDialog {
                                    id: fileDialog
                                    title: "Select text file"
                                    nameFilters: ["Text files (*.txt)"]

                                    onAccepted: {
                                        dbManager.importTextFile(selectedFile)
                                    }
                                }

                            }
                        }
                    }
                }
            }
        }
    }
}
