import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Database

Page {
    id: root
    property int selectedRow: -1

    Rectangle {
        anchors.fill: parent
        color: "#f8f9fa"
    }

    function getStatusColor(status) {
        if (!status) return "#7f8c8d"
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
        if (isNaN(date.getTime())) return "Неверная дата"

        var day = date.getDate().toString().padStart(2, '0')
        var month = (date.getMonth() + 1).toString().padStart(2, '0')
        var year = date.getFullYear()
        var hours = date.getHours().toString().padStart(2, '0')
        var minutes = date.getMinutes().toString().padStart(2, '0')

        return day + "." + month + "." + year + " " + hours + ":" + minutes
    }

    function refreshTable() {
        ordersModel.clear()

        var ordersData = DatabaseManager.getMasterOrdersData()
        if (!ordersData || ordersData.length === 0)
            return

        for (var i = 0; i < ordersData.length; i++) {
            var order = ordersData[i]

            if (!order) continue

            var statusFilterText = statusFilter.currentText
            var searchText = searchField.text.toLowerCase()

            if (statusFilterText !== "Все статусы" && order.status !== statusFilterText)
                continue

            var orderNumber = order.order_number ? order.order_number.toLowerCase() : ""
            var customerName = order.customer_name ? order.customer_name.toLowerCase() : ""

            if (searchText && !orderNumber.includes(searchText) && !customerName.includes(searchText))
                continue

            var orderData = {
                id: order.id || 0,
                order_number: order.order_number || "",
                order_type: order.order_type || "",
                status: order.status || "",
                total_amount: order.total_amount || 0,
                created_at: order.created_at || "",
                customer_name: order.customer_name || "Не указан",
                width: order.width || 0,
                height: order.height || 0,
                special_instructions: order.special_instructions || "",
                material_name: order.material_name || "Неизвестный материал",
                material_color: order.material_color || "Не указан"
            }
            ordersModel.append(orderData)
        }
    }

    ListModel {
        id: ordersModel
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

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
                    font.pixelSize: 14
                    model: ["Все статусы", "Новый", "В работе", "Готов", "Завершён", "Отменён"]

                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: statusFilter.activeFocus ? "#3498db" : "#dce0e3"
                    }
                    contentItem: Text {
                        text: statusFilter.displayText
                        color: "#000000"
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
                    placeholderText: "Поиск по номеру заказа или клиенту..."
                    font.pixelSize: 14
                    color: "#000000"
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: searchField.activeFocus ? "#3498db" : "#dce0e3"
                    }
                    onTextChanged: refreshTable()
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

                Repeater {
                    model: ["№ заказа", "Клиент", "Размер", "Статус", "Сумма", "Дата"]

                    Rectangle {
                        width: (parent.width - 5) / 6
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

            ScrollView {
                id: scrollView
                anchors.fill: parent
                anchors.margins: 2
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ListView {
                    id: ordersListView
                    anchors.fill: parent
                    clip: true
                    model: ordersModel
                    spacing: 0

                    delegate: Rectangle {
                        width: ordersListView.width
                        height: 45
                        color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#e9ecef"
                        border.width: 1
                        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: index === 0 ? "transparent" : "#e9ecef"; visible: false }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedRow = index
                                if (model) {
                                    orderDetailsDialog.openWithData(model)
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                color: parent.containsMouse ? "#e3f2fd" : "transparent"
                            }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 1
                            property int colWidth: (parent.width - 5) / 6

                            Rectangle {
                                width: parent.colWidth; height: parent.height; color: "transparent"
                                Text {
                                    anchors.fill: parent; anchors.margins: 5
                                    text: model.order_number
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: "#2c3e50"
                                    font.pixelSize: 13
                                }
                            }
                            Rectangle {
                                width: parent.colWidth; height: parent.height; color: "transparent"
                                Text {
                                    anchors.fill: parent; anchors.margins: 5
                                    text: model.customer_name
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: "#2c3e50"
                                    font.pixelSize: 13
                                }
                            }
                            Rectangle {
                                width: parent.colWidth; height: parent.height; color: "transparent"
                                Text {
                                    anchors.fill: parent; anchors.margins: 5
                                    text: (model.width && model.height) ? (model.width + "x" + model.height + " см") : "—"
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: "#2c3e50"
                                    font.pixelSize: 13
                                }
                            }
                            Rectangle {
                                width: parent.colWidth; height: parent.height; color: "transparent"
                                Text {
                                    anchors.fill: parent; anchors.margins: 5
                                    text: model.status
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: getStatusColor(model.status)
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }
                            Rectangle {
                                width: parent.colWidth; height: parent.height; color: "transparent"
                                Text {
                                    anchors.fill: parent; anchors.margins: 5
                                    text: model.total_amount + " ₽"
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: "#2c3e50"
                                    font.pixelSize: 13
                                }
                            }
                            Rectangle {
                                width: parent.colWidth; height: parent.height; color: "transparent"
                                Text {
                                    anchors.fill: parent; anchors.margins: 5
                                    text: formatDate(model.created_at)
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: "#2c3e50"
                                    font.pixelSize: 13
                                }
                            }
                        }
                    }
                }
            }
        }

        Button {
            Layout.alignment: Qt.AlignRight
            text: "Обновить"
            font.pixelSize: 14
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


    Dialog {
        id: orderDetailsDialog
        modal: true
        header: null
        width: 450
        height: 600
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
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: "Карточка заказа (Мастерская)"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignTop
            }

            Item {
                Layout.fillHeight: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                spacing: 20

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: infoCol.implicitHeight + 30
                    color: "#f8f9fa"
                    radius: 10
                    border.color: "#ecf0f1"

                    ColumnLayout {
                        id: infoCol
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 12

                        component DetailRow: RowLayout {
                            property string labelText
                            property string valueText
                            property color valueColor: "#2c3e50"
                            property bool isBold: false

                            Layout.fillWidth: true
                            Label {
                                text: labelText
                                font.bold: true
                                color: "#7f8c8d"
                                Layout.preferredWidth: 110
                                font.pixelSize: 14
                            }
                            Label {
                                text: valueText
                                color: valueColor
                                font.bold: isBold
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                font.pixelSize: 14
                            }
                        }

                        DetailRow {
                            labelText: "№ заказа:"
                            valueText: orderDetailsDialog.currentData.order_number || "—"
                        }
                        DetailRow {
                            labelText: "Клиент:"
                            valueText: orderDetailsDialog.currentData.customer_name || "—"
                        }
                        DetailRow {
                            labelText: "Размер:"
                            valueText: (orderDetailsDialog.currentData.width && orderDetailsDialog.currentData.height) ?
                                       (orderDetailsDialog.currentData.width + "x" + orderDetailsDialog.currentData.height + " см") : "—"
                        }
                        DetailRow {
                            labelText: "Материал:"
                            valueText: (orderDetailsDialog.currentData.material_name || "Не указан") +
                                       " (" + (orderDetailsDialog.currentData.material_color || "—") + ")"
                            valueColor: "#d35400"
                            isBold: true
                        }
                        DetailRow {
                            labelText: "Сумма:"
                            valueText: (orderDetailsDialog.currentData.total_amount || 0) + " ₽"
                        }
                        DetailRow {
                            labelText: "Дата:"
                            valueText: formatDate(orderDetailsDialog.currentData.created_at)
                        }
                        DetailRow {
                            labelText: "Текущий статус:"
                            valueText: orderDetailsDialog.currentData.status || "—"
                            valueColor: getStatusColor(orderDetailsDialog.currentData.status)
                            isBold: true
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    visible: {
                        if (!orderDetailsDialog.currentData) return false
                        if (!orderDetailsDialog.currentData.special_instructions) return false
                        return orderDetailsDialog.currentData.special_instructions !== ""
                    }

                    Label {
                        text: "⚠️ Особые инструкции:"
                        font.bold: true
                        color: "#e74c3c"
                        font.pixelSize: 14
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: instructionsText.implicitHeight + 20
                        color: "#fff3cd"
                        radius: 6
                        border.color: "#ffeeba"

                        Text {
                            id: instructionsText
                            anchors.fill: parent
                            anchors.margins: 10
                            text: orderDetailsDialog.currentData.special_instructions || ""
                            wrapMode: Text.Wrap
                            color: "#856404"
                            font.pixelSize: 13
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#e0e0e0"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Layout.alignment: Qt.AlignHCenter

                    Label {
                        text: "Обновить статус работы:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                    }

                    ComboBox {
                        id: statusComboBox
                        Layout.preferredWidth: 250
                        Layout.alignment: Qt.AlignHCenter
                        model: ["Новый", "В работе", "Готов", "Завершён", "Отменён"]

                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: statusComboBox.activeFocus ? "#3498db" : "#bdc3c7"
                            border.width: 1
                        }
                        contentItem: Text {
                            text: statusComboBox.displayText
                            color: "#000000"
                            font: statusComboBox.font
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            leftPadding: 12
                        }
                    }

                    Button {
                        text: "Сохранить новый статус"
                        font.bold: true
                        font.pixelSize: 14
                        Layout.preferredWidth: 250
                        Layout.preferredHeight: 40
                        Layout.alignment: Qt.AlignHCenter
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
                            if (orderDetailsDialog.currentData && orderDetailsDialog.currentData.id) {
                                if (DatabaseManager.updateOrderStatus(orderDetailsDialog.currentData.id, statusComboBox.currentText)) {
                                    refreshTable()
                                    orderDetailsDialog.close()
                                    statusUpdatedMessage.open()
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            Button {
                text: "Закрыть"
                Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom
                Layout.preferredWidth: 120
                Layout.preferredHeight: 35
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
                onClicked: orderDetailsDialog.close()
            }
        }

        function openWithData(orderModel) {
            if (orderModel) {
                currentData = {
                    id: orderModel.id,
                    order_number: orderModel.order_number,
                    customer_name: orderModel.customer_name,
                    width: orderModel.width,
                    height: orderModel.height,
                    material_name: orderModel.material_name,
                    material_color: orderModel.material_color,
                    total_amount: orderModel.total_amount,
                    status: orderModel.status,
                    created_at: orderModel.created_at,
                    special_instructions: orderModel.special_instructions
                }

                if (currentData.status) {
                    var index = statusComboBox.model.indexOf(currentData.status)
                    if (index >= 0) {
                        statusComboBox.currentIndex = index
                    } else {
                        statusComboBox.currentIndex = 0
                    }
                } else {
                    statusComboBox.currentIndex = 0
                }
            } else {
                currentData = {}
                statusComboBox.currentIndex = 0
            }
            open()
        }
    }

    Dialog {
        id: statusUpdatedMessage
        modal: true
        header: null
        width: 300
        height: 150
        anchors.centerIn: parent
        padding: 20

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
                text: "Успешно"
                font.bold: true
                font.pixelSize: 18
                color: "#27ae60"
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                text: "Статус заказа обновлен!"
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                color: "#2c3e50"
                Layout.fillWidth: true
            }

            Item { Layout.fillHeight: true }

            Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 100
                Layout.preferredHeight: 35

                text: "OK"
                background: Rectangle {
                    color: parent.down ? "#27ae60" : "#2ecc71"
                    radius: 8
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                onClicked: statusUpdatedMessage.close()
            }
        }
    }

    Component.onCompleted: {
        refreshTable()
    }

    onVisibleChanged: {
        if (visible) {
            refreshTable()
        }
    }
}
