// ExplorerTableView.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    anchors.fill: parent

    anchors.rightMargin: 8

    ListModel { id: wordModel }

    ScrollView {
        id: scroller
        anchors.fill: parent
        clip: true



        GridView {
            id: grid
            anchors.fill: parent
            model: wordModel

            flow: GridView.LeftToRight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            highlightFollowsCurrentItem: false
            interactive: true

            cellWidth: width / columns
            property int minCellWidth: 160
            property int columns: Math.max(1, Math.floor(width / minCellWidth))
            property int spacing: 12

            delegate: Item {
                width: grid.cellWidth
                height: 70
                property bool hovered: false


                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    anchors.rightMargin: Math.round(grid.spacing / 2)
                    anchors.leftMargin: Math.round(grid.spacing / 2)
                    border.width: 1
                    border.color: hovered ? "#999" : "#cfcfcf"

                    color: {
                        switch (type) {
                        case "verb": return "#dff7df"
                        case "noun": return "#f7dfdf"
                        case "adjective": return "#dfecf7"
                        default: return "#efefef"
                        }
                    }

                    Text {
                        text: vocab
                        anchors.centerIn: parent
                        width: parent.width - 10
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: hovered = true
                        onExited: hovered = false
                        onClicked: explorer.openProfile(id, "word")
                    }
                }
            }
        }
















    }








    Component.onCompleted: {
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

        for (let i = 0; i < words.length; ++i) {
            const w = words[i]
            wordModel.append({
                vocab: w.vocab,
                type: w.type,
                id: w.id
            })
        }
        console.log(`✅ Loaded ${words.length} words from database.`)
    }
}
