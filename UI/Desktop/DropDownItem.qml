import QtQuick
import QtQuick.Controls


Column {
    id: root
    width: parent ? parent.width : 300
    spacing: 0

    // API
    property alias model: repeater.model
    property string title: "Section"
    property int columns: 2

    Rectangle {
        id: header
        width: parent.width
        color: "#f3f4f6"
        radius: 8
        height: 60


        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                text: root.title
                font.pointSize: 12
                font.bold: true
                verticalAlignment: Text.AlignVCenter
                width: parent.width - 30
                wrapMode: Text.Wrap
                height: parent.height
            }

            Text {
                id: arrow
                text: ">"
                font.pointSize: 12
                verticalAlignment: Text.AlignVCenter
                rotation: content.visible ? 90 : 0
                height: parent.height
                Behavior on rotation { NumberAnimation { duration: 200 } }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                content.visible = !content.visible
                header.bottomLeftRadius = content.visible ? 0 : 8
                header.bottomRightRadius = content.visible ? 0 : 8
            }
        }
    }

    Rectangle {
        id: content
        width: parent.width
        color: "#f9fafb"
        radius: 8
        visible: false
        height: container.height

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Item {
            id: container
            width: parent.width
            height: grid.height + 20

            Grid {
                id: grid
                columns: root.columns
                spacing: 10
                width: parent.width - 10
                anchors.top: parent.top
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter

                Repeater {
                    id: repeater
                    model: 0

                    Rectangle {
                        width: root.columns == 1 ? parent.width : (parent.width  - parent.spacing) / root.columns
                        height: textItem.height + 20
                        color: "#e5e7eb"
                        radius: 4

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: console.log("Clicked:", modelData.id)
                        }

                        Text {
                            id: textItem
                            anchors.centerIn: parent
                            text: modelData.word
                            wrapMode: Text.Wrap
                            width: parent.width - 20
                            font.pointSize: 10
                            textFormat: Text.MarkdownText
                        }
                    }
                }
            }
        }
    }
}
