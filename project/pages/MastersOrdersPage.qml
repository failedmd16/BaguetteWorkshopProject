import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import databasemanager

Page {
    id: root
    property int selectedRow: -1

    Rectangle {
        anchors.fill: parent
        color: "#f8f9fa"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        DatabaseManager {
            id: dbmanager
        }

        Label {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            text: "🔧 Заказы на изготовление"
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

        // Фильтры
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#ffffff"
            radius: 10
            border.color: "#e0e0e0"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                ComboBox {
                    id: statusFilter
                    Layout.preferredWidth: 200
                    model: ["Все статусы", "Новый", "В работе", "Готов", "Завершён", "Отменён"]
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: "#dce0e3"
                    }
                    contentItem: Text {
                        text: statusFilter.displayText
                        color: "#2c3e50"
                        font: statusFilter.font
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                        leftPadding: 12
                    }
                    onCurrentTextChanged: refreshTable()
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "🔍 Поиск по номеру заказа или клиенту..."
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: searchField.activeFocus ? "#3498db" : "#dce0e3"
                    }
                    onTextChanged: refreshTable()
                }
            }
        }

        // Заголовки таблицы
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#3498db"
            radius: 8

            Row {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 1

                Repeater {
                    model: ["№ заказа", "Клиент", "Размер", "Статус", "Сумма", "Дата создания"]

                    Rectangle {
                        width: tableview.width / 6
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

        // Таблица заказов
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#ffffff"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1

            ScrollView {
                anchors.fill: parent
                anchors.margins: 2
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                TableView {
                    id: tableview
                    anchors.fill: parent
                    clip: true
                    model: ordersModel

                    columnWidthProvider: function(column) {
                        return tableview.width / 6
                    }

                    delegate: Rectangle {
                        implicitHeight: 45
                        color: row % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#e9ecef"

                        property var rowData: ordersModel.get(row)

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedRow = row
                                orderDetailsDialog.openWithData(row)
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: parent.containsMouse ? "#e3f2fd" : "transparent"
                            }
                        }

                        Text {
                            anchors.fill: parent
                            anchors.margins: 12
                            text: {
                                if (!parent.rowData) return ""

                                switch(column) {
                                    case 0: return parent.rowData.order_number || ""
                                    case 1: return parent.rowData.customer_name || ""
                                    case 2: return (parent.rowData.width || 0) + "x" + (parent.rowData.height || 0) + " см"
                                    case 3: return parent.rowData.status || ""
                                    case 4: return (parent.rowData.total_amount || 0) + " ₽"
                                    case 5: return formatDate(parent.rowData.created_at)
                                    default: return ""
                                }
                            }
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            elide: Text.ElideRight
                            color: column === 3 ? getStatusColor(parent.rowData.status) : "#2c3e50"
                            font.pixelSize: 13
                            font.bold: column === 3
                        }
                    }
                }
            }
        }

        // Кнопка обновления
        Button {
            Layout.alignment: Qt.AlignRight
            text: "🔄 Обновить"
            font.bold: true
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

    ListModel {
        id: ordersModel
    }

    // Функции для работы с данными
    function getStatusColor(status) {
        switch(status) {
            case 'Новый': return "#3498db"
            case 'В работе': return "#f39c12"
            case 'Готов': return "#27ae60"
            case 'Завершён': return "#2ecc71"
            case 'Отменён': return "#e74c3c"
            default: return "#7f8c8d"
        }
    }

    function formatDate(dateString) {
        if (!dateString) return "Не указана"
        var date = new Date(dateString)
        return date.toLocaleDateString(Qt.locale(), "dd.MM.yyyy HH:mm")
    }

    function refreshTable() {
        ordersModel.clear()

        // Получаем данные через отдельную функцию в DatabaseManager
        var ordersData = dbmanager.getOrdersData()
        if (!ordersData || ordersData.length === 0) {
            console.log("No orders data received")
            return
        }

        console.log("Received orders data:", ordersData.length, "items")

        for (var i = 0; i < ordersData.length; i++) {
            var order = ordersData[i]

            // Фильтруем только заказы на изготовление рамок
            if (order.order_type !== "Изготовление рамки") continue

            // Применяем фильтры
            var statusFilterText = statusFilter.currentText
            var searchText = searchField.text.toLowerCase()

            if (statusFilterText !== "Все статусы" && order.status !== statusFilterText) continue
            if (searchText && !order.order_number.toLowerCase().includes(searchText) &&
                !order.customer_name.toLowerCase().includes(searchText)) continue

            // Получаем детали заказа рамки
            var frameDetails = dbmanager.getOrderDetails(order.id)

            var orderData = {
                id: order.id,
                order_number: order.order_number,
                order_type: order.order_type,
                status: order.status,
                total_amount: order.total_amount,
                created_at: order.created_at,
                customer_name: order.customer_name,
                width: frameDetails.width || 0,
                height: frameDetails.height || 0,
                special_instructions: frameDetails.special_instructions || ""
            }

            console.log("Adding order:", orderData.order_number)
            ordersModel.append(orderData)
        }

        console.log("Table refreshed, total items:", ordersModel.count)
    }

    // Диалог деталей заказа
    Dialog {
        id: orderDetailsDialog
        modal: true
        title: "📋 Детали заказа"

        property int currentRow: -1
        property var currentData: ({})

        width: 700
        height: 600
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e0e0e0"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Label {
                Layout.fillWidth: true
                text: "👀 Просмотр заказа"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    // Основная информация
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 15
                        rowSpacing: 10

                        Label { text: "№ заказа:"; font.bold: true; color: "#34495e" }
                        Label { text: orderDetailsDialog.currentData.order_number || "Не указан"; Layout.fillWidth: true }

                        Label { text: "Клиент:"; font.bold: true; color: "#34495e" }
                        Label { text: orderDetailsDialog.currentData.customer_name || "Не указан"; Layout.fillWidth: true }

                        Label { text: "Размер:"; font.bold: true; color: "#34495e" }
                        Label { text: (orderDetailsDialog.currentData.width || 0) + "x" + (orderDetailsDialog.currentData.height || 0) + " см"; Layout.fillWidth: true }

                        Label { text: "Сумма:"; font.bold: true; color: "#34495e" }
                        Label { text: (orderDetailsDialog.currentData.total_amount || 0) + " ₽"; Layout.fillWidth: true }

                        Label { text: "Статус:"; font.bold: true; color: "#34495e" }
                        Label {
                            text: orderDetailsDialog.currentData.status || "Не указан"
                            color: getStatusColor(orderDetailsDialog.currentData.status)
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        Label { text: "Дата создания:"; font.bold: true; color: "#34495e" }
                        Label { text: formatDate(orderDetailsDialog.currentData.created_at); Layout.fillWidth: true }
                    }

                    // Особые инструкции
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        visible: orderDetailsDialog.currentData.special_instructions

                        Label {
                            text: "📝 Особые инструкции:"
                            font.bold: true
                            color: "#34495e"
                        }
                        Label {
                            Layout.fillWidth: true
                            text: orderDetailsDialog.currentData.special_instructions || ""
                            wrapMode: Text.Wrap
                            padding: 10
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 6
                            }
                        }
                    }

                    // Смена статуса
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: "🔄 Изменить статус:"
                            font.bold: true
                            color: "#34495e"
                        }

                        ComboBox {
                            id: statusComboBox
                            Layout.fillWidth: true
                            model: ["Новый", "В работе", "Готов", "Завершён", "Отменён"]
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 6
                                border.color: statusComboBox.activeFocus ? "#3498db" : "#dce0e3"
                            }
                        }

                        Button {
                            text: "💾 Сохранить статус"
                            font.bold: true
                            Layout.fillWidth: true
                            background: Rectangle {
                                color: parent.down ? "#27ae60" : "#2ecc71"
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
                                if (dbmanager.updateOrderStatus(orderDetailsDialog.currentData.id, statusComboBox.currentText)) {
                                    refreshTable()
                                    orderDetailsDialog.close()
                                    statusUpdatedMessage.open()
                                }
                            }
                        }
                    }
                }
            }
        }

        footer: DialogButtonBox {
            alignment: Qt.AlignCenter
            padding: 15
            background: Rectangle {
                color: "transparent"
            }

            Button {
                text: "❌ Закрыть"
                font.bold: true
                padding: 12
                width: 120
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
                onClicked: orderDetailsDialog.close()
            }
        }

        function openWithData(row) {
            currentRow = row
            currentData = ordersModel.get(row)

            // Устанавливаем текущий статус в комбобокс
            if (currentData.status) {
                statusComboBox.currentIndex = statusComboBox.model.indexOf(currentData.status)
            }
            open()
        }
    }

    // Сообщение об успешном обновлении статуса
    Dialog {
        id: statusUpdatedMessage
        modal: true
        title: "✅ Статус обновлен"
        width: 300
        height: 150
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        Label {
            anchors.centerIn: parent
            text: "Статус заказа успешно обновлен!"
            font.bold: true
            color: "#27ae60"
        }

        standardButtons: Dialog.Ok
    }

    Component.onCompleted: {
        console.log("MastersOrdersPage component completed")
        refreshTable()
    }

    onVisibleChanged: {
        if (visible) {
            console.log("MastersOrdersPage became visible")
            refreshTable()
        }
    }
}
