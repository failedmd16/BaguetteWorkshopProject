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
                        border.color: "#dce0e3"
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
                    placeholderText: "🔍 Поиск по номеру заказа или клиенту..."
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
            Layout.fillHeight: true
            color: "#ffffff"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1

            ScrollView {
                id: scrollView
                anchors.fill: parent
                clip: true

                ListView {
                    id: ordersListView
                    width: scrollView.width
                    height: contentHeight
                    clip: true
                    model: ordersModel
                    spacing: 1

                    header: Rectangle {
                        width: ordersListView.width
                        height: 50
                        color: "#3498db"
                        radius: 8

                        Row {
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 1

                            Repeater {
                                model: ["№ заказа", "Клиент", "Размер", "Статус", "Сумма", "Дата создания"]

                                Rectangle {
                                    width: ordersListView.width / 6
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

                    delegate: Rectangle {
                        width: ordersListView.width
                        height: 45
                        color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#e9ecef"

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

                            Rectangle {
                                width: ordersListView.width / 6
                                height: parent.height
                                color: "transparent"
                                Text {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: model && model.order_number ? model.order_number : ""
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: "#2c3e50"
                                    font.pixelSize: 13
                                }
                            }
                            Rectangle {
                                width: ordersListView.width / 6
                                height: parent.height
                                color: "transparent"
                                Text {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: model && model.customer_name ? model.customer_name : "Не указан"
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: "#2c3e50"
                                    font.pixelSize: 13
                                }
                            }
                            Rectangle {
                                width: ordersListView.width / 6
                                height: parent.height
                                color: "transparent"
                                Text {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: model && model.width && model.height ?
                                          (model.width + "x" + model.height + " см") : "Не указан"
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: "#2c3e50"
                                    font.pixelSize: 13
                                }
                            }
                            Rectangle {
                                width: ordersListView.width / 6
                                height: parent.height
                                color: "transparent"
                                Text {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: model && model.status ? model.status : ""
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: getStatusColor(model ? model.status : "")
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                            }
                            Rectangle {
                                width: ordersListView.width / 6
                                height: parent.height
                                color: "transparent"
                                Text {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: (model && model.total_amount ? model.total_amount : 0) + " ₽"
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: "#2c3e50"
                                    font.pixelSize: 13
                                }
                            }
                            Rectangle {
                                width: ordersListView.width / 6
                                height: parent.height
                                color: "transparent"
                                Text {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: formatDate(model ? model.created_at : "")
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
            text: "🔄 Обновить"
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

    ListModel {
        id: ordersModel
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

        var ordersData = dbmanager.getMasterOrdersData()
        if (!ordersData || ordersData.length === 0)
            return

        for (var i = 0; i < ordersData.length; i++) {
            var order = ordersData[i]

            if (!order)
                continue

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
                special_instructions: order.special_instructions || ""
            }

            ordersModel.append(orderData)
        }
    }

    Dialog {
        id: orderDetailsDialog
        modal: true
        title: "📋 Детали заказа"
        standardButtons: Dialog.NoButton

        property var currentData: ({})

        anchors.centerIn: parent
        width: 360
        height: 500

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e0e0e0"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: "👀 Просмотр заказа"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 15
                        rowSpacing: 10

                        Label {
                            text: "№ заказа:"
                            font.bold: true
                            color: "#34495e"
                            Layout.alignment: Qt.AlignRight
                            Layout.preferredWidth: 120
                        }
                        Label {
                            text: orderDetailsDialog.currentData && orderDetailsDialog.currentData.order_number ? orderDetailsDialog.currentData.order_number : "Не указан"
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft
                        }

                        Label {
                            text: "Клиент:"
                            font.bold: true
                            color: "#34495e"
                            Layout.alignment: Qt.AlignRight
                            Layout.preferredWidth: 120
                        }
                        Label {
                            text: orderDetailsDialog.currentData && orderDetailsDialog.currentData.customer_name ? orderDetailsDialog.currentData.customer_name : "Не указан"
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft
                        }

                        Label {
                            text: "Размер:"
                            font.bold: true
                            color: "#34495e"
                            Layout.alignment: Qt.AlignRight
                            Layout.preferredWidth: 120
                        }
                        Label {
                            text: (orderDetailsDialog.currentData && orderDetailsDialog.currentData.width && orderDetailsDialog.currentData.height) ?
                                  (orderDetailsDialog.currentData.width + "x" + orderDetailsDialog.currentData.height + " см") : "Не указан"
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft
                        }

                        Label {
                            text: "Сумма:"
                            font.bold: true
                            color: "#34495e"
                            Layout.alignment: Qt.AlignRight
                            Layout.preferredWidth: 120
                        }
                        Label {
                            text: ((orderDetailsDialog.currentData && orderDetailsDialog.currentData.total_amount) ? orderDetailsDialog.currentData.total_amount : 0) + " ₽"
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft
                        }

                        Label {
                            text: "Статус:"
                            font.bold: true
                            color: "#34495e"
                            Layout.alignment: Qt.AlignRight
                            Layout.preferredWidth: 120
                        }
                        Label {
                            text: orderDetailsDialog.currentData && orderDetailsDialog.currentData.status ? orderDetailsDialog.currentData.status : "Не указан"
                            color: getStatusColor(orderDetailsDialog.currentData && orderDetailsDialog.currentData.status ? orderDetailsDialog.currentData.status : "")
                            font.bold: true
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft
                        }

                        Label {
                            text: "Дата создания:"
                            font.bold: true
                            color: "#34495e"
                            Layout.alignment: Qt.AlignRight
                            Layout.preferredWidth: 120
                        }
                        Label {
                            text: formatDate(orderDetailsDialog.currentData && orderDetailsDialog.currentData.created_at ? orderDetailsDialog.currentData.created_at : "")
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignLeft
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        visible: orderDetailsDialog.currentData && orderDetailsDialog.currentData.special_instructions && orderDetailsDialog.currentData.special_instructions !== ""

                        Label {
                            text: "📝 Особые инструкции:"
                            font.bold: true
                            color: "#34495e"
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Label {
                            Layout.fillWidth: true
                            text: orderDetailsDialog.currentData && orderDetailsDialog.currentData.special_instructions ? orderDetailsDialog.currentData.special_instructions : ""
                            wrapMode: Text.Wrap
                            padding: 10
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 6
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: "🔄 Изменить статус:"
                            font.bold: true
                            color: "#34495e"
                            Layout.alignment: Qt.AlignHCenter
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
                            contentItem: Text {
                                text: statusComboBox.displayText
                                color: "#000000"
                                font: statusComboBox.font
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
                                elide: Text.ElideRight
                                leftPadding: 12
                            }
                        }

                        Button {
                            text: "💾 Сохранить статус"
                            font.bold: true
                            font.pixelSize: 14
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
                                if (orderDetailsDialog.currentData && orderDetailsDialog.currentData.id) {
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

            Button {
                Layout.alignment: Qt.AlignHCenter
                text: "❌ Закрыть"
                font.bold: true
                font.pixelSize: 14
                padding: 12
                Layout.preferredWidth: 120
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

        function openWithData(orderModel) {
            if (orderModel) {
                currentData = orderModel
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
        title: "✅ Статус обновлен"
        anchors.centerIn: parent
        width: 350
        height: 150

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            anchors.margins: 10

            Label {
                Layout.alignment: Qt.AlignCenter
                font.pixelSize: 14
                text: "Статус заказа успешно обновлен!"
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                color: "#27ae60"
                font.bold: true
            }

            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 10
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 40
                Layout.bottomMargin: 10

                text: "✅ OK"
                background: Rectangle {
                    color: parent.down ? "#27ae60" : "#2ecc71"
                    radius: 8
                    border.color: "#27ae60"
                    border.width: 1
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                onClicked: statusUpdatedMessage.accept()
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
