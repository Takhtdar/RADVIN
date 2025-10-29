// ExplorerTableView.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    anchors.fill: parent

    // dynamic list that will hold words from the database
    ListModel { id: wordModel }

    // number of columns and layout metrics
    property int columns: 5
    property int cellSpacing: 8
    property int cellWidth: Math.max(100, Math.floor((root.width - (columns + 1) * cellSpacing) / columns))
    property int cellHeight: 80

    Component.onCompleted: {
        // safety check: dbManager must be exposed to QML context
        if (typeof dbManager === "undefined" || dbManager.getWords === undefined) {
            console.error("❌ dbManager is not available in QML context.")
            return
        }

        const words = dbManager.getWords()
        wordModel.clear()

        if (!words || words.length === 0) {
            console.warn("⚠️ No words found in database.")
            return
        }

        // populate model dynamically
        for (let i = 0; i < words.length; ++i) {
            const w = words[i]
            wordModel.append({
                vocab: w.vocab,
                type: w.type,
                idNum: w.idNum
            })
        }

        console.log(`✅ Loaded ${words.length} words from database.`)
    }

    ScrollView {
        id: scroller
        anchors.fill: parent
        clip: true

        GridView {
            id: grid
            anchors.fill: parent
            model: wordModel
            cellWidth: root.cellWidth
            cellHeight: root.cellHeight
            flow: GridView.LeftToRight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            highlightFollowsCurrentItem: false
            interactive: true

            delegate: Rectangle {
                width: grid.cellWidth
                height: grid.cellHeight
                radius: 6
                border.width: 1
                border.color: "#cfcfcf"

                color: {
                    if (type === "verb") return "#dff7df"      // light green
                    else if (type === "noun") return "#f7dfdf" // light red
                    else if (type === "adjective") return "#dfecf7" // light blue
                    else return "#efefef"
                }

                Column {
                    anchors.centerIn: parent  // Center the entire column in the rectangle
                    spacing: 4
                    width: parent.width - 16  // Account for margins

                    Text {
                        id: wordText
                        text: vocab
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        wrapMode: Text.Wrap
                        width: parent.width
                        color: "black"
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (typeof explorer !== "undefined" && explorer.openWordProfile) {
                            explorer.openWordProfile(idNum)
                        } else {
                            console.log("clicked id:", idNum)
                        }
                    }
                    onEntered: border.color = "#999"
                    onExited: border.color = "#cfcfcf"
                }
            }
        }
    }
}
