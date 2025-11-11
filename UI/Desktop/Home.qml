// Home.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts


Rectangle {

        Rectangle{
        id: sidebar
        height: parent.height
        width: 50
        color: "white"
        z: 99

        Component.onCompleted: {
            // later show here dashboard! maybe!
            screenLoader.source = "Queue.qml"
            // Close the menu after selection
            if(sidebar.width !== 50) {
                sidebar.toggleMenu()
            }
        }


        function toggleMenu() {
            if(sidebar.width ===  50){
                burgerBtn.color =  "gray"
                sidebar.width = 250
                queueBtn.visible = true
                explorerBtn.visible = true
                practiceBtn.visible = true
                settingBtn.visible = true
                appName.visible = true
            } else{
                burgerBtn.color =  "Black"
                sidebar.width = 50
                queueBtn.visible = false
                explorerBtn.visible = false
                practiceBtn.visible = false
                settingBtn.visible = false
                appName.visible = false
            }
        }

        Rectangle{
            id: burgerBtn
            width: 30
            height: 30
            color: "Black"
            anchors.top: sidebar.top
            anchors.left: sidebar.left
            anchors.leftMargin: 10
            anchors.topMargin: 10

            Text {
                id: appName
                text: "RADVIN"
                anchors.left: burgerBtn.right
                anchors.verticalCenter: burgerBtn.verticalCenter
                anchors.horizontalCenter: burgerBtn.horizontalCenter
                anchors.leftMargin: 25
                font.pointSize: 26
                font.bold: true
                visible: false
            }

            MouseArea{
                anchors.fill: parent
                onClicked : {
                    sidebar.toggleMenu()
                }
            }

        }

        Rectangle{
            id: queueBtn
            width: parent.width - 20
            height: 70
            color: "red"
            anchors.top: burgerBtn.bottom
            anchors.left: sidebar.left
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 25
            radius: 8
            visible: false

            Text {
                text: "Queue"
                color: "white"
                font.pointSize: 18
                anchors.centerIn: parent
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    screenLoader.source = "Queue.qml"
                    // Close the menu after selection
                    if(sidebar.width !== 50) {
                        sidebar.toggleMenu()
                    }
                }
            }
        }


        Rectangle{
            id: explorerBtn
            width: parent.width - 20
            height: 70
            color: "green"
            anchors.top: queueBtn.bottom
            anchors.left: sidebar.left
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 25
            radius: 8
            visible: false

            Text {
                text: "Explorer"
                color: "white"
                anchors.centerIn: parent
                font.pointSize: 18
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    screenLoader.source = "Explorer.qml"
                    // Close the menu after selection
                    if(sidebar.width !== 50) {
                        sidebar.toggleMenu()
                    }
                }
            }


        }

        Rectangle{
            id: practiceBtn
            width: parent.width - 20
            height: 70
            color: "lightgreen"
            anchors.top: explorerBtn.bottom
            anchors.left: sidebar.left
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 25
            radius: 8
            visible: false

            Text {
                text: "Practice"
                color: "Black"
                anchors.centerIn: parent
                font.pointSize: 18
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    screenLoader.source = "Practice.qml"
                    // Close the menu after selection
                    if(sidebar.width !== 50) {
                        sidebar.toggleMenu()
                    }
                }
            }
        }


        Rectangle{
            id: settingBtn
            width: parent.width - 20
            height: 70
            color: "Black"
            anchors.bottom: sidebar.bottom
            anchors.left: sidebar.left
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            anchors.topMargin: 25
            anchors.bottomMargin: 10
            radius: 8
            visible: false

            Text {
                text: "⚙️ Settings"
                color: "White"
                anchors.centerIn: parent
                font.pointSize: 18
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    screenLoader.source = "Settings.qml"
                    // Close the menu after selection
                    if(sidebar.width !== 50) {
                        sidebar.toggleMenu()
                    }
                }
            }
        }
    }


        Rectangle{
            id: mainScreen
            height: parent.height
            width: parent.width - 70
            // height: parent.height - 20
            color: "white"
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            // anchors.leftMargin: 10
            // anchors.rightMargin: 10
            // anchors.topMargin: 10
            // anchors.bottomMargin: 10
            radius: 8
            z: 1

            Loader {
                id: screenLoader
                anchors.right : parent.right
                asynchronous: true
                z: 2
            }
        }
}
