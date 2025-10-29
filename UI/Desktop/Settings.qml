import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs


Item {
    width: mainScreen.width
    height: mainScreen.height
    z: 3

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: settingsColumn.height

        Column {
            id: settingsColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 20
            spacing: 20

            /*
            todo: how to align the following items? or have them all in one grid? or have a better way!
            improve design!
            */
            GridLayout {
                columns: 2
                rowSpacing: 5
                columnSpacing: 10

                Text {
                    text: "Clipboard Monitoring"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#555"
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter // Align label to the left and vertically centered with the switch
                }

                Switch {
                    id: clipboardToggle
                    checked: settings.getValue("clipboard_enabled", false)
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                    onCheckedChanged: {
                        console.log("📎 Clipboard monitoring switched:", checked ? "ON" : "OFF")
                        settings.setValue("clipboard_enabled", checked)
                        settings.sync()

                        clipboardListener.setEnabled(checked)
                    }
                }

                Text {
                    text: "Select your AI Provider: "
                    font.pixelSize: 16
                    font.bold: true
                    color: "#555"
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter // Align label to the left and vertically centered with the switch
                }

                ComboBox {
                    id: aiProviders
                    textRole: "display"
                    model: [
                        {display: "select provider"},
                        { display: "Ollama" }
                        // to add more providers such as OpenAI, Grok...
                    ]

                    Component.onCompleted: {
                        // Load saved provider from settings
                        var savedProvider = settings.getValue("provider", "Ollama")
                        for (var i = 0; i < model.length; i++) {
                            if (model[i].display === savedProvider) {
                                currentIndex = i
                                break
                            }
                        }
                    }

                    onActivated: function(index) {
                        console.log("Selected index:", index, "text:", aiProviders.currentText)
                        settings.setValue("provider", aiProviders.currentText)
                        settings.sync()
                    }
                }

                Text {
                    text: "AI Provider Address: "
                    font.pixelSize: 16
                    font.bold: true
                    color: "#555"
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter // Align label to the left and vertically centered with the switch
                }

                TextField {
                    id: aiProviderAddress
                    text: settings.getValue("provider_address", "http://127.0.0.1:11434/api/chat")

                    onTextChanged: {
                        settings.setValue("provider_address", text)
                        settings.sync()
                    }
                }


                Text {
                    text: "Model ID: "
                    font.pixelSize: 16
                    font.bold: true
                    color: "#555"
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter // Align label to the left and vertically centered with the switch

                }

                TextField {
                    id: aiModels
                    text: settings.getValue("model", "llama3.1-16k:latest")

                    onTextChanged: {
                        settings.setValue("model", text)
                        settings.sync()
                    }
                }



                Text {
                    text: "Listen to External Queue"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#555"
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter // Align label to the left and vertically centered with the switch
                }

                Switch {
                    id: listenForExternalQueue
                    checked: settings.getValue("listen_external_queue", false)

                    onCheckedChanged: {
                        settings.setValue("listen_external_queue", checked)
                        settings.sync()
                    }
                }


                Text {
                    text: "Host"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#555"
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter // Align label to the left and vertically centered with the switch
                }

                TextField {
                    id: host
                    text: settings.getValue("host", "http://0.0.0.0:54700")
                    placeholderText: "http://0.0.0.0:54700"
                    // to insert items to queue from other devices such as my e-ink device
                    // we read this port, and ip to listen for other clients.
                    // save it to settings in case user didn't enter just save default

                    onTextChanged: {
                        settings.setValue("host", text)
                        settings.sync()
                    }
                }



                Text {
                    text: "Select Word Prompt: "
                    font.pixelSize: 16
                    font.bold: true
                    color: "#555"
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                }

                Button {
                    text: "Select Word Prompt"
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    Layout.preferredWidth: 200

                    onClicked: {
                        fileDialog.title = "Select Word Prompt File"
                        fileDialog.nameFilters = ["Text files (*.txt)", "All files (*)"]
                        fileDialog.open()
                    }
                }

                Text {
                    text: "Select Sentence Prompt: "
                    font.pixelSize: 16
                    font.bold: true
                    color: "#555"
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                }

                Button {
                    text: "Select Sentence Prompt"
                    Layout.preferredWidth: 200
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                    onClicked: {
                        fileDialog.title = "Select Sentence Prompt File"
                        fileDialog.nameFilters = ["Text files (*.txt)", "All files (*)"]
                        fileDialog.open()
                    }
                }
            }

            Text {
                text: "Credit: Qt"
                font.pixelSize: 12
                color: "#999"
                anchors.horizontalCenter: parent.horizontalCenter
                bottomPadding: 20 // Add some space at the very bottom
            }



        }
    }


    FileDialog {
       id: fileDialog
       onAccepted: {
           var filePath = selectedFile.toString()

           if(selectedFile.toString().startsWith("file://")){
            filePath = selectedFile.toString().substring(7);
           }
           if (fileDialog.title.includes("Word")) {
               settings.setValue("word_prompt_file", filePath)
           } else if (fileDialog.title.includes("Sentence")) {
               settings.setValue("sentence_prompt_file", filePath)
           }
           settings.sync()

           console.log("Saved prompt file:", filePath)
       }
   }
}


