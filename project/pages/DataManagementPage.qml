import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import Database

Page {
    id: root
    property bool isLoading: false
    property var chartData: []
    property double maxRevenue: 1.0

    Rectangle {
        anchors.fill: parent
        color: "#f8f9fa"
    }

    MouseArea {
        anchors.fill: parent
        visible: root.isLoading
        hoverEnabled: true
        z: 99
        onClicked: {}
        BusyIndicator {
            anchors.centerIn: parent
            running: root.isLoading
        }
    }

    Connections {
        target: DatabaseManager

        function onStatisticsLoaded(data) {
            root.chartData = data
            var max = 0
            for(var i=0; i<data.length; i++) {
                if(data[i].revenue > max)
                    max = data[i].revenue
            }
            root.maxRevenue = max > 0 ? max : 1
            if (chartCanvas.available)
                chartCanvas.requestPaint()
            root.isLoading = false
        }

        function onOperationResult(success, message) {
            if (!root.visible) return

            root.isLoading = false
            messageDialog.show(success ? "Успешно" : "Ошибка", message)
        }
    }

    Component.onCompleted: {
        root.isLoading = true
        if (DatabaseManager && DatabaseManager.fetchStatisticsAsync)
            DatabaseManager.fetchStatisticsAsync(30)
    }

    // ScrollView убран, ColumnLayout теперь прямой потомок Page
    ColumnLayout {
        id: mainLayout
        // Ширина теперь привязана к ширине страницы
        width: parent.width - 40
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        spacing: 20

        Label {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            text: "📊 Управление данными"
            font.bold: true
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: "#2c3e50"

            background: Rectangle {
                color: "#ffffff"
                radius: 10
                border.color: "#e0e0e0"
                border.width: 1
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 400
            color: "#ffffff"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        text: "Статистика продаж (30 дней)"
                        font.bold: true
                        font.pixelSize: 16
                        color: "black"
                        Layout.fillWidth: true
                    }
                    Button {
                        text: "Сохранить график"
                        font.bold: true
                        font.pixelSize: 13
                        Layout.preferredHeight: 35
                        Layout.preferredWidth: 160
                        background: Rectangle {
                            color: parent.down ? "#2980b9" : "#3498db"
                            radius: 8
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font: parent.font
                        }
                        onClicked: chartExportDialog.open()
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Canvas {
                        id: chartCanvas
                        anchors.fill: parent
                        antialiasing: true
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d")
                            var w = width
                            var h = height
                            ctx.clearRect(0, 0, w, h)

                            if (root.chartData.length === 0) {
                                ctx.fillStyle = "#7f8c8d"
                                ctx.font = "14px sans-serif"
                                ctx.textAlign = "center"
                                ctx.fillText("Нет данных за выбранный период", w/2, h/2)
                                return
                            }

                            var paddingBottom = 30
                            var paddingTop = 30
                            var maxH = h - paddingBottom

                            var barWidth = (w / root.chartData.length) - 10
                            if (barWidth > 80) barWidth = 80

                            var totalChartWidth = root.chartData.length * (barWidth + 10)
                            var startX = (w - totalChartWidth) / 2 + 5

                            for (var i = 0; i < root.chartData.length; i++) {
                                var item = root.chartData[i]
                                var ratio = root.maxRevenue > 0 ? (item.revenue / root.maxRevenue) : 0
                                var barHeight = ratio * (maxH - paddingTop)

                                if (barHeight < 1 && item.count > 0) barHeight = 2

                                var x = startX + i * (barWidth + 10)
                                var y = maxH - barHeight

                                var gradient = ctx.createLinearGradient(x, y, x, maxH)
                                gradient.addColorStop(0, "#3498db")
                                gradient.addColorStop(1, "#2980b9")
                                ctx.fillStyle = gradient

                                ctx.fillRect(x, y, barWidth, barHeight)

                                ctx.fillStyle = "#2c3e50"
                                ctx.textAlign = "center"

                                var label = item.count + " (" + item.revenue + " ₽)"

                                ctx.font = barWidth < 60 ? "bold 10px sans-serif" : "bold 12px sans-serif"

                                ctx.fillText(label, x + barWidth/2, y - 5)

                                ctx.fillStyle = "#7f8c8d"
                                ctx.font = "11px sans-serif"
                                if (root.chartData.length <= 15 || i % 2 === 0) {
                                    ctx.fillText(item.date, x + barWidth/2, h - 10)
                                }
                            }

                            ctx.beginPath()
                            ctx.strokeStyle = "#bdc3c7"
                            ctx.lineWidth = 1
                            ctx.moveTo(0, maxH)
                            ctx.lineTo(w, maxH)
                            ctx.stroke()
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 200
            Layout.bottomMargin: 60

            color: "#ffffff"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Label {
                    text: "Управление базой данных"
                    font.bold: true
                    font.pixelSize: 16
                    color: "black"
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 30

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        spacing: 10

                        Label {
                            text: "1. Работа с таблицами (CSV)"
                            font.bold: true
                            color: "black"
                            font.pixelSize: 14
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Label {
                                text: "Таблица:"
                                color: "black"
                                font.pixelSize: 14
                            }
                            ComboBox {
                                id: tableSelector
                                Layout.fillWidth: true
                                model: ["orders", "customers", "frame_materials", "component_furniture", "embroidery_kits", "users"]
                                font.pixelSize: 14
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                    border.color: tableSelector.activeFocus ? "#3498db" : "#bdc3c7"
                                    border.width: 1
                                }
                                contentItem: Text {
                                    text: tableSelector.displayText
                                    color: "#2c3e50"
                                    font: tableSelector.font
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 10
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Button {
                                text: "Экспорт"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                font.bold: true
                                font.pixelSize: 13
                                background: Rectangle {
                                    color: parent.down ? "#219150" : "#27ae60"
                                    radius: 8
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font: parent.font
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: fileExportDialog.open()
                            }

                            Button {
                                text: "Импорт"
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                font.bold: true
                                font.pixelSize: 13
                                background: Rectangle {
                                    color: parent.down ? "#d35400" : "#e67e22"
                                    radius: 8
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font: parent.font
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: fileImportDialog.open()
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        color: "#e0e0e0"
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        spacing: 10

                        Label {
                            text: "2. Резервное копирование"
                            font.bold: true
                            color: "#c0392b"
                            font.pixelSize: 14
                        }

                        Item { Layout.fillHeight: true }

                        Button {
                            text: "Восстановить из дампа"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            font.bold: true
                            font.pixelSize: 13
                            background: Rectangle {
                                color: parent.down ? "#219150" : "#27ae60"
                                radius: 8
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                font: parent.font
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: restoreDialog.open()
                        }

                        Button {
                            text: "Создать дамп"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            font.bold: true
                            font.pixelSize: 13
                            background: Rectangle {
                                color: parent.down ? "#d35400" : "#e67e22"
                                radius: 8
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                font: parent.font
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            onClicked: backupDialog.open()
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: chartExportDialog
        title: "Сохранить график"
        currentFolder: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0]
        fileMode: FileDialog.SaveFile
        nameFilters: ["PNG Image (*.png)"]
        onAccepted: {
            if (chartCanvas.available) {
                chartCanvas.grabToImage(function(result) {
                    var path = selectedFile.toString()

                    if (Qt.platform.os !== "windows")
                        path = path.replace("file://", "")
                    else
                        path = path.replace("file:///", "")

                    result.saveToFile(path)
                    messageDialog.show("Успешно", "График сохранен")
                })
            }
        }
    }

    FileDialog {
        id: fileExportDialog
        title: "Экспорт таблицы в CSV"
        fileMode: FileDialog.SaveFile
        nameFilters: ["CSV Files (*.csv)"]
        onAccepted: {
            root.isLoading = true
            var path = selectedFile.toString()

            if (Qt.platform.os !== "windows")
                path = path.replace("file://", "")
            else
                path = path.replace("file:///", "")

            DatabaseManager.exportTableAsync(tableSelector.currentText, path)
        }
    }

    FileDialog {
        id: fileImportDialog
        title: "Импорт таблицы из CSV"
        fileMode: FileDialog.OpenFile
        nameFilters: ["CSV Files (*.csv)"]
        onAccepted: {
            root.isLoading = true
            var path = selectedFile.toString()

            if (Qt.platform.os !== "windows")
                path = path.replace("file://", "")
            else
                path = path.replace("file:///", "")

            DatabaseManager.importTableAsync(tableSelector.currentText, path)
        }
    }

    FileDialog {
        id: backupDialog
        title: "Сохранить резервную копию БД"
        fileMode: FileDialog.SaveFile
        nameFilters: ["SQL Backup (*.sql)", "All Files (*)"]
        onAccepted: {
            root.isLoading = true
            var path = selectedFile.toString()

            if (Qt.platform.os !== "windows")
                path = path.replace("file://", "")
            else
                path = path.replace("file:///", "")

            DatabaseManager.createBackupAsync(path)
        }
    }

    FileDialog {
        id: restoreDialog
        title: "Выберите файл бэкапа для восстановления"
        fileMode: FileDialog.OpenFile
        nameFilters: ["SQL Backup (*.sql)", "All Files (*)"]
        onAccepted: {
            root.isLoading = true
            var path = selectedFile.toString()

            if (Qt.platform.os !== "windows")
                path = path.replace("file://", "")
            else
                path = path.replace("file:///", "")

            if (DatabaseManager.restoreFromBackupAsync) {
                DatabaseManager.restoreFromBackupAsync(path)
            } else {
                console.error("Method restoreFromBackupAsync not found!")
                root.isLoading = false
            }
        }
    }

    Dialog {
        id: messageDialog
        property string msgTitle: ""
        property string msgText: ""
        modal: true
        width: 350
        height: 220
        anchors.centerIn: parent
        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }
        ColumnLayout {
            anchors.fill: parent
            spacing: 15
            Label {
                text: messageDialog.msgTitle
                font.bold: true
                font.pixelSize: 18
                color: messageDialog.msgTitle === "Ошибка" ? "#c0392b" : "#27ae60"
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 15
            }
            Label {
                text: messageDialog.msgText
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                font.pixelSize: 14
                color: "#2c3e50"
                Layout.margins: 10
            }

            Item { Layout.fillHeight: true }

            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 100
                Layout.preferredHeight: 35
                Layout.bottomMargin: 15
                background: Rectangle {
                    color: parent.down ? "#7f8c8d" : "#95a5a6"
                    radius: 8
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                onClicked: messageDialog.close()
            }
        }
        function show(t, txt) {
            msgTitle = t
            msgText = txt
            open()
        }
    }
}
