import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    // These Layout properties are essential for the parent (Exploreprofile)
    // to stretch this panel to fill the remaining space.
    Layout.fillWidth: true
    Layout.fillHeight: true


    RowLayout {
        anchors.fill: parent
        spacing: 0

        Item{ width: 15 }



        // --- Flashcards ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
            Layout.preferredWidth: 1 // Force equal distribution

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50 // Fixed height for header
                color: "#eff2f5" // Light grey/blue background from image
                z: 30

                // Use RowLayout to align Icon and Text side-by-side
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 15
                    anchors.rightMargin: 15
                    spacing: 10

                    // Header Text
                    Text {
                        text: " 🎓️ Flash Card"
                        font.pixelSize: 16
                        font.bold: true
                        color: "black"
                        Layout.alignment: Qt.AlignVCenter // Centers text vertically
                    }

                    // Spacer to push everything else to the left
                    Item { Layout.fillWidth: true }
                }
            }

            // 1a. Top Section (50% relative height) flash card front
            // converted from Rectangle
            TextArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
                //color: "#e3f2fd" // Light Blue
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop

                padding: 10
                wrapMode: Text.Wrap
                clip: true
                background: Rectangle { // Optional: Visual border like TextField
                        border.color: parent.activeFocus ? "#2196F3" : "#EBEEF3"
                        bottomLeftRadius:  8
                        bottomRightRadius: 8
                        color: "transparent"
                        anchors.fill: parent

                        anchors.top: parent.top
                        anchors.topMargin: -1 // Hides top border (prev. trick)

                        anchors.bottom: parent.bottom
                        // anchors.bottomMargin: 0 // (Default is fine here)

                        anchors.left: parent.left
                        anchors.leftMargin: 1   // <--- Pushes in 2px from left

                        anchors.right: parent.right
                        anchors.rightMargin: 1  // <--- Pushes in 2px from right
                }
            }

            Item{ height: 20 }


            // 1b. Middle Section (50% relative height) flash card back
            // converted from Rectangle
            TextArea {
                Layout.fillWidth: true
                Layout.fillHeight: true
                //color: "#bbdefb" // Medium Blue
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignTop
                padding: 10
                wrapMode: Text.Wrap
                background: Rectangle { // Optional: Visual border like TextField
                        border.color: parent.activeFocus ? "#2196F3" : "#EBEEF3"
                        color: "transparent"
                        radius: 8
                }
            }

            Item{ height: 20 }


            // 1c. Bottom Bar (50px fixed height)  panel
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 50

                Button{
                    text: "Add Card"
                }

                Button{
                    text: "Cloze"
                }

                Button{
                    text: "Add Image"
                }
            }
        }

        Item{ width: 20 }

        // --- 2. Middle Column (50% relative width) ---
        RowLayout {
            Layout.preferredWidth: 1 // Force equal distribution

            // 1. Main Card Container (provides border and rounded corners)
            Rectangle {
                Layout.fillHeight: true
                        Layout.fillWidth: true
                radius: 8   // Rounded corners
                border.color: "#e0e0e0" // Thin light grey border
                border.width: 1
                clip: true // Ensures content doesn't spill out of rounded corners

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // --- Header Section ---
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50 // Fixed height for header
                        color: "#eff2f5" // Light grey/blue background from image

                        // Use RowLayout to align Icon and Text side-by-side
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            spacing: 10


                            // Header Text
                            Text {
                                text: " 🎓️ Prompts List"
                                font.pixelSize: 16
                                font.bold: true
                                color: "black"
                                Layout.alignment: Qt.AlignVCenter // Centers text vertically
                            }

                            // Spacer to push everything else to the left
                            Item { Layout.fillWidth: true }
                        }

                        // Small bottom border for the header to separate it from body
                        Rectangle {
                            width: parent.width; height: 1
                            color: "#e0e0e0"
                            anchors.bottom: parent.bottom
                        }
                    }

                    // --- Body Section ---
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "white"

                        Text {
                            text: "- Is this word concrete?\n\n- Other stupid questions to ask when you see a word you don't know."
                            color: "#202124" // Dark grey text
                            font.pixelSize: 16 // Bigger font
                            wrapMode: Text.Wrap // Wraps text to next line

                            // Alignment and Padding
                            anchors.fill: parent
                            anchors.margins: 20 // 20px padding on all sides
                            verticalAlignment: Text.AlignTop
                        }
                    }
                }
            }
        }

        Item{ width: 20 }


        // --- 3. Right Vertical Strip (50px fixed width) ---
        Rectangle {
            Layout.preferredWidth: 50
            Layout.fillHeight: true
            color: "#eff2f5" // Medium Purple
            Text {
                anchors.centerIn: parent;
                text: "Vert";
                rotation: 90
            }
        }
    }
}
