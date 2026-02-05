import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true

    property int currentSection: 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        ScrollView {
            id: scrollView
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                id: content
                width: scrollView.width
                spacing: 20

                // Table 3: Word Profile (Deductive)
                RobustTable {
                    width: parent.width - 32
                    tableColumns: [
                        { role: "category", label: "Feature" },
                        { role: "details", label: "Description" }
                    ]
                    tableModel: [
                        { category: "Part of Speech", details: "Adjective" },
                        { category: "Noun Form", details: "Deduction" },
                        { category: "Verb Form", details: "Deduce" },
                        { category: "Register", details: "Formal / Academic" },
                        { category: "Meaning", details: "Relating to the inference of particular instances from a general law." }
                    ]
                }

                // Table 1: Word Collocations
                RobustTable {
                    width: parent.width - 32
                    tableColumns: [
                        { role: "collocation", label: "Common Collocations" }
                    ]
                    tableModel: [
                        { collocation: "Deductive reasoning" },
                        { collocation: "Inductive approach" },
                        { collocation: "Deductive logic" },
                        { collocation: "Inductive method" }
                    ]
                }

                // Table 2: Example Sentences
                RobustTable {
                    width: parent.width - 32
                    tableColumns: [
                        { role: "sentence", label: "Example Sentences" }
                    ]
                    tableModel: [
                        { sentence: "The detective used a deductive process to identify the suspect from the available evidence." },
                        { sentence: "In a deductive argument, if the premises are true, the conclusion must also be true." },
                        { sentence: "Mathematical proofs are primarily deductive in nature." }
                    ]
                }



                // Table 4: Key Contrasts (Additional)
                RobustTable {
                    width: parent.width - 32
                    tableColumns: [
                        { role: "type", label: "Type" },
                        { role: "direction", label: "Direction of Thought" }
                    ]
                    tableModel: [
                        { type: "Deductive", direction: "Top-down (General to Specific)" },
                        { type: "Inductive", direction: "Bottom-up (Specific to General)" }
                    ]
                }
            }
        }
    }

    property var sectionPositions: []

    Component.onCompleted: {
        sectionPositions = content.children
    }
}


