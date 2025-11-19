// FancyButton.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    id: root
    width: 150
    height: 40
    radius: 8

    // customizable from outside
    property color backgroundColor: "#e63946"
    property color hoverColor: "#ff4d4d"
    property color textColor: "white"

    color: hovered ? hoverColor : backgroundColor

    property alias text: label.text
    signal clicked()

    property bool hovered: false

    Text {
        id: label
        anchors.centerIn: parent
        color: textColor
        font.pixelSize: 16
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onClicked: root.clicked()
        onEntered: root.hovered = true
        onExited: root.hovered = false
    }
}
