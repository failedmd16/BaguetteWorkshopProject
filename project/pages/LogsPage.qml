import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Database

Page {
    id: root
    property string tableName: "event_logs"
    property int selectedRow: -1

    // Свойства для асинхронности
    property int totalLogsCount: 0
    property bool isLoading: false

    Rectangle {
        anchors.fill: parent
        color: "#f8f9fa"
    }

    Component.onCompleted: {
        refreshTable()
    }

    // --- ЛОГИКА АСИНХРОННОСТИ ---

    // 1. Модель данных (теперь это ListModel, а не SQL)
    ListModel {
        id: logListModel
    }

    // 2. Обработка сигналов от C++
    Connections {
        target: DatabaseManager

        function onLogsLoaded(data) {
            logListModel.clear()
            // Заполняем модель данными из базы
            for (var i = 0; i < data.length; i++) {
                logListModel.append(data[i])
            }
            root.isLoading = false
        }

        function onLogsCountLoaded(count) {
            root.totalLogsCount = count
        }
    }

    // 3. Запуск обновления
    function refreshTable() {
        root.isLoading = true
        // Запускаем асинхронные методы
        DatabaseManager.fetchLogs()
        DatabaseManager.fetchLogsCount()
    }

    onVisibleChanged: {
        if (visible)
            refreshTable()
    }

    // --- Вспомогательные функции ---

    function formatDate(dateInput) {
        if (!dateInput) return ""
        var date
        if (dateInput instanceof Date) {
            date = dateInput
        } else {
            var safeDateString = String(dateInput).replace(" ", "T")
            date = new Date(safeDateString)
        }
        if (isNaN(date.getTime())) return String(dateInput)

        // Коррекция времени (-3 часа)
        date.setHours(date.getHours() - 3)

        return date.toLocaleString(Qt.locale("ru_RU"), "dd.MM.yyyy HH:mm:ss")
    }

    function isValidDate(dateString) {
        var regex = /^(\d{2})\.(\d{2})\.(\d{4})$/
        var match = dateString.match(regex)
        if (!match) return false
        var day = parseInt(match[1], 10)
        var month = parseInt(match[2], 10)
        if (month < 1 || month > 12) return false
        if (day < 1 || day > 31) return false
        return true
    }

    function convertToSqlDate(dateString) {
        var parts = dateString.split('.')
        if (parts.length !== 3) return dateString
        return parts[2] + '-' + parts[1] + '-' + parts[0]
    }

    function getCategoryColor(category) {
        if (!category) return "#2c3e50"
        var catUpper = category.toUpperCase()
        if (catUpper.includes("AUTH") || catUpper.includes("АВТОРИЗАЦИЯ")) return "#8e44ad"
        if (catUpper.includes("ERROR") || catUpper.includes("FAIL") || catUpper.includes("ОШИБКА")) return "#c0392b"
        if (catUpper.includes("USER") || catUpper.includes("ПОЛЬЗОВАТЕЛ")) return "#d35400"
        if (catUpper.includes("ORDER") || catUpper.includes("ЗАКАЗ")) return "#27ae60"
        if (catUpper.includes("SYS") || catUpper.includes("СИСТЕМ")) return "#7f8c8d"
        return "#2c3e50"
    }

    // --- Интерфейс ---

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // 1. Заголовок
        Label {
            Layout.fillWidth: true
            text: "📜 Журнал событий"
            font.bold: true
            font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter
            padding: 15
            color: "#2c3e50"
            background: Rectangle {
                color: "#ffffff"
                radius: 10
                border.color: "#e0e0e0"
                border.width: 1
            }
        }

        // 2. Панель фильтрации (Оформление из вашего примера)
        Rectangle {
            Layout.alignment: Qt.AlignLeft
            Layout.preferredHeight: 50
            color: "#ffffff"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1

            RowLayout {
                anchors.margins: 15
                spacing: 10
                anchors.centerIn: parent
                width: parent.width

                Label {
                    text: "Фильтр по периоду:"
                    font.bold: true
                    color: "#2c3e50"
                    font.pixelSize: 14
                }
                Label { text: "С:"; color: "#34495e"; font.bold: true }
                TextField {
                    id: startDateField
                    Layout.preferredWidth: 120
                    placeholderText: "дд.мм.гггг"
                    font.pixelSize: 14
                    padding: 10
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 8
                        border.color: startDateField.activeFocus ? "#3498db" : "#dce0e3"
                        border.width: 1
                    }
                }
                Label { text: "По:"; color: "#34495e"; font.bold: true }
                TextField {
                    id: endDateField
                    Layout.preferredWidth: 120
                    placeholderText: "дд.мм.гггг"
                    font.pixelSize: 14
                    padding: 10
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 8
                        border.color: endDateField.activeFocus ? "#3498db" : "#dce0e3"
                        border.width: 1
                    }
                }

                Button {
                    text: "Применить"
                    font.bold: true
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 140
                    font.pixelSize: 14
                    background: Rectangle { color: parent.down ? "#2980b9" : "#3498db"; radius: 8 }
                    contentItem: Text {
                        text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font
                    }
                    onClicked: {
                        if (startDateField.text && endDateField.text && isValidDate(startDateField.text) && isValidDate(endDateField.text)) {
                            // Включаем индикатор загрузки
                            root.isLoading = true

                            // Вызываем новый метод C++
                            DatabaseManager.fetchLogsByPeriod(startDateField.text, endDateField.text)

                        } else {
                            messageDialog.showError("Введите корректные даты (дд.мм.гггг)")
                        }
                    }
                }

                Button {
                    text: "Сбросить"
                    font.bold: true
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 120
                    font.pixelSize: 14
                    background: Rectangle { color: parent.down ? "#7f8c8d" : "#95a5a6"; radius: 8 }
                    contentItem: Text {
                        text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font
                    }
                    onClicked: {
                        var endDate = new Date()
                        var startDate = new Date()
                        startDate.setDate(startDate.getDate() - 30)

                        var formatInput = function(d) { return d.toLocaleDateString(Qt.locale("ru_RU"), "dd.MM.yyyy") }

                        startDateField.text = formatInput(startDate)
                        endDateField.text = formatInput(endDate)
                        refreshTable()
                    }
                }
            }
        }

        // 3. Шапка таблицы (Синяя)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#3498db"
            radius: 8

            Row {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 1
                property var colWeights: [0.15, 0.15, 0.15, 0.20, 0.35]

                Repeater {
                    model: ["Время", "Пользователь", "Категория", "Действие", "Описание"]
                    Rectangle {
                        width: tableview.width * parent.colWeights[index]
                        height: parent.height
                        color: "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: "white"
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }

        // 4. Таблица (Замена TableView на ListView для корректного отображения колонок)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#ffffff"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1
            clip: true

            // Индикатор загрузки
            BusyIndicator {
                anchors.centerIn: parent
                running: root.isLoading
                z: 10
            }

            ListView {
                id: tableview
                anchors.fill: parent
                clip: true

                // Модель данных
                model: logListModel

                // Настройки скроллбара
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AlwaysOn }

                // Внешний вид строки (делегат)
                delegate: Rectangle {
                    width: tableview.width // Строка на всю ширину
                    height: 45

                    // 'index' вместо 'row' в ListView
                    color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                    border.color: "#e9ecef"
                    border.width: 1 // Разделитель снизу

                    // Данные для диалога
                    property var rowData: {
                        "id": id, // В ListView можно обращаться к полям напрямую по имени
                        "timestamp": timestamp,
                        "user_login": user_login,
                        "category": category,
                        "action": action,
                        "description": description
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: logDetailsDialog.openWithData(parent.rowData)
                        // Подсветка при наведении
                        Rectangle { anchors.fill: parent; color: parent.containsMouse ? "#e3f2fd" : "transparent" }
                    }

                    // ВНУТРИ СТРОКИ РИСУЕМ КОЛОНКИ
                    Row {
                        anchors.fill: parent
                        // Те же веса, что и в шапке
                        property var colWeights: [0.15, 0.15, 0.15, 0.20, 0.35]

                        // Используем Repeater, чтобы создать 5 колонок, как было у вас
                        Repeater {
                            model: 5 // 5 колонок

                            Rectangle {
                                width: tableview.width * parent.colWeights[index]
                                height: parent.height
                                color: "transparent"

                                Text {
                                    anchors.fill: parent
                                    anchors.margins: 5
                                    verticalAlignment: Text.AlignVCenter
                                    elide: Text.ElideRight
                                    font.pixelSize: 13

                                    // Логика выбора текста в зависимости от номера колонки (index)
                                    text: {
                                        switch(index) {
                                            case 0: return formatDate(timestamp) // timestamp берется из модели
                                            case 1: return user_login || "System"
                                            case 2: return category || ""
                                            case 3: return action || ""
                                            case 4: return description || ""
                                            default: return ""
                                        }
                                    }

                                    // Логика цвета
                                    color: (index === 2 || index === 3) ? getCategoryColor(category) : "#2c3e50"
                                    font.bold: (index === 2 || index === 3)
                                }
                            }
                        }
                    }
                }
            }
        }

        Button {
            id: refreshButton
            text: root.isLoading ? "Загрузка..." : "Обновить"
            enabled: !root.isLoading
            Layout.alignment: Qt.AlignRight
            font.bold: true
            font.pixelSize: 14
            padding: 12
            Layout.preferredWidth: 120
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
            onClicked: refreshTable()
        }
    }

    Dialog {
        id: logDetailsDialog
        modal: true; header: null; width: 500; height: 400; anchors.centerIn: parent; padding: 20
        property var currentData: ({})
        background: Rectangle { color: "#ffffff"; radius: 12; border.color: "#e0e0e0"; border.width: 1 }

        ColumnLayout {
            anchors.fill: parent; spacing: 15
            Label { Layout.fillWidth: true; text: "Детали события"; font.bold: true; font.pixelSize: 18; color: "#2c3e50"; horizontalAlignment: Text.AlignHCenter }

            GridLayout {
                columns: 2; Layout.fillWidth: true; columnSpacing: 10; rowSpacing: 10
                Label { text: "ID:"; font.bold: true; color: "#7f8c8d"; font.pixelSize: 14 }
                Label { text: logDetailsDialog.currentData.id || "-"; font.pixelSize: 14 }
                Label { text: "Время:"; font.bold: true; color: "#7f8c8d"; font.pixelSize: 14 }
                Label { text: formatDate(logDetailsDialog.currentData.timestamp); font.pixelSize: 14 }
                Label { text: "Пользователь:"; font.bold: true; color: "#7f8c8d"; font.pixelSize: 14 }
                Label { text: logDetailsDialog.currentData.user_login || "System"; font.bold: true; font.pixelSize: 14 }
                Label { text: "Категория:"; font.bold: true; color: "#7f8c8d"; font.pixelSize: 14 }
                Label { text: logDetailsDialog.currentData.category || "-"; color: getCategoryColor(logDetailsDialog.currentData.category); font.bold: true; font.pixelSize: 14 }
                Label { text: "Действие:"; font.bold: true; color: "#7f8c8d"; font.pixelSize: 14 }
                Label { text: logDetailsDialog.currentData.action || "-"; font.pixelSize: 14 }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#e0e0e0" }
            Label { text: "Полное описание:"; font.bold: true; color: "#34495e"; font.pixelSize: 14 }

            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true
                TextArea {
                    readOnly: true
                    text: logDetailsDialog.currentData.description || ""
                    wrapMode: Text.Wrap
                    color: "#2c3e50"
                    font.pixelSize: 14
                    background: Rectangle { color: "#f8f9fa"; radius: 8; border.color: "#dce0e3" }
                }
            }

            Button {
                text: "Закрыть"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 40
                background: Rectangle { color: parent.down ? "#7f8c8d" : "#95a5a6"; radius: 8 }
                contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: logDetailsDialog.close()
            }
        }
        function openWithData(data) { currentData = data; open() }
    }

    // Диалог сообщений
    Dialog {
        id: messageDialog
        modal: true; header: null; width: 350; height: 180; anchors.centerIn: parent; padding: 20
        property string errorMsg: "Ошибка"
        background: Rectangle { color: "#ffffff"; radius: 12; border.color: "#e0e0e0"; border.width: 1 }

        ColumnLayout {
            anchors.fill: parent; spacing: 10
            Label { text: "Сообщение"; font.bold: true; font.pixelSize: 18; color: "#e74c3c"; Layout.alignment: Qt.AlignHCenter }
            Label { id: msgTextLabel; Layout.fillWidth: true; Layout.fillHeight: true; text: messageDialog.errorMsg; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.pixelSize: 14 }
            Button {
                text: "Закрыть"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 40

                // 1. Задаем настройки шрифта в самой кнопке
                font.bold: true
                font.pixelSize: 14

                background: Rectangle {
                    color: parent.down ? "#7f8c8d" : "#95a5a6"
                    radius: 8
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    // 2. В contentItem просто наследуем шрифт от кнопки
                    font: parent.font
                }
                onClicked: {
                    logDetailsDialog.close()
                    messageDialog.close()
                }
            }
        }
        function showError(msg) {
            errorMsg = msg
            msgTextLabel.text = msg
            open()
        }
    }
}
