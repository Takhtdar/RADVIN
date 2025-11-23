
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    implicitHeight: mainLayout.implicitHeight
    Layout.fillHeight: true

    property var jsonData: ({})

    // Styling
    property color headerColor: "#F3F4F6"
    property color headerHoverColor: "#E5E7EB"
    property color textColor: "#1F2937"
    property color accentColor: "#3B82F6"
    property color borderColor: "#E5E7EB"



    ColumnLayout {
        id: mainLayout
        width: root.width
        spacing: 8

        Repeater {
            model: root.isObject(root.jsonData) ? Object.keys(root.jsonData) : []

            delegate: ColumnLayout {
                id: sectionDelegate
                width: parent.width
                spacing: 0

                property string key: modelData
                property var value: root.jsonData[modelData]
                property bool expanded: false

                // Header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: headerMouseArea.containsMouse ? root.headerHoverColor : root.headerColor
                    radius: 6
                    border.color: root.borderColor
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: root.formatTitle(sectionDelegate.key)
                            font.pointSize: 11
                            font.bold: true
                            color: root.textColor
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "❯"
                            color: "#6B7280"
                            font.pointSize: 10
                            rotation: sectionDelegate.expanded ? 90 : 0
                            Behavior on rotation { NumberAnimation { duration: 200 } }
                        }
                    }

                    MouseArea {
                        id: headerMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sectionDelegate.expanded = !sectionDelegate.expanded
                    }
                }

                // Content Body
                Rectangle {
                    Layout.fillWidth: true
                    visible: sectionDelegate.expanded
                    Layout.preferredHeight: sectionDelegate.expanded ? contentColumn.implicitHeight + 24 : 0
                    clip: true
                    color: "white"
                    border.color: root.borderColor
                    border.width: 1
                    radius: 6

                    Behavior on Layout.preferredHeight {
                        NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                    }

                    ColumnLayout {
                        id: contentColumn
                        x: 12
                        y: 12
                        width: parent.width - 24
                        spacing: 6

                        // Recursive content display
                        Repeater {
                            model: root.isObject(sectionDelegate.value) ? Object.keys(sectionDelegate.value) : []
                            delegate: ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                property string currentKey: modelData
                                property var currentValue: sectionDelegate.value[modelData]
                                property bool isSimpleValue: !root.isObject(currentValue) && !root.isArray(currentValue)





                                // For simple values (strings, numbers, booleans)
                                GridLayout {
                                    visible: isSimpleValue
                                    Layout.fillWidth: true
                                    columns: {
                                        // Calculate total text length
                                        var keyText = root.formatTitle(currentKey) + ":";
                                        var valueText = root.formatValue(currentValue);
                                        var totalLength = keyText.length + valueText.length;

                                        // Use 2 columns if total length is short, otherwise 1 column
                                        return totalLength <= 60 ? 2 : 1; // Adjust 60 to your preferred threshold
                                    }
                                    rowSpacing: 2
                                    columnSpacing: 6

                                    Text {
                                        text: root.formatTitle(currentKey) + ":"
                                        font.bold: true
                                        color: root.textColor
                                        font.pointSize: 11
                                        Layout.alignment: Qt.AlignTop
                                    }

                                    Text {
                                        text: root.formatValue(currentValue)
                                        color: "#4B5563"
                                        font.pointSize: 11
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                        textFormat: Text.MarkdownText
                                    }
                                }


                                // For arrays
                                ColumnLayout {
                                    visible: root.isArray(currentValue)
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        text: root.formatTitle(currentKey) + ":"
                                        font.bold: true
                                        color: root.textColor
                                        font.pointSize: 11
                                    }

                                    Repeater {
                                        model: currentValue
                                        delegate: RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                text: "•"
                                                color: root.accentColor
                                                font.pointSize: 11
                                            }

                                            Text {
                                                text: {
                                                    // Handle both objects and simple values safely
                                                    if (root.isObject(modelData)) {
                                                        return root.formatObjectAsText(modelData);
                                                    } else {
                                                        return root.formatValue(modelData);
                                                    }
                                                }
                                                color: "#4B5563"
                                                font.pointSize: 11
                                                wrapMode: Text.Wrap
                                                Layout.fillWidth: true
                                                textFormat: Text.MarkdownText
                                            }
                                        }
                                    }
                                }




                                // For nested objects
                                ColumnLayout {
                                    visible: root.isObject(currentValue) && !root.isArray(currentValue)
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        text: root.formatTitle(currentKey) + ":"
                                        font.bold: true
                                        color: root.textColor
                                        font.pointSize: 11
                                    }

                                    Repeater {
                                        model: Object.keys(currentValue)
                                        delegate: RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                text: "  " + root.formatTitle(modelData) + ":"
                                                font.bold: true
                                                color: "#6B7280"
                                                font.pointSize: 10
                                                Layout.preferredWidth: implicitWidth
                                                textFormat: Text.MarkdownText
                                            }
                                            Text {
                                                text: root.formatValue(currentValue[modelData])
                                                color: "#4B5563"
                                                font.pointSize: 10
                                                wrapMode: Text.Wrap
                                                Layout.fillWidth: true
                                                textFormat: Text.MarkdownText
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
    }


    // Helper functions
    function isObject(val) {
        return val !== null && typeof val === 'object' && !Array.isArray(val);
    }

    function isArray(val) {
        return Array.isArray(val);
    }

    function formatTitle(str) {
        if (!str) return "";
        // Convert to string explicitly
        var stringStr = String(str);
        return stringStr.replace(/_/g, " ").replace(/\b\w/g, l => l.toUpperCase());
    }

    function formatValue(val) {
        if (val === null) {
            return "null";
        } else if (val === undefined) {
            return "undefined";
        }

        // Convert to string first to handle QJSValue issues
        var stringVal = String(val);

        if (stringVal === "true" || stringVal === "false") {
            return stringVal === "true" ? "✅ true" : "❌ false";
        } else {
            return stringVal;
        }
    }

    function formatObjectAsText(obj) {
        if (!isObject(obj)) return "";
        var parts = [];
        for (var key in obj) {
            if (obj.hasOwnProperty(key)) {
                parts.push(root.formatTitle(key) + ": " + root.formatValue(obj[key]));
            }
        }
        return parts.join(", ");
    }
}
