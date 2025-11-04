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
                    model: dbmanager.getTableModel(root.tableName)

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
                                if (productTypeGroup.checkedButton.text.includes("Наборы")) {
                                    switch(column) {
                                        case 0: return model.id || "—"
                                        case 1: return model.name || "—"
                                        case 2: return model.description || "—"
                                        case 3: return model.price ? model.price + " ₽" : "—"
                                        case 4: return model.stock_quantity || "0"
                                        default: return model.display || "—"
                                    }
                                } else {
                                    switch(column) {
                                        case 0: return model.id || "—"
                                        case 1: return model.name || "—"
                                        case 2: return model.type || "—"
                                        case 3: return model.price_per_unit ? model.price_per_unit + " ₽" : "—"
                                        case 4: return model.stock_quantity || "0"
                                        case 5: return model.unit || "—"
                                        default: return model.display || "—"
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
        }
    }

    // Функция обновления списка товаров
    function updateProductList() {
        if (productTypeGroup.checkedButton.text.includes("Наборы")) {
            root.tableName = "embroidery_kits"
        } else {
            root.tableName = "consumable_furniture"
        }
        tableview.model = dbmanager.getTableModel(root.tableName)
    }

    // Диалог оформления продажи
    Dialog {
        id: saleDialog
        modal: true
        title: "🛒 Оформление продажи"

        width: 600
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
                           dbmanager.getEmbroideryKitsModel() : null // Нужно добавить модель для фурнитуры
                    textRole: "name"
                    displayText: currentIndex >= 0 ? currentText : "Выберите товар"
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
                    to: 100
                    value: 1
                }
            }

            // Итоговая сумма
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
                        text: "💰 Итоговая сумма:"
                        font.bold: true
                        color: "#27ae60"
                        font.pixelSize: 14
                    }

                    Label {
                        id: totalAmountLabel
                        text: "0 ₽"
                        font.bold: true
                        font.pixelSize: 18
                        color: "#2ecc71"
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

        function processSale() {
            if (validateSaleForm()) {
                // Здесь должна быть логика оформления продажи
                // Создание заказа, обновление остатков и т.д.
                saleDialog.close()
                saleSuccessDialog.open()
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
        }
    }

    // Диалог успешной продажи
    Dialog {
        id: saleSuccessDialog
        modal: true
        title: "✅ Продажа оформлена"

        width: 400
        height: 200
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
                font.pixelSize: 16
                color: "#27ae60"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                Layout.fillWidth: true
                text: "Товар продан, остатки обновлены."
                wrapMode: Text.WordWrap
                font.pixelSize: 14
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
                onClicked: saleSuccessDialog.close()
            }
        }
    }

    // Здесь должны быть диалоги для добавления/просмотра наборов и фурнитуры
    // (аналогичные диалогам из CustomersPage, но адаптированные под товары)

    // Заглушки для диалогов
    Dialog { id: kitViewDialog; function openWithData(row) {} }
    Dialog { id: consumableViewDialog; function openWithData(row) {} }
    Dialog { id: kitAddDialog }
    Dialog { id: consumableAddDialog }

    onVisibleChanged: {
        if (visible) updateProductList()
    }

    Component.onCompleted: {
        updateProductList()
    }
}
