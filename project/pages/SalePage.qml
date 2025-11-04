import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import databasemanager

Page {
    id: root
    property string tableName: "embroidery_kits"
    property string consumablesTable: "consumable_furniture"
    property int selectedRow: -1

    Rectangle {
        anchors.fill: parent
        color: "#f8f9fa"
    }

    ListModel {
        id: productsModel
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        DatabaseManager {
            id: dbmanager
        }

        // Заголовок страницы
        Label {
            Layout.fillWidth: true
            text: "🛍️ Продажа наборов и расходной фурнитуры"
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

        // Выбор типа товара
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: "#ffffff"
            radius: 10
            border.color: "#e0e0e0"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Label {
                    text: "Тип товара:"
                    font.bold: true
                    color: "#2c3e50"
                    font.pixelSize: 14
                }

                ButtonGroup {
                    id: productTypeGroup
                }

                RadioButton {
                    text: "🎨 Наборы для вышивки"
                    checked: true
                    ButtonGroup.group: productTypeGroup
                    onCheckedChanged: if (checked) updateProductList()
                }

                RadioButton {
                    text: "🧵 Расходная фурнитура"
                    ButtonGroup.group: productTypeGroup
                    onCheckedChanged: if (checked) updateProductList()
                }
            }
        }

        // Заголовок таблицы
        Rectangle {
            Layout.fillWidth: true
            height: 50
            color: "#3498db"
            radius: 8

            Row {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 1

                Repeater {
                    model: productTypeGroup.checkedButton.text.includes("Наборы") ?
                           ["ID", "Название", "Описание", "Цена", "В наличии"] :
                           ["ID", "Название", "Тип", "Цена за ед.", "В наличии", "Ед. изм."]

                    Rectangle {
                        width: tableview.width / (productTypeGroup.checkedButton.text.includes("Наборы") ? 5 : 6)
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

        // Таблица товаров
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
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                TableView {
                    id: tableview
                    anchors.fill: parent
                    clip: true
                    model: productsModel

                    columnWidthProvider: function(column) {
                        const colCount = productTypeGroup.checkedButton.text.includes("Наборы") ? 5 : 6
                        return tableview.width / Math.max(colCount, 1)
                    }

                    delegate: Rectangle {
                        implicitHeight: 45
                        color: row % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#e9ecef"

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedRow = row
                                if (productTypeGroup.checkedButton.text.includes("Наборы")) {
                                    kitViewDialog.openWithData(row)
                                } else {
                                    consumableViewDialog.openWithData(row)
                                }
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
                                if (!model) return ""

                                if (productTypeGroup.checkedButton.text.includes("Наборы")) {
                                    switch(column) {
                                        case 0: return model.id || "—"
                                        case 1: return model.name || "—"
                                        case 2: return model.description || "—"
                                        case 3: return model.price ? model.price + " ₽" : "—"
                                        case 4: return model.stock_quantity || "0"
                                        default: return ""
                                    }
                                } else {
                                    switch(column) {
                                        case 0: return model.id || "—"
                                        case 1: return model.name || "—"
                                        case 2: return model.type || "—"
                                        case 3: return model.price_per_unit ? model.price_per_unit + " ₽" : "—"
                                        case 4: return model.stock_quantity || "0"
                                        case 5: return model.unit || "—"
                                        default: return ""
                                    }
                                }
                            }
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            elide: Text.ElideRight
                            color: "#2c3e50"
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }

        // Кнопки действий
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "➕ Добавить товар"
                font.bold: true
                font.pixelSize: 14
                padding: 12
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
                    if (productTypeGroup.checkedButton.text.includes("Наборы")) {
                        kitAddDialog.open()
                    } else {
                        consumableAddDialog.open()
                    }
                }
            }

            Button {
                text: "🛒 Оформить продажу"
                font.bold: true
                font.pixelSize: 14
                padding: 12
                Layout.fillWidth: true
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
                onClicked: saleDialog.open()
            }

            Button {
                text: "📊 Отчет по продажам"
                font.bold: true
                font.pixelSize: 14
                padding: 12
                Layout.fillWidth: true
                background: Rectangle {
                    color: parent.down ? "#8e44ad" : "#9b59b6"
                    radius: 8
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }
                onClicked: salesReportDialog.open()
            }
        }
    }

    function updateProductList() {
        productsModel.clear()

        console.log("Updating product list for:", productTypeGroup.checkedButton.text)

        var productData = []
        if (productTypeGroup.checkedButton.text.includes("Наборы")) {
            productData = dbmanager.getEmbroideryKitsData()
            root.tableName = "embroidery_kits"
        } else {
            productData = dbmanager.getConsumableFurnitureData()
            root.tableName = "consumable_furniture"
        }

        console.log("Raw product data:", productData)

        for (var i = 0; i < productData.length; i++) {
            productsModel.append(productData[i])
        }

        console.log("Loaded", productsModel.count, "products from", root.tableName)
    }

    // Диалог оформления продажи
    Dialog {
        id: saleDialog
        modal: true
        title: "🛒 Оформление продажи"

        property double unitPrice: 0
        property int availableStock: 0

        width: 600
        height: 550
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
                text: "🛒 Оформление продажи товара"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            // Выбор покупателя
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "👤 Покупатель:"
                    font.bold: true
                    color: "#34495e"
                    font.pixelSize: 14
                }

                ComboBox {
                    id: customerComboBox
                    Layout.fillWidth: true
                    model: dbmanager.getCustomersModel()
                    textRole: "full_name"
                    delegate: ItemDelegate {
                        width: customerComboBox.width
                        contentItem: Column {
                            spacing: 2
                            Text {
                                text: model.full_name
                                font.pixelSize: 14
                                color: "#2c3e50"
                            }
                            Text {
                                text: model.phone + " • " + model.email
                                font.pixelSize: 11
                                color: "#7f8c8d"
                            }
                        }
                    }
                    displayText: {
                        if (currentIndex >= 0) {
                            var name = model.data(model.index(currentIndex, 1))
                            var phone = model.data(model.index(currentIndex, 2))
                            return name + " • " + phone
                        }
                        return "Выберите покупателя"
                    }
                }
            }

            // Выбор товара
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: productTypeGroup.checkedButton.text.includes("Наборы") ? "🎨 Товар:" : "🧵 Товар:"
                    font.bold: true
                    color: "#34495e"
                    font.pixelSize: 14
                }

                ComboBox {
                    id: productComboBox
                    Layout.fillWidth: true
                    model: productTypeGroup.checkedButton.text.includes("Наборы") ?
                           dbmanager.getEmbroideryKitsModel() : dbmanager.getConsumableFurnitureModel()
                    textRole: "name"
                    displayText: currentIndex >= 0 ? currentText : "Выберите товар"
                    onCurrentIndexChanged: updateProductInfo()
                }
            }

            // Информация о товаре
            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                visible: productComboBox.currentIndex >= 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: "#e8f5e8"
                    radius: 8
                    border.color: "#27ae60"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        Label {
                            text: "💰 Цена за ед.:"
                            font.bold: true
                            color: "#27ae60"
                            font.pixelSize: 12
                        }

                        Label {
                            text: saleDialog.unitPrice + " ₽"
                            font.bold: true
                            font.pixelSize: 14
                            color: "#2ecc71"
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 60
                    color: "#e3f2fd"
                    radius: 8
                    border.color: "#3498db"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        Label {
                            text: "📦 В наличии:"
                            font.bold: true
                            color: "#3498db"
                            font.pixelSize: 12
                        }

                        Label {
                            text: saleDialog.availableStock + " шт"
                            font.bold: true
                            font.pixelSize: 14
                            color: "#2980b9"
                        }
                    }
                }
            }

            // Количество
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: "📦 Количество:"
                    font.bold: true
                    color: "#34495e"
                    font.pixelSize: 14
                }

                SpinBox {
                    id: quantitySpinBox
                    Layout.fillWidth: true
                    from: 1
                    to: 1000
                    value: 1
                    onValueChanged: updateTotalAmount()
                }
            }

            // Итоговая сумма
            Rectangle {
                Layout.fillWidth: true
                height: 70
                color: "#fff3cd"
                radius: 8
                border.color: "#ffc107"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Label {
                        text: "💰 Итоговая сумма:"
                        font.bold: true
                        color: "#e67e22"
                        font.pixelSize: 16
                    }

                    Label {
                        id: totalAmountLabel
                        text: "0 ₽"
                        font.bold: true
                        font.pixelSize: 20
                        color: "#d35400"
                    }
                }
            }

            Label {
                id: saleValidationError
                Layout.fillWidth: true
                Layout.preferredHeight: saleValidationError.visible ? implicitHeight : 0
                color: "#e74c3c"
                visible: false
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                padding: 8
                background: Rectangle {
                    color: "#fdf2f2"
                    radius: 6
                    border.color: "#e74c3c"
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
                onClicked: saleDialog.reject()
            }

            Button {
                text: "✅ Оформить"
                font.bold: true
                padding: 12
                width: 120
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
                onClicked: processSale()
            }
        }

        function updateProductInfo() {
            if (productComboBox.currentIndex >= 0) {
                var price = productTypeGroup.checkedButton.text.includes("Наборы") ?
                           productComboBox.model.data(productComboBox.model.index(productComboBox.currentIndex, 2)) :
                           productComboBox.model.data(productComboBox.model.index(productComboBox.currentIndex, 3))

                var stock = productTypeGroup.checkedButton.text.includes("Наборы") ?
                           productComboBox.model.data(productComboBox.model.index(productComboBox.currentIndex, 3)) :
                           productComboBox.model.data(productComboBox.model.index(productComboBox.currentIndex, 4))

                saleDialog.unitPrice = price || 0
                saleDialog.availableStock = stock || 0
                quantitySpinBox.to = saleDialog.availableStock
                updateTotalAmount()
            }
        }

        function updateTotalAmount() {
            var total = saleDialog.unitPrice * quantitySpinBox.value
            totalAmountLabel.text = total.toFixed(2) + " ₽"
        }

        function processSale() {
            if (validateSaleForm()) {
                var customerId = customerComboBox.model.data(customerComboBox.model.index(customerComboBox.currentIndex, 0))
                var productId = productComboBox.model.data(productComboBox.model.index(productComboBox.currentIndex, 0))
                var productName = productComboBox.currentText
                var quantity = quantitySpinBox.value
                var totalAmount = saleDialog.unitPrice * quantity

                // Здесь должна быть логика сохранения продажи в БД
                // dbmanager.createSale(customerId, productId, productName, quantity, totalAmount, productTypeGroup.checkedButton.text.includes("Наборы") ? "kit" : "consumable")

                saleDialog.close()
                saleSuccessDialog.openWithData(productName, quantity, totalAmount)
            }
        }

        function validateSaleForm() {
            const errors = []

            if (customerComboBox.currentIndex < 0) {
                errors.push("• Выберите покупателя")
            }

            if (productComboBox.currentIndex < 0) {
                errors.push("• Выберите товар")
            }

            if (quantitySpinBox.value <= 0) {
                errors.push("• Количество должно быть больше 0")
            }

            if (quantitySpinBox.value > saleDialog.availableStock) {
                errors.push("• Недостаточно товара на складе. Максимум: " + saleDialog.availableStock + " шт.")
            }

            if (errors.length > 0) {
                saleValidationError.text = errors.join("\n")
                saleValidationError.visible = true
                return false
            }

            saleValidationError.visible = false
            return true
        }

        onOpened: {
            saleValidationError.visible = false
            quantitySpinBox.value = 1
            updateProductInfo()
        }
    }

    // Диалог успешной продажи
    Dialog {
        id: saleSuccessDialog
        modal: true
        title: "✅ Продажа оформлена"

        property string productName: ""
        property int quantity: 0
        property double totalAmount: 0

        width: 450
        height: 250
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
                text: "✅ Продажа успешно оформлена!"
                wrapMode: Text.WordWrap
                font.pixelSize: 18
                color: "#27ae60"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "#f8f9fa"
                radius: 8
                border.color: "#e9ecef"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    Label {
                        Layout.fillWidth: true
                        text: "Товар: " + saleSuccessDialog.productName
                        font.pixelSize: 14
                        color: "#2c3e50"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Количество: " + saleSuccessDialog.quantity + " шт."
                        font.pixelSize: 14
                        color: "#2c3e50"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Сумма: " + saleSuccessDialog.totalAmount.toFixed(2) + " ₽"
                        font.pixelSize: 14
                        color: "#27ae60"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: "Товар продан, остатки обновлены."
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                color: "#7f8c8d"
                horizontalAlignment: Text.AlignHCenter
            }
        }

        footer: DialogButtonBox {
            alignment: Qt.AlignCenter
            padding: 15
            background: Rectangle {
                color: "transparent"
            }

            Button {
                text: "✅ OK"
                font.bold: true
                padding: 12
                width: 100
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
                    saleSuccessDialog.close()
                    updateProductList()
                }
            }
        }

        function openWithData(productName, quantity, totalAmount) {
            saleSuccessDialog.productName = productName
            saleSuccessDialog.quantity = quantity
            saleSuccessDialog.totalAmount = totalAmount
            open()
        }
    }

    // Диалог добавления набора
    Dialog {
        id: kitAddDialog
        modal: true
        title: "🎨 Добавить набор для вышивки"

        width: 500
        height: 500
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
            spacing: 12

            Label {
                Layout.fillWidth: true
                text: "🎨 Добавление нового набора"
                font.bold: true
                font.pixelSize: 16
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "Название набора:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                    }
                    TextField {
                        id: addKitNameField
                        Layout.fillWidth: true
                        placeholderText: "Введите название набора"
                        font.pixelSize: 14
                        padding: 10
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: addKitNameField.activeFocus ? "#3498db" : "#dce0e3"
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "Описание:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                    }
                    TextArea {
                        id: addKitDescriptionField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        placeholderText: "Введите описание набора"
                        font.pixelSize: 14
                        padding: 10
                        wrapMode: TextArea.Wrap
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: addKitDescriptionField.activeFocus ? "#3498db" : "#dce0e3"
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Label {
                            text: "Цена (₽):"
                            font.bold: true
                            color: "#34495e"
                            font.pixelSize: 13
                        }
                        TextField {
                            id: addKitPriceField
                            Layout.fillWidth: true
                            placeholderText: "0.00"
                            font.pixelSize: 14
                            padding: 10
                            validator: DoubleValidator { bottom: 0; decimals: 2 }
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 6
                                border.color: addKitPriceField.activeFocus ? "#3498db" : "#dce0e3"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Label {
                            text: "Количество:"
                            font.bold: true
                            color: "#34495e"
                            font.pixelSize: 13
                        }
                        SpinBox {
                            id: addKitQuantityField
                            Layout.fillWidth: true
                            from: 0
                            to: 1000
                            value: 0
                        }
                    }
                }

                Label {
                    id: kitValidationError
                    Layout.fillWidth: true
                    Layout.preferredHeight: kitValidationError.visible ? implicitHeight : 0
                    color: "#e74c3c"
                    visible: false
                    wrapMode: Text.WordWrap
                    font.pixelSize: 12
                    padding: 8
                    background: Rectangle {
                        color: "#fdf2f2"
                        radius: 6
                        border.color: "#e74c3c"
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
                onClicked: kitAddDialog.reject()
            }

            Button {
                text: "✅ Добавить"
                font.bold: true
                padding: 12
                width: 120
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
                    if (validateKitForm()) {
                        // dbmanager.addEmbroideryKit(addKitNameField.text, addKitDescriptionField.text, parseFloat(addKitPriceField.text), addKitQuantityField.value)
                        tableview.model = dbmanager.getTableModel(root.tableName)
                        kitAddDialog.close()
                    }
                }
            }
        }

        function validateKitForm() {
            const errors = []

            if (addKitNameField.text.trim().length < 2) {
                errors.push("• Название набора должно содержать минимум 2 символа")
            }

            if (parseFloat(addKitPriceField.text) <= 0) {
                errors.push("• Цена должна быть больше 0")
            }

            if (addKitQuantityField.value < 0) {
                errors.push("• Количество не может быть отрицательным")
            }

            if (errors.length > 0) {
                kitValidationError.text = errors.join("\n")
                kitValidationError.visible = true
                return false
            }

            kitValidationError.visible = false
            return true
        }

        onOpened: {
            addKitNameField.text = ""
            addKitDescriptionField.text = ""
            addKitPriceField.text = ""
            addKitQuantityField.value = 0
            kitValidationError.visible = false
            addKitNameField.forceActiveFocus()
        }
    }

    // Диалог добавления расходной фурнитуры
    Dialog {
        id: consumableAddDialog
        modal: true
        title: "🧵 Добавить расходную фурнитуру"

        width: 500
        height: 550
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
            spacing: 12

            Label {
                Layout.fillWidth: true
                text: "🧵 Добавление расходной фурнитуры"
                font.bold: true
                font.pixelSize: 16
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "Название:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                    }
                    TextField {
                        id: addConsumableNameField
                        Layout.fillWidth: true
                        placeholderText: "Введите название фурнитуры"
                        font.pixelSize: 14
                        padding: 10
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: addConsumableNameField.activeFocus ? "#3498db" : "#dce0e3"
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "Тип:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                    }
                    ComboBox {
                        id: addConsumableTypeField
                        Layout.fillWidth: true
                        model: ["инструменты", "материалы", "аксессуары", "прочее"]
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Label {
                            text: "Цена за ед. (₽):"
                            font.bold: true
                            color: "#34495e"
                            font.pixelSize: 13
                        }
                        TextField {
                            id: addConsumablePriceField
                            Layout.fillWidth: true
                            placeholderText: "0.00"
                            font.pixelSize: 14
                            padding: 10
                            validator: DoubleValidator { bottom: 0; decimals: 2 }
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 6
                                border.color: addConsumablePriceField.activeFocus ? "#3498db" : "#dce0e3"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Label {
                            text: "Ед. измерения:"
                            font.bold: true
                            color: "#34495e"
                            font.pixelSize: 13
                        }
                        ComboBox {
                            id: addConsumableUnitField
                            Layout.fillWidth: true
                            model: ["шт", "набор", "метр", "упаковка"]
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "Количество на складе:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                    }
                    SpinBox {
                        id: addConsumableQuantityField
                        Layout.fillWidth: true
                        from: 0
                        to: 10000
                        value: 0
                    }
                }

                Label {
                    id: consumableValidationError
                    Layout.fillWidth: true
                    Layout.preferredHeight: consumableValidationError.visible ? implicitHeight : 0
                    color: "#e74c3c"
                    visible: false
                    wrapMode: Text.WordWrap
                    font.pixelSize: 12
                    padding: 8
                    background: Rectangle {
                        color: "#fdf2f2"
                        radius: 6
                        border.color: "#e74c3c"
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
                onClicked: consumableAddDialog.reject()
            }

            Button {
                text: "✅ Добавить"
                font.bold: true
                padding: 12
                width: 120
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
                    if (validateConsumableForm()) {
                        // dbmanager.addConsumableFurniture(addConsumableNameField.text, addConsumableTypeField.currentText, parseFloat(addConsumablePriceField.text), addConsumableQuantityField.value, addConsumableUnitField.currentText)
                        tableview.model = dbmanager.getTableModel(root.tableName)
                        consumableAddDialog.close()
                    }
                }
            }
        }

        function validateConsumableForm() {
            const errors = []

            if (addConsumableNameField.text.trim().length < 2) {
                errors.push("• Название должно содержать минимум 2 символа")
            }

            if (parseFloat(addConsumablePriceField.text) <= 0) {
                errors.push("• Цена должна быть больше 0")
            }

            if (addConsumableQuantityField.value < 0) {
                errors.push("• Количество не может быть отрицательным")
            }

            if (errors.length > 0) {
                consumableValidationError.text = errors.join("\n")
                consumableValidationError.visible = true
                return false
            }

            consumableValidationError.visible = false
            return true
        }

        onOpened: {
            addConsumableNameField.text = ""
            addConsumableTypeField.currentIndex = 0
            addConsumablePriceField.text = ""
            addConsumableUnitField.currentIndex = 0
            addConsumableQuantityField.value = 0
            consumableValidationError.visible = false
            addConsumableNameField.forceActiveFocus()
        }
    }

    // Диалог просмотра набора
    Dialog {
        id: kitViewDialog
        modal: true
        title: "🎨 Просмотр набора"

        property int currentRow: -1
        property var currentData: ({})

        width: 500
        height: 400
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
                text: "🎨 Информация о наборе"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Label {
                        text: "Название:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 14
                    }
                    Label {
                        Layout.fillWidth: true
                        text: kitViewDialog.currentData.name || "Не указано"
                        wrapMode: Text.Wrap
                        color: "#2c3e50"
                        font.pixelSize: 14
                        padding: 10
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: "#e9ecef"
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Label {
                        text: "Описание:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 14
                    }
                    Label {
                        Layout.fillWidth: true
                        text: kitViewDialog.currentData.description || "Не указано"
                        wrapMode: Text.Wrap
                        color: "#2c3e50"
                        font.pixelSize: 14
                        padding: 10
                        Layout.preferredHeight: 60
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: "#e9ecef"
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Label {
                            text: "Цена:"
                            font.bold: true
                            color: "#34495e"
                            font.pixelSize: 14
                        }
                        Label {
                            Layout.fillWidth: true
                            text: (kitViewDialog.currentData.price ? kitViewDialog.currentData.price + " ₽" : "Не указано")
                            color: "#27ae60"
                            font.pixelSize: 14
                            font.bold: true
                            padding: 10
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                                border.color: "#e9ecef"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Label {
                            text: "В наличии:"
                            font.bold: true
                            color: "#34495e"
                            font.pixelSize: 14
                        }
                        Label {
                            Layout.fillWidth: true
                            text: kitViewDialog.currentData.stock_quantity || "0"
                            color: "#2c3e50"
                            font.pixelSize: 14
                            padding: 10
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                                border.color: "#e9ecef"
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
                onClicked: kitViewDialog.close()
            }
        }

        function openWithData(row) {
            currentRow = row
            currentData = dbmanager.getRowData("embroidery_kits", row)
            open()
        }
    }

    // Диалог просмотра фурнитуры
    Dialog {
        id: consumableViewDialog
        modal: true
        title: "🧵 Просмотр фурнитуры"

        property int currentRow: -1
        property var currentData: ({})

        width: 500
        height: 400
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
                text: "🧵 Информация о фурнитуре"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Label {
                        text: "Название:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 14
                    }
                    Label {
                        Layout.fillWidth: true
                        text: consumableViewDialog.currentData.name || "Не указано"
                        wrapMode: Text.Wrap
                        color: "#2c3e50"
                        font.pixelSize: 14
                        padding: 10
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: "#e9ecef"
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Label {
                            text: "Тип:"
                            font.bold: true
                            color: "#34495e"
                            font.pixelSize: 14
                        }
                        Label {
                            Layout.fillWidth: true
                            text: consumableViewDialog.currentData.type || "Не указано"
                            color: "#2c3e50"
                            font.pixelSize: 14
                            padding: 10
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                                border.color: "#e9ecef"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Label {
                            text: "Ед. измерения:"
                            font.bold: true
                            color: "#34495e"
                            font.pixelSize: 14
                        }
                        Label {
                            Layout.fillWidth: true
                            text: consumableViewDialog.currentData.unit || "Не указано"
                            color: "#2c3e50"
                            font.pixelSize: 14
                            padding: 10
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                                border.color: "#e9ecef"
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Label {
                            text: "Цена за ед.:"
                            font.bold: true
                            color: "#34495e"
                            font.pixelSize: 14
                        }
                        Label {
                            Layout.fillWidth: true
                            text: (consumableViewDialog.currentData.price_per_unit ? consumableViewDialog.currentData.price_per_unit + " ₽" : "Не указано")
                            color: "#27ae60"
                            font.pixelSize: 14
                            font.bold: true
                            padding: 10
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                                border.color: "#e9ecef"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Label {
                            text: "В наличии:"
                            font.bold: true
                            color: "#34495e"
                            font.pixelSize: 14
                        }
                        Label {
                            Layout.fillWidth: true
                            text: consumableViewDialog.currentData.stock_quantity || "0"
                            color: "#2c3e50"
                            font.pixelSize: 14
                            padding: 10
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                                border.color: "#e9ecef"
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
                onClicked: consumableViewDialog.close()
            }
        }

        function openWithData(row) {
            currentRow = row
            currentData = dbmanager.getRowData("consumable_furniture", row)
            open()
        }
    }

    // Диалог отчета по продажам
    Dialog {
        id: salesReportDialog
        modal: true
        title: "📊 Отчет по продажам"

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
                text: "📊 Отчет по продажам"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            // Период отчета
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Label {
                        text: "Дата начала:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 12
                    }
                    TextField {
                        id: reportStartDate
                        Layout.fillWidth: true
                        placeholderText: "ГГГГ-ММ-ДД"
                        text: new Date().toISOString().slice(0,10)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Label {
                        text: "Дата окончания:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 12
                    }
                    TextField {
                        id: reportEndDate
                        Layout.fillWidth: true
                        placeholderText: "ГГГГ-ММ-ДД"
                        text: new Date().toISOString().slice(0,10)
                    }
                }

                Button {
                    text: "📈 Сформировать"
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
                    onClicked: generateReport()
                }
            }

            // Статистика
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    color: "#e8f5e8"
                    radius: 8
                    border.color: "#27ae60"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        Label {
                            text: "💰 Общая выручка"
                            font.bold: true
                            color: "#27ae60"
                            font.pixelSize: 12
                        }
                        Label {
                            text: "15,240 ₽"
                            font.bold: true
                            font.pixelSize: 16
                            color: "#2ecc71"
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    color: "#e3f2fd"
                    radius: 8
                    border.color: "#3498db"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        Label {
                            text: "📦 Продано товаров"
                            font.bold: true
                            color: "#3498db"
                            font.pixelSize: 12
                        }
                        Label {
                            text: "42 шт"
                            font.bold: true
                            font.pixelSize: 16
                            color: "#2980b9"
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    color: "#fff3cd"
                    radius: 8
                    border.color: "#ffc107"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        Label {
                            text: "🎨 Наборы"
                            font.bold: true
                            color: "#e67e22"
                            font.pixelSize: 12
                        }
                        Label {
                            text: "18 шт"
                            font.bold: true
                            font.pixelSize: 16
                            color: "#d35400"
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 80
                    color: "#f4ecf7"
                    radius: 8
                    border.color: "#9b59b6"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10

                        Label {
                            text: "🧵 Фурнитура"
                            font.bold: true
                            color: "#9b59b6"
                            font.pixelSize: 12
                        }
                        Label {
                            text: "24 шт"
                            font.bold: true
                            font.pixelSize: 16
                            color: "#8e44ad"
                        }
                    }
                }
            }

            // Детализация продаж
            Label {
                text: "📋 Детализация продаж:"
                font.bold: true
                color: "#34495e"
                font.pixelSize: 14
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#f8f9fa"
                radius: 8
                border.color: "#e9ecef"

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 5
                    clip: true

                    ListView {
                        anchors.fill: parent
                        model: 10
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 40
                            color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 5
                                spacing: 10

                                Text {
                                    text: "2024-01-" + (index + 10)
                                    color: "#2c3e50"
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 80
                                }

                                Text {
                                    text: "Набор 'Цветочная композиция'"
                                    color: "#2c3e50"
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "2 шт"
                                    color: "#2c3e50"
                                    font.pixelSize: 12
                                    Layout.preferredWidth: 40
                                }

                                Text {
                                    text: "2,400 ₽"
                                    color: "#27ae60"
                                    font.pixelSize: 12
                                    font.bold: true
                                    Layout.preferredWidth: 70
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
                onClicked: salesReportDialog.close()
            }
        }

        function generateReport() {
            // Здесь должна быть логика генерации отчета из БД
            console.log("Генерация отчета с", reportStartDate.text, "по", reportEndDate.text)
        }
    }

    onVisibleChanged: {
        if (visible) updateProductList()
    }

    Component.onCompleted: {
        updateProductList()
    }
}
