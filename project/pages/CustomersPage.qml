import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import databasemanager

Page {
    id: root
    property string tableName: "customers" // Название таблицы, которая должна выводиться в TableView

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        DatabaseManager {
            id: dbmanager
        }

        Label {
            Layout.fillWidth: true
            text: "Таблица покупателей"
            font.bold: true
            font.pixelSize: 16
            horizontalAlignment: Text.AlignHCenter
            padding: 10
        }
        Row {
            Layout.fillWidth: true
            height: 40

            Repeater {
                model: tableview.columns

                Rectangle {
                    width: tableview.width / tableview.columns
                    height: parent.height
                    color: "#2196F3"

                    Text {
                        anchors.fill: parent
                        anchors.margins: 5
                        text: dbmanager.getColumnName(root.tableName, modelData) // использование метода для получения имен столбцов
                        color: "white"
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.visible: false


            TableView {
                id: tableview
                anchors.fill: parent
                clip: true
                columnSpacing: 1
                rowSpacing: 1
                model: dbmanager.getTableModel(root.tableName) // получение данных из модели при помощи метода

                columnWidthProvider: function(column) { // распредеделение размеров столбцов
                    var colCount = tableview.columns > 0 ? tableview.columns : 1
                    return tableview.width / colCount
                }

                delegate: Rectangle {
                    implicitHeight: 35
                    color: row % 2 === 0 ? "#FFFFFF" : "#F5F5F5"
                    border.color: "#E0E0E0"

                    Text {
                        anchors.fill: parent
                        anchors.margins: 5
                        text: model.display
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Button {
            Layout.alignment: Qt.AlignRight
            anchors.margins: 15
            text: "Добавить"
        }
    }

    // обновляем модель при каждом показе страницы
    onVisibleChanged: {
        tableview.model = dbmanager.getTableModel(root.tableName)
    }
}
