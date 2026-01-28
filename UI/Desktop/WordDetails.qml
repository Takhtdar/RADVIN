import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root
    color: "#f8f9fa"  // Lighter background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Tab bar
        TabBar {
            id: tabBar
            Layout.fillWidth: true

            TabButton {
                text: "Definition"
                width: implicitWidth + 20
            }
            TabButton {
                text: "Collocations"
                width: implicitWidth + 20
            }
            TabButton {
                text: "Synonyms"
                width: implicitWidth + 20
            }
            TabButton {
                text: "Examples"
                width: implicitWidth + 20
            }
        }

        // Content area
        StackLayout {
            id: stackLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // ========== DEFINITION TAB ==========
            Rectangle {
                color: "transparent"

                Column {
                    anchors.fill: parent
                    spacing: 2

                    // Table header
                    Rectangle {
                        width: parent.width
                        height: 40
                        color: "#007AFF"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 20

                            Text {
                                width: 100
                                text: "Part of Speech"
                                color: "white"
                                font.bold: true
                            }

                            Text {
                                width: parent.width - 120
                                text: "Definition"
                                color: "white"
                                font.bold: true
                            }
                        }
                    }

                    // Table content
                    ListView {
                        width: parent.width
                        height: parent.height - 42
                        clip: true
                        model: ListModel {
                            ListElement { partOfSpeech: "noun"; definition: "A small domesticated carnivorous mammal with soft fur" }
                            ListElement { partOfSpeech: "verb"; definition: "Raise (an anchor) from the surface of the water" }
                            ListElement { partOfSpeech: "adj."; definition: "Relating to cats; catlike" }
                        }

                        delegate: Rectangle {
                            width: parent.width
                            height: 50
                            color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                            border.color: "#e9ecef"
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 20

                                Text {
                                    width: 100
                                    text: model.partOfSpeech
                                    font.pixelSize: 14
                                    color: "#495057"
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    width: parent.width - 120
                                    text: model.definition
                                    font.pixelSize: 14
                                    color: "#212529"
                                    wrapMode: Text.WordWrap
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }

            // ========== COLLOCATIONS TAB ==========
            Rectangle {
                color: "transparent"

                Column {
                    anchors.fill: parent
                    spacing: 2

                    // Table header
                    Rectangle {
                        width: parent.width
                        height: 40
                        color: "#28a745"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 20

                            Text {
                                width: 150
                                text: "Pattern"
                                color: "white"
                                font.bold: true
                            }

                            Text {
                                width: parent.width - 170
                                text: "Examples"
                                color: "white"
                                font.bold: true
                            }
                        }
                    }

                    // Table content
                    ListView {
                        width: parent.width
                        height: parent.height - 42
                        clip: true
                        model: ListModel {
                            ListElement { pattern: "Verb + cat"; examples: "feed a cat, pet a cat, adopt a cat" }
                            ListElement { pattern: "Adjective + cat"; examples: "stray cat, domestic cat, black cat" }
                            ListElement { pattern: "Noun + cat"; examples: "cat food, cat lover, cat owner" }
                        }

                        delegate: Rectangle {
                            width: parent.width
                            height: 50
                            color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                            border.color: "#e9ecef"
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 20

                                Text {
                                    width: 150
                                    text: model.pattern
                                    font.pixelSize: 14
                                    color: "#495057"
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    width: parent.width - 170
                                    text: model.examples
                                    font.pixelSize: 14
                                    color: "#6c757d"
                                    wrapMode: Text.WordWrap
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }

            // ========== SYNONYMS TAB ==========
            Rectangle {
                color: "transparent"

                Column {
                    anchors.fill: parent
                    spacing: 2

                    // Table header
                    Rectangle {
                        width: parent.width
                        height: 40
                        color: "#dc3545"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10

                            Text {
                                text: "Synonyms"
                                color: "white"
                                font.bold: true
                                font.pixelSize: 16
                            }
                        }
                    }

                    // Table content
                    GridView {
                        width: parent.width
                        height: parent.height - 42
                        cellWidth: 120
                        cellHeight: 50
                        clip: true

                        model: ListModel {
                            ListElement { synonym: "feline"; type: "noun" }
                            ListElement { synonym: "kitty"; type: "noun" }
                            ListElement { synonym: "pussycat"; type: "noun" }
                            ListElement { synonym: "tomcat"; type: "noun" }
                            ListElement { synonym: "moggy"; type: "noun" }
                            ListElement { synonym: "mouser"; type: "noun" }
                        }

                        delegate: Rectangle {
                            width: 110
                            height: 40
                            radius: 6
                            color: "#e3f2fd"
                            border.color: "#bbdefb"
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    text: model.synonym
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#1976d2"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: "(" + model.type + ")"
                                    font.pixelSize: 10
                                    color: "#5c6bc0"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }
                }
            }

            // ========== EXAMPLES TAB ==========
            Rectangle {
                color: "transparent"

                Column {
                    anchors.fill: parent
                    spacing: 2

                    // Table header
                    Rectangle {
                        width: parent.width
                        height: 40
                        color: "#ffc107"

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 20

                            Text {
                                width: 80
                                text: "No."
                                color: "white"
                                font.bold: true
                            }

                            Text {
                                width: parent.width - 100
                                text: "Example Sentence"
                                color: "white"
                                font.bold: true
                            }
                        }
                    }

                    // Table content
                    ListView {
                        width: parent.width
                        height: parent.height - 42
                        clip: true
                        model: ListModel {
                            ListElement { sentence: "The cat sat on the mat." }
                            ListElement { sentence: "She has two cats and a dog." }
                            ListElement { sentence: "My cat purrs loudly when I pet her." }
                            ListElement { sentence: "The cat chased the mouse around the house." }
                        }

                        delegate: Rectangle {
                            width: parent.width
                            height: 60
                            color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                            border.color: "#e9ecef"
                            border.width: 1

                            Row {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 20

                                Text {
                                    width: 80
                                    text: (index + 1) + "."
                                    font.pixelSize: 14
                                    color: "#6c757d"
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    width: parent.width - 100
                                    text: model.sentence
                                    font.pixelSize: 14
                                    color: "#212529"
                                    wrapMode: Text.WordWrap
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
