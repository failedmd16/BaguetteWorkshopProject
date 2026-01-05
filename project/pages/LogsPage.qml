import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Database

Page {
    id: root
    property string tableName: "event_logs"
    property int selectedRow: -1

    property int totalLogsCount: 0
    property bool isLoading: false

    Rectangle {
        anchors.fill: parent
        color: "#f8f9fa"
    }

    Component.onCompleted: {
        refreshTable()
    }

    ListModel {
        id: logListModel
    }

    Shortcut {
        sequence: "F5"
        enabled: root.visible && !root.isLoading
        onActivated: refreshTable()
    }

    Shortcut {
        sequence: "Esc"
        enabled: root.visible
        onActivated: {
            if (logDetailsDialog.opened)
                logDetailsDialog.close()
            else if (messageDialog.opened)
                messageDialog.close()
        }
    }

    Connections {
        target: DatabaseManager

        function onLogsLoaded(data) {
            logListModel.clear()
            for (var i = 0; i < data.length; i++)
                logListModel.append(data[i])
            root.isLoading = false
        }

        function onLogsCountLoaded(count) {
            root.totalLogsCount = count
        }
    }

    function refreshTable() {
        root.isLoading = true

        DatabaseManager.fetchLogs()
        DatabaseManager.fetchLogsCount()
    }

    onVisibleChanged: {
        if (visible) {
            forceActiveFocus()
            refreshTable()
        }
    }

    function formatDate(dateInput) {
        if (!dateInput)
            return ""

        var date

        if (dateInput instanceof Date) {
            date = dateInput
        } else {
            var safeDateString = String(dateInput).replace(" ", "T")
            date = new Date(safeDateString)
        }

        if (isNaN(date.getTime()))
            return String(dateInput)

        date.setHours(date.getHours() - 3)

        return date.toLocaleString(Qt.locale("ru_RU"), "dd.MM.yyyy HH:mm:ss")
    }

    function isValidDate(dateString) {
        var regex = /^(\d{2})\.(\d{2})\.(\d{4})$/
        var match = dateString.match(regex)

        if (!match)
            return false

        var day = parseInt(match[1], 10)
        var month = parseInt(match[2], 10)

        if (month < 1 || month > 12)
            return false

        if (day < 1 || day > 31)
            return false

        return true
    }

    function convertToSqlDate(dateString) {
        var parts = dateString.split('.')

        if (parts.length !== 3)
            return dateString

        return parts[2] + '-' + parts[1] + '-' + parts[0]
    }

    function getCategoryColor(category) {
        if (!category)
            return "#2c3e50"
        var catUpper = category.toUpperCase()

        if (catUpper.includes("AUTH") || catUpper.includes("АВТОРИЗАЦИЯ"))
            return "#8e44ad"
        if (catUpper.includes("ERROR") || catUpper.includes("FAIL") || catUpper.includes("ОШИБКА"))
            return "#c0392b"
        if (catUpper.includes("USER") || catUpper.includes("ПОЛЬЗОВАТЕЛ"))
            return "#d35400"
        if (catUpper.includes("ORDER") || catUpper.includes("ЗАКАЗ"))
            return "#27ae60"
        if (catUpper.includes("SYS") || catUpper.includes("СИСТЕМ"))
            return "#7f8c8d"

        return "#2c3e50"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#ffffff"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1

            RowLayout {
                anchors.margins: 10
                spacing: 20
                anchors.centerIn: parent
                anchors.fill: parent

                Label {
                    text: "Фильтр по периоду:"
                    font.bold: true
                    color: "#2c3e50"
                    font.pixelSize: 14
                }
                Label {
                    text: "С:"
                    color: "#34495e"
                    font.bold: true
                }
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
                Label { text: "По:"
                    color: "#34495e"
                    font.bold: true
                }
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
                    Layout.preferredWidth: 140
                    font.pixelSize: 14
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

                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Найти логи за указанный период")

                    onClicked: {
                        if (startDateField.text && endDateField.text && isValidDate(startDateField.text) && isValidDate(endDateField.text)) {
                            root.isLoading = true
                            DatabaseManager.fetchLogsByPeriod(startDateField.text, endDateField.text)
                        } else {
                            messageDialog.showError("Введите корректные даты для фильтрации (дд.мм.гг)")
                        }
                    }
                }

                Button {
                    text: "Сбросить"
                    font.bold: true
                    Layout.preferredWidth: 120
                    font.pixelSize: 14
                    background: Rectangle {color: parent.down ? "#7f8c8d" : "#95a5a6"
                        radius: 8
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font: parent.font
                    }

                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Сбросить даты и обновить таблицу")

                    onClicked: {
                        startDateField.text = ""
                        endDateField.text = ""
                        root.isLoading = true
                        refreshTable()
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
            }
        }

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

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#ffffff"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1
            clip: true

            BusyIndicator {
                anchors.centerIn: parent
                running: root.isLoading
                z: 10
            }

            ListView {
                id: tableview
                anchors.fill: parent
                clip: true

                model: logListModel

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AlwaysOn
                }

                delegate: Rectangle {
                    width: tableview.width
                    height: 45

                    color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                    border.color: "#e9ecef"
                    border.width: 1

                    property var rowData: {
                        "id": id,
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

                        Rectangle {
                            anchors.fill: parent
                            color: parent.containsMouse ? "#e3f2fd" : "transparent"
                        }
                    }

                    Row {
                        anchors.fill: parent
                        property var colWeights: [0.15, 0.15, 0.15, 0.20, 0.35]

                        Repeater {
                            model: 5

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

                                    text: {
                                        switch(index) {
                                            case 0: return formatDate(timestamp)
                                            case 1: return user_login || "System"
                                            case 2: return category || ""
                                            case 3: return action || ""
                                            case 4: return description || ""
                                            default: return ""
                                        }
                                    }

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

            ToolTip.delay: 1000
            ToolTip.timeout: 5000
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Обновить таблицу")
            onClicked: refreshTable()
        }
    }

    Dialog {
        id: logDetailsDialog
        modal: true
        header: null
        width: 500
        height: 400
        anchors.centerIn: parent
        padding: 20

        property var currentData: ({})

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
                Layout.fillWidth: true
                text: "Детали события"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
            }

            GridLayout {
                columns: 2
                Layout.fillWidth: true
                columnSpacing: 10
                rowSpacing: 10

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

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#e0e0e0"
            }
            Label {
                text: "Полное описание:"
                font.bold: true
                color: "#34495e"
                font.pixelSize: 14
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                TextArea {
                    readOnly: true
                    text: logDetailsDialog.currentData.description || ""
                    wrapMode: Text.Wrap
                    color: "#2c3e50"
                    font.pixelSize: 14
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 8
                        border.color: "#dce0e3"
                    }
                }
            }

            Button {
                text: "Закрыть"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 40
                background: Rectangle {
                    color: parent.down ? "#7f8c8d" : "#95a5a6"
                    radius: 8
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: logDetailsDialog.close()
            }
        }
        function openWithData(data) {
            currentData = data
            open()
        }
    }

    Dialog {
        id: messageDialog
        modal: true
        header: null
        width: 350
        height: 180
        anchors.centerIn: parent
        padding: 20
        property string errorMsg: "Ошибка"
        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            Label {
                text: "Ошибка"
                font.bold: true
                font.pixelSize: 18
                color: "#e74c3c"
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                id: msgTextLabel
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: messageDialog.errorMsg
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 14
            }
            Button {
                text: "Закрыть"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 40

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
