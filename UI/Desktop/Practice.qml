import QtQuick
import QtQuick.Controls

Rectangle {
    color: "lightgreen"
    width: mainScreen.width
    height: mainScreen.height
    radius: 8
    z: 3

    Text {
        text: "🔍 Practice Page"
        font.pixelSize: 24
        anchors.centerIn: parent
        color: "black"
    }
}
