import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    // Bind height to content so parent ScrollView handles it
    implicitHeight: header.height + listView.contentHeight
    implicitWidth: parent.width

    property var tableModel: []
    property var tableColumns: []

    // Helper: Calculate column width based on total width
    property real columnWidth: width / (tableColumns.length || 1)

    Column {
        anchors.fill: parent

        // 1. Header (Remains fixed height usually, but you can use Layout here too if needed)
        Row {
            id: header
            width: parent.width
            height: 40
            spacing: -1 // <--- Overlaps the 1px borders to remove the "gap"


            Repeater {
                model: root.tableColumns
                    delegate: Rectangle {
                        width: root.columnWidth
                        height: parent.height
                        color: "#EBEEF3"
                        border.color: "#EBEEF3"
                        border.width: 1

                        // Conditionally apply radius based on the column index
                        topLeftRadius: index === 0 ? 8 : 0
                        topRightRadius: index === root.tableColumns.length - 1 ? 8 : 0

                        // Ensure bottom corners are always square to meet the data rows
                        bottomLeftRadius: 0
                        bottomRightRadius: 0

                    Text {
                        anchors.centerIn: parent
                        text: modelData.label
                        font.bold: true
                        width: parent.width - 10
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // 2. Data Rows
        ListView {
            id: listView
            width: parent.width
            height: contentHeight
            interactive: false
            model: root.tableModel

            // USE RowLayout here to handle dynamic heights
            delegate: RowLayout {
                width: listView.width
                spacing: -1 // <--- Overlaps borders in the data rows too


                property var rowData: modelData

                Repeater {
                    model: root.tableColumns
                    delegate: Rectangle {
                        // 1. Width calculation
                        Layout.preferredWidth: root.columnWidth

                        // 2. Height calculation:
                        // "Layout.fillHeight: true" makes this cell stretch if a neighbor is taller.
                        Layout.fillHeight: true

                        // We must define how tall this specific cell *wants* to be based on text.
                        // We set a minimum of 40, or the text height + 20px padding.
                        Layout.preferredHeight: Math.max(40, textItem.implicitHeight + 20)

                        border.color: "#EBEEF3"
                        border.width: 1

                        Text {
                            id: textItem
                            anchors.centerIn: parent
                            width: parent.width - 20 // Give 10px padding on each side
                            font.pixelSize: 16
                            // 3. Enable Wrapping
                            text: rowData[modelData.role] !== undefined ? rowData[modelData.role] : ""
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}
