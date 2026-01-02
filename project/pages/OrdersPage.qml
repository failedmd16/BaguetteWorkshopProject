import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Database

Page {
    id: root
    property string tableName: "orders"
    property int selectedRow: -1
    property bool isLoading: false

    // Хранилище всех заказов для локальной фильтрации
    property var allOrders: []

    Rectangle {
        anchors.fill: parent
        color: "#f8f9fa"
    }

    // Индикатор загрузки
    MouseArea {
        anchors.fill: parent; visible: root.isLoading; hoverEnabled: true; z: 99
        onClicked: {}
        BusyIndicator { anchors.centerIn: parent; running: root.isLoading }
    }

    // --- МОДЕЛИ ---
    ListModel { id: ordersModel }
    ListModel { id: customersModel }
    ListModel { id: kitsModel }
    ListModel { id: frameMaterialsModel }
    ListModel { id: mastersModel }

    Component.onCompleted: {
        root.isLoading = true
        // Запускаем параллельную загрузку
        DatabaseManager.fetchOrders()
        DatabaseManager.fetchReferenceData()
    }

    onVisibleChanged: {
        if (visible) {
            root.isLoading = true
            DatabaseManager.fetchOrders()
        }
    }

    // --- СВЯЗЬ С C++ ---
    Connections {
        target: DatabaseManager

        // 1. Загрузка списка заказов
        function onOrdersLoaded(data) {
            root.allOrders = data // Сохраняем "сырые" данные
            applyFilters() // Применяем фильтры и заполняем модель
            root.isLoading = false
        }

        // 2. Загрузка справочников (одним пакетом)
        function onReferenceDataLoaded(data) {
            // Клиенты
            customersModel.clear()
            var custs = data["customers"] || []
            for(var i=0; i<custs.length; i++) customersModel.append(custs[i])

            // Наборы
            kitsModel.clear()
            var kits = data["kits"] || []
            for(var j=0; j<kits.length; j++) kitsModel.append(kits[j])

            // Материалы
            frameMaterialsModel.clear()
            var mats = data["materials"] || []
            for(var k=0; k<mats.length; k++) frameMaterialsModel.append(mats[k])

            // Мастера
            mastersModel.clear()
            mastersModel.append({id: -1, display: "Не назначен"})
            var mas = data["masters"] || []
            for(var m=0; m<mas.length; m++) mastersModel.append(mas[m])
        }

        // 3. Результат операций
        function onOrderOperationResult(success, message) {
            root.isLoading = false
            if(success) {
                // Закрываем диалоги и обновляем таблицу
                if(orderAddDialog.opened) {
                    orderAddDialog.close()
                    orderCreatedMessage.open()
                }
                if(orderEditDialog.opened) orderEditDialog.close()
                if(deleteConfirmDialog.opened) deleteConfirmDialog.close()
                if(orderDetailsDialog.opened && deleteConfirmDialog.opened) orderDetailsDialog.close()

                // Обновляем список
                DatabaseManager.fetchOrders()
            } else {
                // Ошибка
                addOrderValidationError.text = message
                addOrderValidationError.visible = true
                console.log("Order Error: " + message)
            }
        }
    }

    // --- ЛОГИКА ---

    function applyFilters() {
        ordersModel.clear()

        var statusFilterText = statusFilter.currentText
        var typeFilterText = typeFilter.currentText
        var searchText = searchField.text.toLowerCase().trim()

        for (var i = 0; i < root.allOrders.length; i++) {
            var orderData = root.allOrders[i]

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

    // Функция обновления (теперь просто запрашивает данные у C++)
    function refreshTable() {
        root.isLoading = true
        DatabaseManager.fetchOrders()
    }

    function createOrder() {
        if (!validateForm()) return

        root.isLoading = true

        // Собираем данные в Map для отправки в транзакцию C++
        var orderData = {
            "order_number": "ORD-" + new Date().getTime(),
            "order_type": orderTypeComboBox.currentText,
            "total_amount": parseFloat(totalAmountField.text) || 0,
            "status": (orderTypeComboBox.currentText === "Продажа набора") ? "Завершён" : "Новый",
            "notes": notesField.text,
            "customer_id": customersModel.get(customerComboBox.currentIndex).id
        }

        if (orderTypeComboBox.currentText === "Изготовление рамки") {
            orderData["width"] = parseFloat(frameWidthField.text)
            orderData["height"] = parseFloat(frameHeightField.text)
            orderData["material_id"] = (materialComboBox.currentIndex >= 0) ? frameMaterialsModel.get(materialComboBox.currentIndex).id : 1
            var mIndex = masterComboBox.currentIndex
            orderData["master_id"] = (mIndex >= 0) ? mastersModel.get(mIndex).id : -1
        } else {
            var kitData = kitsModel.get(kitComboBox.currentIndex)
            orderData["kit_id"] = kitData.id
            orderData["quantity"] = parseInt(kitQuantityField.text)
            orderData["unit_price"] = kitData.price
        }

        // Асинхронный вызов
        DatabaseManager.createOrderTransactionAsync(orderData)
    }

    function validateForm() {
        var errors = []
        if (customerComboBox.currentIndex === -1) errors.push("• Выберите клиента из списка")
        if (!totalAmountField.text || parseFloat(totalAmountField.text) <= 0) errors.push("• Введите корректную сумму заказа")

        if (orderTypeComboBox.currentText === "Изготовление рамки") {
            if (!frameWidthField.text) errors.push("• Введите ширину")
            if (!frameHeightField.text) errors.push("• Введите высоту")
        } else if (orderTypeComboBox.currentText === "Продажа набора") {
            if (kitComboBox.currentIndex === -1) errors.push("• Выберите набор")
        }

        if (errors.length > 0) {
            addOrderValidationError.text = errors.join("\n")
            addOrderValidationError.visible = true
            return false
        }
        addOrderValidationError.visible = false
        return true
    }

    // Вспомогательные функции (без изменений)
    function formatDate(dateString) {
        if (!dateString) return "Не указана"
        var date = new Date(dateString)
        if (isNaN(date.getTime())) return "Неверная дата"
        return date.toLocaleDateString(Qt.locale("ru_RU"), "dd.MM.yyyy")
    }

    function getStatusColor(status) {
        if (!status) return "#7f8c8d"
        switch (status) {
            case 'Новый': return "#3498db"
            case 'В работе': return "#f39c12"
            case 'Готов': return "#27ae60"
            case 'Завершён': return "#2ecc71"
            case 'Отменён': return "#e74c3c"
            default: return "#7f8c8d"
        }
    }

    function toggleOrderTypeFields() {
        frameOrderFields.visible = orderTypeComboBox.currentText === "Изготовление рамки"
        kitOrderFields.visible = orderTypeComboBox.currentText === "Продажа набора"
        calculateTotal()
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
            if (width > 0 && height > 0 && materialComboBox.currentIndex >= 0) {
                var matPrice = frameMaterialsModel.get(materialComboBox.currentIndex).price
                var cost = ((width + height) * 2 / 100.0 * 1.15 * matPrice) + 500
                total = cost * 2.0
            }
        }
        totalAmountField.text = total > 0 ? total.toFixed(2) : ""
    }

    // --- ИНТЕРФЕЙС (Без визуальных изменений) ---

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label {
            Layout.fillWidth: true; Layout.preferredHeight: 70
            text: "📦 Управление заказами"
            font.bold: true; font.pixelSize: 20
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            color: "#2c3e50"
            background: Rectangle { color: "#ffffff"; radius: 10; border.color: "#e0e0e0"; border.width: 1 }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 60
            color: "#ffffff"; radius: 10; border.color: "#e0e0e0"

            RowLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 10

                ComboBox {
                    id: statusFilter; Layout.preferredWidth: 200
                    model: ["Все статусы", "Новый", "В работе", "Готов", "Завершён", "Отменён"]
                    contentItem: Text { text: statusFilter.displayText; color: "#000000"; font: statusFilter.font; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignLeft; elide: Text.ElideRight; leftPadding: 12 }
                    background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: statusFilter.activeFocus ? "#3498db" : "#dce0e3" }
                    onCurrentTextChanged: applyFilters() // Используем applyFilters вместо refreshTable
                }

                ComboBox {
                    id: typeFilter; Layout.preferredWidth: 180
                    model: ["Все типы", "Изготовление рамки", "Продажа набора"]
                    contentItem: Text { text: typeFilter.displayText; color: "#000000"; font: typeFilter.font; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignLeft; elide: Text.ElideRight; leftPadding: 12 }
                    background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: typeFilter.activeFocus ? "#3498db" : "#dce0e3" }
                    onCurrentTextChanged: applyFilters()
                }

                TextField {
                    id: searchField; Layout.fillWidth: true
                    placeholderText: "Поиск по номеру заказа или клиенту..."
                    font.pixelSize: 14
                    background: Rectangle { color: "#f8f9fa"; radius: 8; border.color: searchField.activeFocus ? "#3498db" : "#dce0e3"; border.width: 1 }
                    onTextChanged: applyFilters()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 50
            color: "#3498db"; radius: 8
            Row {
                anchors.fill: parent; anchors.margins: 5; spacing: 1
                Repeater {
                    model: ["№ заказа", "Клиент", "Тип", "Статус", "Сумма", "Дата"]
                    Rectangle {
                        width: (parent.width - 5) / 6; height: parent.height; color: "transparent"
                        Text { anchors.centerIn: parent; text: modelData; color: "white"; font.bold: true; font.pixelSize: 14 }
                    }
                }
            }
        }

        Rectangle {
            id: tableContainer
            Layout.fillWidth: true; Layout.fillHeight: true
            color: "#ffffff"; radius: 10; border.color: "#e0e0e0"; border.width: 1; clip: true

            ScrollView {
                anchors.fill: parent; anchors.margins: 2; clip: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn; ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ListView {
                    id: ordersListView
                    anchors.fill: parent; clip: true
                    model: ordersModel
                    spacing: 0

                    delegate: Rectangle {
                        width: ordersListView.width; height: 45
                        color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#e9ecef"; border.width: 1

                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedRow = index
                                orderDetailsDialog.openWithData(model)
                            }
                            Rectangle { anchors.fill: parent; color: parent.containsMouse ? "#e3f2fd" : "transparent" }
                        }

                        Row {
                            anchors.fill: parent; anchors.margins: 5; spacing: 1
                            property int colWidth: (parent.width - 5) / 6

                            Rectangle { width: parent.colWidth; height: parent.height; color: "transparent"; Text { anchors.fill: parent; anchors.margins: 5; text: model.order_number; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 13; color: "#2c3e50" } }
                            Rectangle { width: parent.colWidth; height: parent.height; color: "transparent"; Text { anchors.fill: parent; anchors.margins: 5; text: model.customer_name; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; font.pixelSize: 13; color: "#2c3e50" } }
                            Rectangle { width: parent.colWidth; height: parent.height; color: "transparent"; Text { anchors.fill: parent; anchors.margins: 5; text: model.order_type; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 13; color: "#2c3e50" } }
                            Rectangle { width: parent.colWidth; height: parent.height; color: "transparent"; Text { anchors.fill: parent; anchors.margins: 5; text: model.status; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; color: getStatusColor(model.status); font.bold: true; font.pixelSize: 13 } }
                            Rectangle { width: parent.colWidth; height: parent.height; color: "transparent"; Text { anchors.fill: parent; anchors.margins: 5; text: model.total_amount + " ₽"; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 13; color: "#2c3e50" } }
                            Rectangle { width: parent.colWidth; height: parent.height; color: "transparent"; Text { anchors.fill: parent; anchors.margins: 5; text: formatDate(model.created_at); verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 13; color: "#2c3e50" } }
                        }
                    }
                }
            }
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight; spacing: 10
            Button {
                id: newOrderButton; text: "Новый заказ"
                font.bold: true; padding: 12; font.pixelSize: 14; Layout.preferredWidth: 150
                enabled: !root.isLoading
                background: Rectangle { color: parent.down ? "#27ae60" : "#2ecc71"; radius: 8 }
                contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                onClicked: orderAddDialog.open()
            }
            Button {
                id: refreshButton; text: "Обновить"
                font.bold: true; font.pixelSize: 14; padding: 12; Layout.preferredWidth: 120
                enabled: !root.isLoading
                background: Rectangle { color: parent.down ? "#2980b9" : "#3498db"; radius: 8 }
                contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font: parent.font }
                onClicked: refreshTable()
            }
        }
    }

    // --- ДИАЛОГИ ---

    Dialog {
        id: orderAddDialog
        modal: true; header: null; width: 500; height: 700; anchors.centerIn: parent; padding: 20
        background: Rectangle { color: "#ffffff"; radius: 12; border.color: "#e0e0e0"; border.width: 1 }

        ColumnLayout {
            anchors.fill: parent; spacing: 10
            Label { Layout.fillWidth: true; text: "Создание нового заказа"; font.bold: true; font.pixelSize: 18; color: "#2c3e50"; padding: 10; horizontalAlignment: Text.AlignHCenter }

            ScrollView {
                clip: true; Layout.fillHeight: true; Layout.fillWidth: true; contentWidth: availableWidth
                ScrollBar.vertical.policy: ScrollBar.AsNeeded; ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: parent.width; spacing: 15; anchors.top: parent.top; anchors.topMargin: 10
                    Column {
                        width: 400; anchors.horizontalCenter: parent.horizontalCenter; spacing: 12
                        Column {
                            width: parent.width; spacing: 6
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Выберите клиента:"; font.bold: true; color: "#34495e"; font.pixelSize: 13 }
                            ComboBox {
                                id: customerComboBox; width: parent.width; anchors.horizontalCenter: parent.horizontalCenter
                                model: customersModel; textRole: "display"
                                background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: customerComboBox.activeFocus ? "#3498db" : "#dce0e3" }
                                contentItem: Text { text: customerComboBox.displayText; color: "#000000"; font: customerComboBox.font; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignLeft; elide: Text.ElideRight; leftPadding: 12 }
                                onActivated: {
                                    if (currentIndex >= 0) {
                                        var customerData = customersModel.get(currentIndex)
                                        customerPhoneLabel.text = "Телефон: " + (customerData.phone || "Не указан")
                                        customerEmailLabel.text = "Email: " + (customerData.email || "Не указан")
                                    }
                                }
                            }
                        }
                        Column {
                            width: parent.width; spacing: 6; visible: customerComboBox.currentIndex >= 0
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Контактная информация:"; font.bold: true; color: "#34495e"; font.pixelSize: 13 }
                            Label { id: customerPhoneLabel; width: parent.width; anchors.horizontalCenter: parent.horizontalCenter; padding: 8; background: Rectangle { color: "#f8f9fa"; radius: 6 } }
                            Label { id: customerEmailLabel; width: parent.width; anchors.horizontalCenter: parent.horizontalCenter; padding: 8; background: Rectangle { color: "#f8f9fa"; radius: 6 } }
                        }
                        Column {
                            width: parent.width; spacing: 6
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Тип заказа:"; font.bold: true; color: "#34495e"; font.pixelSize: 13 }
                            ComboBox {
                                id: orderTypeComboBox; width: parent.width; anchors.horizontalCenter: parent.horizontalCenter
                                model: ["Изготовление рамки", "Продажа набора"]
                                background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: orderTypeComboBox.activeFocus ? "#3498db" : "#dce0e3" }
                                contentItem: Text { text: orderTypeComboBox.displayText; color: "#000000"; font: orderTypeComboBox.font; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignLeft; elide: Text.ElideRight; leftPadding: 12 }
                                onCurrentTextChanged: toggleOrderTypeFields()
                            }
                        }

                        // Фрейм
                        Column {
                            id: frameOrderFields; width: parent.width; spacing: 6; visible: false
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Багет:"; font.bold: true; color: "#34495e"; font.pixelSize: 13 }
                            ComboBox {
                                id: materialComboBox; width: parent.width; anchors.horizontalCenter: parent.horizontalCenter
                                model: frameMaterialsModel; textRole: "display"
                                background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: materialComboBox.activeFocus ? "#3498db" : "#dce0e3" }
                                contentItem: Text { text: materialComboBox.displayText; color: "#000000"; font: materialComboBox.font; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignLeft; elide: Text.ElideRight; leftPadding: 12 }
                                onActivated: calculateTotal()
                            }
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Мастер:"; font.bold: true; color: "#34495e"; font.pixelSize: 13 }
                            ComboBox {
                                id: masterComboBox; width: parent.width; anchors.horizontalCenter: parent.horizontalCenter
                                model: mastersModel; textRole: "display"
                                background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: masterComboBox.activeFocus ? "#3498db" : "#dce0e3" }
                                contentItem: Text { text: masterComboBox.displayText; color: "#000000"; font: masterComboBox.font; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignLeft; elide: Text.ElideRight; leftPadding: 12 }
                            }
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Размеры рамки (см):"; font.bold: true; color: "#34495e"; font.pixelSize: 13 }
                            Row {
                                width: parent.width; anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
                                Column {
                                    width: (parent.width - 10) / 2; spacing: 4
                                    Label { text: "Ширина:"; font.bold: true; color: "#34495e"; font.pixelSize: 12 }
                                    TextField {
                                        id: frameWidthField; width: parent.width; placeholderText: "0.0"
                                        validator: DoubleValidator { bottom: 0.1; top: 1000.0 }
                                        background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: frameWidthField.activeFocus ? "#3498db" : "#dce0e3" }
                                        onTextChanged: calculateTotal()
                                    }
                                }
                                Column {
                                    width: (parent.width - 10) / 2; spacing: 4
                                    Label { text: "Высота:"; font.bold: true; color: "#34495e"; font.pixelSize: 12 }
                                    TextField {
                                        id: frameHeightField; width: parent.width; placeholderText: "0.0"
                                        validator: DoubleValidator { bottom: 0.1; top: 1000.0 }
                                        background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: frameHeightField.activeFocus ? "#3498db" : "#dce0e3" }
                                        onTextChanged: calculateTotal()
                                    }
                                }
                            }
                        }

                        // Набор
                        Column {
                            id: kitOrderFields; width: parent.width; spacing: 6; visible: false
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Набор:"; font.bold: true; color: "#34495e"; font.pixelSize: 13 }
                            ComboBox {
                                id: kitComboBox; width: parent.width; anchors.horizontalCenter: parent.horizontalCenter
                                model: kitsModel; textRole: "display"
                                background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: kitComboBox.activeFocus ? "#3498db" : "#dce0e3" }
                                onActivated: calculateKitTotal()
                            }
                            Row {
                                width: parent.width; anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
                                Column {
                                    width: (parent.width - 10) / 2; spacing: 4
                                    Label { text: "Кол-во:"; font.bold: true; color: "#34495e"; font.pixelSize: 12 }
                                    TextField {
                                        id: kitQuantityField; width: parent.width; text: "1"
                                        validator: IntValidator { bottom: 1; top: 1000 }
                                        background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: kitQuantityField.activeFocus ? "#3498db" : "#dce0e3" }
                                        onTextChanged: calculateKitTotal()
                                    }
                                }
                                Column {
                                    width: (parent.width - 10) / 2; spacing: 4
                                    Label { text: " "; font.pixelSize: 12 }
                                    Row {
                                        height: kitQuantityField.height; spacing: 5
                                        Label { text: "Цена за шт:"; color: "#34495e"; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                        Label { id: kitPriceLabel; text: "0 ₽"; color: "#2c3e50"; font.bold: true; font.pixelSize: 13; verticalAlignment: Text.AlignVCenter; height: parent.height }
                                    }
                                }
                            }
                        }

                        Column {
                            width: parent.width; spacing: 6
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Итоговая сумма (₽):"; font.bold: true; color: "#34495e"; font.pixelSize: 13 }
                            TextField {
                                id: totalAmountField; width: parent.width; anchors.horizontalCenter: parent.horizontalCenter
                                placeholderText: "0.00"; font.bold: true
                                validator: DoubleValidator { bottom: 0.01; top: 1000000.0 }
                                background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: totalAmountField.activeFocus ? "#3498db" : "#dce0e3" }
                            }
                        }
                        Column {
                            width: parent.width; spacing: 6
                            Label { anchors.horizontalCenter: parent.horizontalCenter; text: "Примечания:"; font.bold: true; color: "#34495e"; font.pixelSize: 13 }
                            TextArea {
                                id: notesField; width: parent.width; anchors.horizontalCenter: parent.horizontalCenter; height: 90
                                wrapMode: TextArea.Wrap
                                background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: notesField.activeFocus ? "#3498db" : "#dce0e3" }
                            }
                        }
                        Label { id: addOrderValidationError; width: parent.width; anchors.horizontalCenter: parent.horizontalCenter; color: "#e74c3c"; visible: false; wrapMode: Text.WordWrap; font.pixelSize: 13; font.bold: true }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 60; color: "transparent"
                RowLayout {
                    anchors.centerIn: parent; spacing: 15
                    Button {
                        text: "Отмена"; Layout.preferredWidth: 120; Layout.preferredHeight: 40
                        background: Rectangle { color: parent.down ? "#7f8c8d" : "#95a5a6"; radius: 8 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true; font.pixelSize: 13 }
                        onClicked: orderAddDialog.close()
                    }
                    Button {
                        text: "Создать"; Layout.preferredWidth: 120; Layout.preferredHeight: 40
                        background: Rectangle { color: parent.down ? "#27ae60" : "#2ecc71"; radius: 8 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true; font.pixelSize: 13 }
                        onClicked: createOrder()
                    }
                }
            }
        }
        onOpened: {
            customerComboBox.currentIndex = -1; kitComboBox.currentIndex = -1; orderTypeComboBox.currentIndex = 0
            totalAmountField.text = ""; frameWidthField.text = ""; frameHeightField.text = ""; kitQuantityField.text = "1"
            notesField.text = ""; addOrderValidationError.visible = false
            customerPhoneLabel.text = "Телефон: Не выбран"; customerEmailLabel.text = "Email: Не выбран"
            kitPriceLabel.text = "0 ₽"; toggleOrderTypeFields()
        }
    }

    Dialog {
        id: orderDetailsDialog
        modal: true; header: null; width: 500; height: 400; anchors.centerIn: parent; padding: 20
        property var currentOrderData: ({})
        background: Rectangle { color: "#ffffff"; radius: 12; border.color: "#e0e0e0"; border.width: 1 }

        ColumnLayout {
            anchors.fill: parent; spacing: 10
            Label { Layout.fillWidth: true; text: "Детали заказа"; font.bold: true; font.pixelSize: 18; color: "#2c3e50"; horizontalAlignment: Text.AlignHCenter }

            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ColumnLayout {
                    width: parent.width; spacing: 15; Layout.topMargin: 10
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: detailsCol.implicitHeight + 20; color: "#f8f9fa"; radius: 8
                        ColumnLayout {
                            id: detailsCol; anchors.fill: parent; anchors.margins: 15; spacing: 10
                            Repeater {
                                model: [
                                    {l: "№ заказа:", v: (orderDetailsDialog.currentOrderData || {}).order_number},
                                    {l: "Статус:", v: (orderDetailsDialog.currentOrderData || {}).status, isStatus: true},
                                    {l: "Тип:", v: (orderDetailsDialog.currentOrderData || {}).order_type},
                                    {l: "Сумма:", v: ((orderDetailsDialog.currentOrderData || {}).total_amount || 0) + " ₽", isPrice: true},
                                    {l: "Клиент:", v: (orderDetailsDialog.currentOrderData || {}).customer_name},
                                    {l: "Телефон:", v: (orderDetailsDialog.currentOrderData || {}).customer_phone},
                                    {l: "Дата:", v: formatDate((orderDetailsDialog.currentOrderData || {}).created_at)}
                                ]
                                RowLayout {
                                    Layout.fillWidth: true
                                    Label { text: modelData.l; font.bold: true; color: "#34495e"; Layout.preferredWidth: 100; font.pixelSize: 16 }
                                    Label {
                                        text: modelData.v || "—"
                                        color: (modelData.isStatus === true) ? getStatusColor(modelData.v) : ((modelData.isPrice === true) ? "#27ae60" : "#2c3e50")
                                        font.bold: (modelData.isStatus === true) || (modelData.isPrice === true)
                                        Layout.fillWidth: true; wrapMode: Text.Wrap; font.pixelSize: 16
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 60; color: "transparent"
                RowLayout {
                    anchors.centerIn: parent; spacing: 15
                    Button {
                        text: "Изменить"; Layout.preferredWidth: 120; Layout.preferredHeight: 40
                        background: Rectangle { color: parent.down ? "#f39c12" : "#f1c40f"; radius: 8 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true; font.pixelSize: 13 }
                        onClicked: { orderDetailsDialog.close(); orderEditDialog.openWithData(orderDetailsDialog.currentOrderData) }
                    }
                    Button {
                        text: "Удалить"; Layout.preferredWidth: 120; Layout.preferredHeight: 40
                        background: Rectangle { color: parent.down ? "#c0392b" : "#e74c3c"; radius: 8 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true; font.pixelSize: 13 }
                        onClicked: deleteConfirmDialog.open()
                    }
                    Button {
                        text: "Закрыть"; Layout.preferredWidth: 120; Layout.preferredHeight: 40
                        background: Rectangle { color: parent.down ? "#7f8c8d" : "#95a5a6"; radius: 8 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true; font.pixelSize: 13 }
                        onClicked: orderDetailsDialog.close()
                    }
                }
            }
        }
        function openWithData(orderModel) { currentOrderData = orderModel; open() }
    }

    Dialog {
        id: orderEditDialog
        modal: true; header: null; width: 500; height: 400; anchors.centerIn: parent; padding: 20
        property var currentData: ({})
        background: Rectangle { color: "#ffffff"; radius: 12; border.color: "#e0e0e0"; border.width: 1 }

        ColumnLayout {
            anchors.fill: parent; spacing: 10
            Label { Layout.fillWidth: true; text: "Редактирование заказа"; font.bold: true; font.pixelSize: 18; color: "#2c3e50"; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }

            ColumnLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.alignment: Qt.AlignCenter; spacing: 20
                Column {
                    Layout.alignment: Qt.AlignHCenter; width: 300; spacing: 5
                    Label { text: "Статус заказа:"; font.bold: true; color: "#34495e" }
                    ComboBox {
                        id: editStatusCombo; width: parent.width
                        model: ["Новый", "В работе", "Готов", "Завершён", "Отменён"]
                        background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: editStatusCombo.activeFocus ? "#3498db" : "#dce0e3" }
                        contentItem: Text { text: editStatusCombo.displayText; color: "#000000"; font: editStatusCombo.font; verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignLeft; elide: Text.ElideRight; leftPadding: 12 }
                    }
                }
                Column {
                    Layout.alignment: Qt.AlignHCenter; width: 300; spacing: 5
                    Label { text: "Сумма заказа:"; font.bold: true; color: "#34495e" }
                    TextField {
                        id: editTotalAmountField; width: parent.width; validator: DoubleValidator { bottom: 0.0 }
                        background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: editTotalAmountField.activeFocus ? "#3498db" : "#dce0e3" }
                    }
                }
                Column {
                    Layout.alignment: Qt.AlignHCenter; width: 300; spacing: 5
                    Label { text: "Примечания:"; font.bold: true; color: "#34495e" }
                    TextArea {
                        id: editNotesField; width: parent.width; height: 80; wrapMode: TextArea.Wrap
                        background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: editNotesField.activeFocus ? "#3498db" : "#dce0e3" }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 60; color: "transparent"
                RowLayout {
                    anchors.centerIn: parent; spacing: 15
                    Button {
                        text: "Отмена"; Layout.preferredWidth: 120; Layout.preferredHeight: 40
                        background: Rectangle { color: parent.down ? "#7f8c8d" : "#95a5a6"; radius: 8 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true; font.pixelSize: 13 }
                        onClicked: orderEditDialog.close()
                    }
                    Button {
                        text: "Сохранить"; Layout.preferredWidth: 120; Layout.preferredHeight: 40
                        background: Rectangle { color: parent.down ? "#27ae60" : "#2ecc71"; radius: 8 }
                        contentItem: Text { text: parent.text; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; font.bold: true; font.pixelSize: 13 }
                        onClicked: {
                            root.isLoading = true
                            DatabaseManager.updateOrderAsync(
                                orderEditDialog.currentData.id,
                                editStatusCombo.currentText,
                                parseFloat(editTotalAmountField.text),
                                editNotesField.text
                            )
                        }
                    }
                }
            }
        }
        function openWithData(data) {
            currentData = data
            editStatusCombo.currentIndex = editStatusCombo.indexOfValue(data.status)
            editTotalAmountField.text = data.total_amount
            editNotesField.text = data.notes || ""
            open()
        }
    }

    Dialog {
        id: deleteConfirmDialog
        modal: true; header: null; width: 350; height: 200; anchors.centerIn: parent; padding: 20
        background: Rectangle { color: "#ffffff"; radius: 12; border.color: "#e0e0e0"; border.width: 1 }

        ColumnLayout {
            anchors.fill: parent; spacing: 15
            Label { Layout.fillWidth: true; text: "Удаление заказа"; font.bold: true; font.pixelSize: 18; color: "#c0392b"; horizontalAlignment: Text.AlignHCenter }
            Label { Layout.fillWidth: true; text: "Вы уверены, что хотите удалить этот заказ? Это действие нельзя отменить."; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; color: "#2c3e50"; font.pixelSize: 14 }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter; spacing: 15
                Button {
                    text: "Нет"; Layout.preferredWidth: 100; Layout.preferredHeight: 40
                    background: Rectangle { color: parent.down ? "#7f8c8d" : "#95a5a6"; radius: 8 }
                    contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; }
                    onClicked: deleteConfirmDialog.close()
                }
                Button {
                    text: "Да, удалить"; Layout.preferredWidth: 100; Layout.preferredHeight: 40
                    background: Rectangle { color: parent.down ? "#c0392b" : "#e74c3c"; radius: 8 }
                    contentItem: Text { text: parent.text; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter;  }
                    onClicked: {
                        root.isLoading = true
                        DatabaseManager.deleteOrderAsync(orderDetailsDialog.currentOrderData.id)
                    }
                }
            }
        }
    }

    Dialog {
        id: orderCreatedMessage
        modal: true; header: null; width: 300; height: 150; anchors.centerIn: parent; padding: 20
        background: Rectangle { color: "#ffffff"; radius: 12; border.color: "#e0e0e0"; border.width: 1 }
        ColumnLayout {
            anchors.fill: parent; spacing: 10
            Label { text: "Успешно"; font.bold: true; font.pixelSize: 18; color: "#27ae60"; Layout.alignment: Qt.AlignHCenter }
            Label { text: "Заказ успешно создан!"; Layout.alignment: Qt.AlignHCenter }
            Item { Layout.fillHeight: true }
            Button {
                text: "OK"; Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 100; Layout.preferredHeight: 35
                background: Rectangle { color: "#2ecc71"; radius: 8 }
                contentItem: Text { text: "OK"; color: "white"; font.bold: true; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                onClicked: orderCreatedMessage.close()
            }
        }
    }
}
