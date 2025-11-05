import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import databasemanager

Page {
    id: root
    property string tableName: "orders"
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
            text: "📦 Управление заказами"
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
                    model: ["Все статусы", "Новый", "В работе", "Готов", "Завершён", "Отменён"]

                    contentItem: Text {
                        text: statusFilter.displayText
                        color: "#000000"
                        font: statusFilter.font
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                        leftPadding: 12
                    }

                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: "#dce0e3"
                    }

                    delegate: ItemDelegate {
                        width: statusFilter.width
                        contentItem: Text {
                            text: modelData
                            color: "#000000"
                            font: statusFilter.font
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.highlighted ? "#e3f2fd" : "transparent"
                        }
                    }

                    onCurrentTextChanged: refreshTable()
                }

                ComboBox {
                    id: typeFilter
                    Layout.preferredWidth: 180
                    model: ["Все типы", "Изготовление рамки", "Продажа набора"]

                    contentItem: Text {
                        text: typeFilter.displayText
                        color: "#000000"
                        font: typeFilter.font
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                        leftPadding: 12
                    }

                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: "#dce0e3"
                    }

                    delegate: ItemDelegate {
                        width: typeFilter.width
                        contentItem: Text {
                            text: modelData
                            color: "#000000"
                            font: typeFilter.font
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.highlighted ? "#e3f2fd" : "transparent"
                        }
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
                    model: ["№ заказа", "Клиент", "Тип", "Статус", "Сумма", "Дата создания"]

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
                                    case 2: return parent.rowData.order_type || ""
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

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            Button {
                id: newOrderButton
                text: "➕ Новый заказ"
                font.bold: true
                font.pixelSize: 14
                padding: 12
                Layout.preferredWidth: 150
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

                onClicked: orderAddDialog.open()
            }

            Button {
                id: refreshButton
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
    }

    ListModel {
        id: ordersModel
    }

    ListModel {
        id: customersModel
    }

    ListModel {
        id: kitsModel
    }

    function formatDate(dateString) {
        if (!dateString) return "Не указана"
        var date = new Date(dateString)
        if (isNaN(date.getTime())) return "Неверная дата"
        return date.toLocaleDateString(Qt.locale("ru_RU"), "dd.MM.yyyy") + " " +
               date.toLocaleTimeString(Qt.locale("ru_RU"), "HH:mm")
    }

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

    function refreshTable() {
        ordersModel.clear()
        var ordersData = dbmanager.getOrdersData()

        for (var i = 0; i < ordersData.length; i++) {
            var orderData = ordersData[i]

            var statusFilterText = statusFilter.currentText
            var typeFilterText = typeFilter.currentText
            var searchText = searchField.text.toLowerCase().trim()

            if (statusFilterText !== "Все статусы" && orderData.status !== statusFilterText) continue
            if (typeFilterText !== "Все типы" && orderData.order_type !== typeFilterText) continue

            if (searchText) {
                var orderNumber = (orderData.order_number || "").toLowerCase()
                var customerName = (orderData.customer_name || "").toLowerCase()

                if (!orderNumber.includes(searchText) && !customerName.includes(searchText)) {
                    continue
                }
            }

            ordersModel.append(orderData)
        }
    }

    function toggleOrderTypeFields() {
        frameOrderFields.visible = orderTypeComboBox.currentText === "Изготовление рамки"
        kitOrderFields.visible = orderTypeComboBox.currentText === "Продажа набора"
        calculateTotal()
    }

    function loadCustomerInfo() {
        if (customerComboBox.currentIndex >= 0) {
            var customerData = customersModel.get(customerComboBox.currentIndex)
            customerPhoneLabel.text = "Телефон: " + (customerData.phone || "Не указан")
            customerEmailLabel.text = "Email: " + (customerData.email || "Не указан")
        }
    }

    function calculateKitTotal() {
        if (kitComboBox.currentIndex >= 0) {
            var kitData = kitsModel.get(kitComboBox.currentIndex)
            var price = kitData.price || 0
            kitPriceLabel.text = price + " ₽"
            calculateTotal()
        } else {
            kitPriceLabel.text = "0 ₽"
        }
    }

    function calculateTotal() {
        var total = 0

        if (orderTypeComboBox.currentText === "Продажа набора" && kitComboBox.currentIndex >= 0) {
            var kitData = kitsModel.get(kitComboBox.currentIndex)
            var quantity = parseInt(kitQuantityField.text) || 1
            var price = kitData.price || 0
            total = quantity * price
        } else if (orderTypeComboBox.currentText === "Изготовление рамки") {
            var width = parseFloat(frameWidthField.text) || 0
            var height = parseFloat(frameHeightField.text) || 0
            if (width > 0 && height > 0) {
                var area = (width * height) / 10000
                total = (area * 1000) + 500
            }
        }

        calculatedAmountLabel.text = "Расчетная сумма: " + total.toFixed(2) + " ₽"
        calculatedAmountLabel.visible = total > 0
        totalAmountField.text = total > 0 ? total.toFixed(2) : ""
    }

    function updateCalculatedAmount() {
        var manualAmount = parseFloat(totalAmountField.text) || 0
        calculatedAmountLabel.visible = false
    }

    function validateForm() {
        var errors = []

        if (customerComboBox.currentIndex === -1)
            errors.push("• Выберите клиента из списка")

        if (!totalAmountField.text || parseFloat(totalAmountField.text) <= 0)
            errors.push("• Введите корректную сумму заказа")

        if (orderTypeComboBox.currentText === "Изготовление рамки") {
            if (!frameWidthField.text || parseFloat(frameWidthField.text) <= 0)
                errors.push("• Введите корректную ширину рамки")
            if (!frameHeightField.text || parseFloat(frameHeightField.text) <= 0)
                errors.push("• Введите корректную высоту рамки")
        } else if (orderTypeComboBox.currentText === "Продажа набора") {
            if (kitComboBox.currentIndex === -1)
                errors.push("• Выберите набор для продажи")
            if (!kitQuantityField.text || parseInt(kitQuantityField.text) <= 0)
                errors.push("• Введите корректное количество")
        }

        if (errors.length > 0) {
            addOrderValidationError.text = errors.join("\n")
            addOrderValidationError.visible = true
            return false
        }

        addOrderValidationError.visible = false
        return true
    }

    function createOrder() {
        if (!validateForm()) return

        var orderNumber = "ORD-" + new Date().getTime()
        var orderType = orderTypeComboBox.currentText
        var totalAmount = parseFloat(totalAmountField.text)
        var customerId = customersModel.get(customerComboBox.currentIndex).id

        var success = dbmanager.createOrder(orderNumber, customerId, orderType, totalAmount, "Новый", notesField.text)

        if (success) {
            var orderId = dbmanager.getLastInsertedOrderId()

            if (orderType === "Изготовление рамки") {
                var width = parseFloat(frameWidthField.text)
                var height = parseFloat(frameHeightField.text)
                dbmanager.createFrameOrder(orderId, width, height, 1, 1, notesField.text)
            } else {
                var kitData = kitsModel.get(kitComboBox.currentIndex)
                var quantity = parseInt(kitQuantityField.text)
                dbmanager.createOrderItem(orderId, kitData.id, "Готовый набор", quantity, kitData.price)
            }

            orderAddDialog.close()
            refreshTable()
            orderCreatedMessage.open()
        } else {
            addOrderValidationError.text = "Ошибка при создании заказа в базе данных"
            addOrderValidationError.visible = true
        }
    }

    Dialog {
        id: orderAddDialog
        modal: true
        title: "📦 Создание нового заказа"

        width: 600
        height: 700
        anchors.centerIn: parent

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e0e0e0"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Label {
                Layout.fillWidth: true
                text: "📝 Создание нового заказа"
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
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.maximumWidth: 500
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Label {
                                text: "👤 Выберите клиента:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }

                            ComboBox {
                                id: customerComboBox
                                Layout.fillWidth: true
                                model: customersModel
                                textRole: "display"

                                contentItem: Text {
                                    text: customerComboBox.displayText
                                    color: "#000000"
                                    font: customerComboBox.font
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                    leftPadding: 12
                                }

                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                    border.color: customerComboBox.activeFocus ? "#3498db" : "#dce0e3"
                                }

                                delegate: ItemDelegate {
                                    width: customerComboBox.width
                                    contentItem: Text {
                                        text: model.display
                                        color: "#000000"
                                        font: customerComboBox.font
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        color: parent.highlighted ? "#e3f2fd" : "transparent"
                                    }
                                }

                                onActivated: loadCustomerInfo()
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: customerComboBox.currentIndex >= 0

                            Label {
                                text: "📞 Контактная информация:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                id: customerPhoneLabel
                                Layout.fillWidth: true
                                text: "Телефон: Не выбран"
                                color: "#7f8c8d"
                                font.pixelSize: 12
                                padding: 8
                                horizontalAlignment: Text.AlignHCenter
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                }
                            }

                            Label {
                                id: customerEmailLabel
                                Layout.fillWidth: true
                                text: "Email: Не выбран"
                                color: "#7f8c8d"
                                font.pixelSize: 12
                                padding: 8
                                horizontalAlignment: Text.AlignHCenter
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Label {
                                text: "🔧 Тип заказа:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }

                            ComboBox {
                                id: orderTypeComboBox
                                Layout.fillWidth: true
                                model: ["Изготовление рамки", "Продажа набора"]

                                contentItem: Text {
                                    text: orderTypeComboBox.displayText
                                    color: "#000000"
                                    font: orderTypeComboBox.font
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                    leftPadding: 12
                                }

                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                    border.color: orderTypeComboBox.activeFocus ? "#3498db" : "#dce0e3"
                                }

                                delegate: ItemDelegate {
                                    width: orderTypeComboBox.width
                                    contentItem: Text {
                                        text: modelData
                                        color: "#000000"
                                        font: orderTypeComboBox.font
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        color: parent.highlighted ? "#e3f2fd" : "transparent"
                                    }
                                }

                                onCurrentTextChanged: toggleOrderTypeFields()
                            }
                        }

                        ColumnLayout {
                            id: frameOrderFields
                            Layout.fillWidth: true
                            spacing: 6
                            visible: orderTypeComboBox.currentText === "Изготовление рамки"

                            Label {
                                text: "📐 Размеры рамки:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Label {
                                        text: "Ширина (см):"
                                        font.bold: true
                                        color: "#34495e"
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    TextField {
                                        id: frameWidthField
                                        Layout.fillWidth: true
                                        placeholderText: "0.0"
                                        validator: DoubleValidator { bottom: 0.1; top: 1000.0 }
                                        horizontalAlignment: Text.AlignHCenter
                                        background: Rectangle {
                                            color: "#f8f9fa"
                                            radius: 6
                                            border.color: frameWidthField.activeFocus ? "#3498db" : "#dce0e3"
                                        }
                                        onTextChanged: calculateTotal()
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Label {
                                        text: "Высота (см):"
                                        font.bold: true
                                        color: "#34495e"
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    TextField {
                                        id: frameHeightField
                                        Layout.fillWidth: true
                                        placeholderText: "0.0"
                                        validator: DoubleValidator { bottom: 0.1; top: 1000.0 }
                                        horizontalAlignment: Text.AlignHCenter
                                        background: Rectangle {
                                            color: "#f8f9fa"
                                            radius: 6
                                            border.color: frameHeightField.activeFocus ? "#3498db" : "#dce0e3"
                                        }
                                        onTextChanged: calculateTotal()
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            id: kitOrderFields
                            Layout.fillWidth: true
                            spacing: 6
                            visible: orderTypeComboBox.currentText === "Продажа набора"

                            Label {
                                text: "🎨 Выбор набора:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }

                            ComboBox {
                                id: kitComboBox
                                Layout.fillWidth: true
                                model: kitsModel
                                textRole: "display"

                                contentItem: Text {
                                    text: kitComboBox.displayText
                                    color: "#000000"
                                    font: kitComboBox.font
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignLeft
                                    elide: Text.ElideRight
                                    leftPadding: 12
                                }

                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                    border.color: kitComboBox.activeFocus ? "#3498db" : "#dce0e3"
                                }

                                delegate: ItemDelegate {
                                    width: kitComboBox.width
                                    contentItem: Text {
                                        text: model.display
                                        color: "#000000"
                                        font: kitComboBox.font
                                        elide: Text.ElideRight
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    background: Rectangle {
                                        color: parent.highlighted ? "#e3f2fd" : "transparent"
                                    }
                                }

                                onActivated: calculateKitTotal()
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Label {
                                        text: "Количество:"
                                        font.bold: true
                                        color: "#34495e"
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    TextField {
                                        id: kitQuantityField
                                        Layout.fillWidth: true
                                        placeholderText: "1"
                                        validator: IntValidator { bottom: 1; top: 1000 }
                                        text: "1"
                                        horizontalAlignment: Text.AlignHCenter
                                        background: Rectangle {
                                            color: "#f8f9fa"
                                            radius: 6
                                            border.color: kitQuantityField.activeFocus ? "#3498db" : "#dce0e3"
                                        }
                                        onTextChanged: calculateKitTotal()
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Label {
                                        text: "Цена за шт:"
                                        font.bold: true
                                        color: "#34495e"
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter
                                    }
                                    Label {
                                        id: kitPriceLabel
                                        Layout.fillWidth: true
                                        text: "0 ₽"
                                        color: "#2c3e50"
                                        font.pixelSize: 12
                                        padding: 8
                                        horizontalAlignment: Text.AlignHCenter
                                        background: Rectangle {
                                            color: "#f8f9fa"
                                            radius: 6
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Label {
                                text: "💰 Сумма заказа:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                TextField {
                                    id: totalAmountField
                                    Layout.fillWidth: true
                                    placeholderText: "0.00"
                                    validator: DoubleValidator { bottom: 0.01; top: 1000000.0 }
                                    horizontalAlignment: Text.AlignHCenter
                                    background: Rectangle {
                                        color: "#f8f9fa"
                                        radius: 6
                                        border.color: totalAmountField.activeFocus ? "#3498db" : "#dce0e3"
                                    }
                                    onTextChanged: updateCalculatedAmount()
                                }

                                Button {
                                    text: "📊 Рассчитать"
                                    font.bold: true
                                    padding: 8
                                    background: Rectangle {
                                        color: parent.down ? "#2980b9" : "#3498db"
                                        radius: 6
                                    }
                                    contentItem: Text {
                                        text: parent.text
                                        color: "white"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font: parent.font
                                    }
                                    onClicked: calculateTotal()
                                }
                            }

                            Label {
                                id: calculatedAmountLabel
                                Layout.fillWidth: true
                                text: "Расчетная сумма: 0 ₽"
                                color: "#27ae60"
                                font.pixelSize: 12
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                visible: false
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Label {
                                text: "📝 Примечания к заказу:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }
                            TextArea {
                                id: notesField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 80
                                placeholderText: "Дополнительные примечания, особые пожелания клиента..."
                                wrapMode: TextArea.Wrap
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                    border.color: notesField.activeFocus ? "#3498db" : "#dce0e3"
                                }
                            }
                        }

                        Label {
                            id: addOrderValidationError
                            Layout.fillWidth: true
                            Layout.preferredHeight: addOrderValidationError.visible ? implicitHeight : 0
                            color: "#e74c3c"
                            visible: false
                            wrapMode: Text.WordWrap
                            font.pixelSize: 12
                            padding: 8
                            horizontalAlignment: Text.AlignHCenter
                            background: Rectangle {
                                color: "#fdf2f2"
                                radius: 6
                                border.color: "#e74c3c"
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
                text: "❌ Отмена"
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
                onClicked: orderAddDialog.reject()
            }

            Button {
                text: "✅ Создать заказ"
                font.bold: true
                padding: 12
                width: 140
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
                onClicked: createOrder()
            }
        }

        onOpened: {
            loadCustomers()
            loadKits()
            customerComboBox.currentIndex = -1
            kitComboBox.currentIndex = -1
            orderTypeComboBox.currentIndex = 0
            totalAmountField.text = ""
            frameWidthField.text = ""
            frameHeightField.text = ""
            kitQuantityField.text = "1"
            notesField.text = ""
            addOrderValidationError.visible = false
            calculatedAmountLabel.visible = false
            customerPhoneLabel.text = "Телефон: Не выбран"
            customerEmailLabel.text = "Email: Не выбран"
            kitPriceLabel.text = "0 ₽"
            toggleOrderTypeFields()
        }
    }

    function loadCustomers() {
        customersModel.clear()
        var model = dbmanager.getCustomersModel()
        for (var i = 0; i < model.rowCount(); i++) {
            customersModel.append({
                display: model.data(model.index(i, 1)),
                id: model.data(model.index(i, 0)),
                phone: model.data(model.index(i, 2)),
                email: model.data(model.index(i, 3))
            })
        }
    }

    function loadKits() {
        kitsModel.clear()
        var model = dbmanager.getEmbroideryKitsModel()
        for (var i = 0; i < model.rowCount(); i++) {
            kitsModel.append({
                display: model.data(model.index(i, 1)) + " - " + model.data(model.index(i, 2)) + " ₽",
                id: model.data(model.index(i, 0)),
                name: model.data(model.index(i, 1)),
                price: model.data(model.index(i, 2))
            })
        }
    }

    Dialog {
        id: orderCreatedMessage
        modal: true
        title: "✅ Заказ создан"
        width: 300
        height: 150
        anchors.centerIn: parent

        Label {
            anchors.centerIn: parent
            text: "Заказ успешно создан!"
            font.bold: true
            color: "#27ae60"
        }

        standardButtons: Dialog.Ok
    }

    Dialog {
        id: orderDetailsDialog
        modal: true
        title: "📦 Детали заказа"

        property int currentRow: -1
        property var currentData: ({})

        width: Math.min(600, parent.width * 0.9)
        height: Math.min(500, parent.height * 0.9)
        anchors.centerIn: parent

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
                text: "📦 Детали заказа"
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

                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.maximumWidth: 500
                        spacing: 10

                        Label {
                            Layout.fillWidth: true
                            text: "Информация о заказе будет отображена здесь"
                            horizontalAlignment: Text.AlignHCenter
                            color: "#7f8c8d"
                            font.italic: true
                        }
                    }
                }
            }
        }

        footer: DialogButtonBox {
            alignment: Qt.AlignCenter
            padding: 15

            Button {
                text: "❌ Закрыть"
                font.bold: true
                onClicked: orderDetailsDialog.close()
            }
        }

        function openWithData(row) {
            currentRow = row
            open()
        }
    }

    Component.onCompleted: {
        refreshTable()
        loadCustomers()
        loadKits()
    }

    onVisibleChanged: {
        if (visible) refreshTable()
    }
}
