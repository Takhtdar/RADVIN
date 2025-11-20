import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    width: mainScreen.width
    height: mainScreen.height
    z: 3
    id: explorer
    property var previousState: null
    property var processingStates: ({})


    Component.onCompleted: {
        const savedView = settings.getValue("explorerView", "List")
        setCurrentView(savedView)
    }

    function setCurrentView(viewName) {
        let fileMap = {
            "List": "ExploreSentences.qml",
            "Grid": "ExploreWords.qml",
        }

        if (fileMap[viewName]) {
            loader.source = fileMap[viewName]
        } else {
            loader.source = "" // or a default
        }
    }

    function openProfile(itemId, type) {
        loader.setSource("ExploreProfile.qml", {
            profileId: itemId,
            profileType: type,
            parentExplorer: explorer
        })
    }

    RowLayout {
        id: explorerNavbar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: explorerNavbar.visible ? 50 : 0
        z: 10
        visible: true


        Item {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            width: 0
        }

        ComboBox {
            id: filterOptions
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 160
            textRole: "display"
            enabled: false
            model: [
                { display: "select a filter" },
                { display: "Nouns" },
                { display: "Verbs" },
                { display: "Idioms" },
            ]

            onCurrentIndexChanged: {
                if (currentIndex >= 0) {
                    // const selected = model[currentIndex].display
                    // settings.setValue("explorerView", selected)
                    // setCurrentView(selected)
                }
            }
        }

        ComboBox {
            id: viewOptions
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 160
            Layout.rightMargin: 10
            textRole: "display"

            model: [
                { display: "List" },
                { display: "Grid" }
            ]

            onCurrentIndexChanged: {
                if (currentIndex >= 0) {
                    const selected = model[currentIndex].display
                    settings.setValue("explorerView", selected)
                    setCurrentView(selected)
                }


            }
        }
    }

    Loader {
        id: loader
        Layout.fillWidth: true
        Layout.fillHeight: true
        anchors.top: explorerNavbar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin: 5
        clip: true
    }
}
