import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    width: parent ? parent.width : 300
    spacing: 0

    // API
    property string title: "Section"
    default property alias content: contentItem.data // Allows nesting anything inside
    property bool expanded: true // Default to open

    // Visual style
    property color headerColor: "#f3f4f6"
    property color contentColor: "#ffffff"

    Rectangle {
        id: header
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        color: root.headerColor
        radius: 8

        // Animate corners when opening/closing
        Behavior on bottomLeftRadius { NumberAnimation { duration: 200 } }
        Behavior on bottomRightRadius { NumberAnimation { duration: 200 } }
        bottomLeftRadius: root.expanded ? 0 : 8
        bottomRightRadius: root.expanded ? 0 : 8

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            Text {
                text: root.formatTitle(root.title)
                font.pointSize: 12
                font.bold: true
                color: "#1f2937"
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: "›"
                font.pointSize: 18
                color: "#6b7280"
                rotation: root.expanded ? 90 : 0
                Behavior on rotation { NumberAnimation { duration: 200 } }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    // The Content Container
    Rectangle {
        id: contentContainer
        Layout.fillWidth: true
        color: root.contentColor
        radius: 8

        // Flatten top corners to merge with header
        topLeftRadius: 0
        topRightRadius: 0

        clip: true

        // Animate Height
        implicitHeight: root.expanded ? contentItem.implicitHeight + 20 : 0
        Behavior on implicitHeight { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

        visible: implicitHeight > 0

        ColumnLayout {
            id: contentItem
            width: parent.width
            anchors.top: parent.top
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            spacing: 10
        }
    }

    // Helper to make "snake_case" look like "Title Case"
    function formatTitle(str) {
        if (!str) return ""
        return str.replace(/_/g, " ").replace(/\b\w/g, l => l.toUpperCase())
    }
}
