import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import databasemanager

Page {
    id: root
    property string currentTable: "frame_materials"
    property int selectedRow: -1

    // Добавьте эти валидаторы
    DoubleValidator {
        id: doubleValidator
        bottom: 0
    }

    IntValidator {
        id: intValidator
        bottom: 0
    }

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
            text: currentTable === "frame_materials" ? "📐 Материалы для рамок" : "🔩 Комплектующая фурнитура"
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

        // Переключение между таблицами
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

                Button {
                    text: "📐 Материалы рамок"
                    font.bold: true
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: root.currentTable === "frame_materials" ? "#3498db" : "#f8f9fa"
                        radius: 6
                        border.color: "#3498db"
                    }
                    contentItem: Text {
                        text: parent.text
                        color: root.currentTable === "frame_materials" ? "white" : "#3498db"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font: parent.font
                    }
                    onClicked: {
                        root.currentTable = "frame_materials"
                        refreshTable()
                    }
                }

                Button {
                    text: "🔩 Комплектующая фурнитура"
                    font.bold: true
                    Layout.fillWidth: true
                    background: Rectangle {
                        color: root.currentTable === "component_furniture" ? "#3498db" : "#f8f9fa"
                        radius: 6
                        border.color: "#3498db"
                    }
                    contentItem: Text {
                        text: parent.text
                        color: root.currentTable === "component_furniture" ? "white" : "#3498db"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font: parent.font
                    }
                    onClicked: {
                        root.currentTable = "component_furniture"
                        refreshTable()
                    }
                }

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "🔍 Поиск..."
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
                    model: currentTable === "frame_materials" ?
                           ["Название", "Тип", "Цена за м", "На складе", "Цвет", "Ширина"] :
                           ["Название", "Тип", "Цена за шт", "На складе"]

                    Rectangle {
                        width: tableview.width / (currentTable === "frame_materials" ? 6 : 4)
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

        // Таблица
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
                    model: productsModel

                    columnWidthProvider: function(column) {
                        var columnsCount = root.currentTable === "frame_materials" ? 6 : 4
                        return tableview.width / columnsCount
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
                                productViewDialog.openWithData(row)
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
                                if (root.currentTable === "frame_materials") {
                                    switch(column) {
                                        case 0: return model.name || ""
                                        case 1: return model.type || ""
                                        case 2: return (model.price_per_meter || 0) + " ₽"
                                        case 3: return (model.stock_quantity || 0) + " м"
                                        case 4: return model.color || ""
                                        case 5: return (model.width || 0) + " см"
                                        default: return ""
                                    }
                                } else {
                                    switch(column) {
                                        case 0: return model.name || ""
                                        case 1: return model.type || ""
                                        case 2: return (model.price_per_unit || 0) + " ₽"
                                        case 3: return (model.stock_quantity || 0) + " шт"
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

        // Кнопки управления
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            Button {
                text: "➕ Добавить"
                font.bold: true
                padding: 12
                Layout.preferredWidth: 120
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
                onClicked: productAddDialog.open()
            }

            Button {
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
        id: productsModel
    }

    function refreshTable() {
        console.log("Refreshing table for:", root.currentTable)
        productsModel.clear()

        var model = root.currentTable === "frame_materials" ?
                   dbmanager.getFrameMaterialsModel() :
                   dbmanager.getComponentFurnitureModel()

        if (!model) {
            console.log("Model is null!")
            return
        }

        console.log("Model row count:", model.rowCount())

        for (var i = 0; i < model.rowCount(); i++) {
            var productData = {}

            // Получаем данные через модель
            if (root.currentTable === "frame_materials") {
                productData = {
                    id: model.data(model.index(i, 0)),
                    name: model.data(model.index(i, 1)),
                    type: model.data(model.index(i, 2)),
                    price_per_meter: model.data(model.index(i, 3)),
                    stock_quantity: model.data(model.index(i, 4)),
                    color: model.data(model.index(i, 5)),
                    width: model.data(model.index(i, 6))
                }
            } else {
                productData = {
                    id: model.data(model.index(i, 0)),
                    name: model.data(model.index(i, 1)),
                    type: model.data(model.index(i, 2)),
                    price_per_unit: model.data(model.index(i, 3)),
                    stock_quantity: model.data(model.index(i, 4))
                }
            }

            // Применяем поиск
            var searchText = searchField.text.toLowerCase()
            if (searchText && !productData.name.toLowerCase().includes(searchText) &&
                !productData.type.toLowerCase().includes(searchText)) continue

            productsModel.append(productData)
        }
        console.log("Table refreshed, items in model:", productsModel.count)
    }

    // Диалог просмотра/редактирования
    Dialog {
        id: productViewDialog
        modal: true
        title: root.currentTable === "frame_materials" ? "📐 Данные материала" : "🔩 Данные фурнитуры"

        property int currentRow: -1
        property var currentData: ({})

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
                text: "👀 Просмотр данных"
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

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 15
                        rowSpacing: 10

                        // Общие поля
                        Label { text: "Название:"; font.bold: true; color: "#34495e" }
                        Label { text: productViewDialog.currentData.name || "Не указано"; Layout.fillWidth: true }

                        Label { text: "Тип:"; font.bold: true; color: "#34495e" }
                        Label { text: productViewDialog.currentData.type || "Не указано"; Layout.fillWidth: true }

                        // Специфичные поля для материалов рамок
                        Label {
                            text: root.currentTable === "frame_materials" ? "Цена за метр:" : "Цена за шт:"
                            font.bold: true; color: "#34495e"
                            visible: root.currentTable === "frame_materials" || root.currentTable === "component_furniture"
                        }
                        Label {
                            text: {
                                if (root.currentTable === "frame_materials")
                                    return (productViewDialog.currentData.price_per_meter || 0) + " ₽"
                                else
                                    return (productViewDialog.currentData.price_per_unit || 0) + " ₽"
                            }
                            Layout.fillWidth: true
                            visible: root.currentTable === "frame_materials" || root.currentTable === "component_furniture"
                        }

                        Label {
                            text: "На складе:"; font.bold: true; color: "#34495e"
                            visible: root.currentTable === "frame_materials" || root.currentTable === "component_furniture"
                        }
                        Label {
                            text: {
                                if (root.currentTable === "frame_materials")
                                    return (productViewDialog.currentData.stock_quantity || 0) + " м"
                                else
                                    return (productViewDialog.currentData.stock_quantity || 0) + " шт"
                            }
                            Layout.fillWidth: true
                            visible: root.currentTable === "frame_materials" || root.currentTable === "component_furniture"
                        }

                        // Только для материалов рамок
                        Label {
                            text: "Цвет:"; font.bold: true; color: "#34495e"
                            visible: root.currentTable === "frame_materials"
                        }
                        Label {
                            text: productViewDialog.currentData.color || "Не указан"
                            Layout.fillWidth: true
                            visible: root.currentTable === "frame_materials"
                        }

                        Label {
                            text: "Ширина:"; font.bold: true; color: "#34495e"
                            visible: root.currentTable === "frame_materials"
                        }
                        Label {
                            text: (productViewDialog.currentData.width || 0) + " см"
                            Layout.fillWidth: true
                            visible: root.currentTable === "frame_materials"
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
                text: "✏️ Изменить"
                font.bold: true
                padding: 12
                width: 120
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
                onClicked: {
                    productViewDialog.close()
                    productEditDialog.openWithData(productViewDialog.currentRow, productViewDialog.currentData)
                }
            }

            Button {
                text: "🗑️ Удалить"
                font.bold: true
                padding: 12
                width: 120
                background: Rectangle {
                    color: parent.down ? "#c0392b" : "#e74c3c"
                    radius: 8
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: parent.font
                }
                onClicked: deleteConfirmDialog.open()
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
                onClicked: productViewDialog.close()
            }
        }

        function openWithData(row) {
            currentRow = row
            // Используем соответствующий метод из DatabaseManager
            if (root.currentTable === "frame_materials") {
                currentData = dbmanager.getFrameMaterialRowData(row)
            } else {
                currentData = dbmanager.getComponentFurnitureRowData(row)
            }
            open()
        }
    }

    // Диалог добавления
    Dialog {
        id: productAddDialog
        modal: true
        title: root.currentTable === "frame_materials" ? "📐 Добавить материал" : "🔩 Добавить фурнитуру"

        width: 500
        height: root.currentTable === "frame_materials" ? 600 : 450
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
                text: "📝 Заполните информацию"
                font.bold: true
                font.pixelSize: 16
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
                        Layout.maximumWidth: 400
                        spacing: 12

                        // Общие поля
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
                                id: addNameField
                                Layout.fillWidth: true
                                placeholderText: "Введите название"
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                    border.color: addNameField.activeFocus ? "#3498db" : "#dce0e3"
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
                            TextField {
                                id: addTypeField
                                Layout.fillWidth: true
                                placeholderText: "Введите тип"
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                    border.color: addTypeField.activeFocus ? "#3498db" : "#dce0e3"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Label {
                                text: root.currentTable === "frame_materials" ? "Цена за метр (₽):" : "Цена за шт (₽):"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                            }
                            TextField {
                                id: addPriceField
                                Layout.fillWidth: true
                                placeholderText: "0.00"
                                validator: DoubleValidator { bottom: 0.01 }
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                    border.color: addPriceField.activeFocus ? "#3498db" : "#dce0e3"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Label {
                                text: root.currentTable === "frame_materials" ? "Количество на складе (м):" : "Количество на складе (шт):"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                            }
                            TextField {
                                id: addStockField
                                Layout.fillWidth: true
                                placeholderText: root.currentTable === "frame_materials" ? "0.0" : "0"
                                validator: root.currentTable === "frame_materials" ? doubleValidator : intValidator
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                    border.color: addStockField.activeFocus ? "#3498db" : "#dce0e3"
                                }
                            }
                        }

                        // Поля только для материалов рамок
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: root.currentTable === "frame_materials"

                            Label {
                                text: "Цвет:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                            }
                            TextField {
                                id: addColorField
                                Layout.fillWidth: true
                                placeholderText: "Введите цвет"
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                    border.color: addColorField.activeFocus ? "#3498db" : "#dce0e3"
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: root.currentTable === "frame_materials"

                            Label {
                                text: "Ширина (см):"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                            }
                            TextField {
                                id: addWidthField
                                Layout.fillWidth: true
                                placeholderText: "0.0"
                                validator: DoubleValidator { bottom: 0.1 }
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 6
                                    border.color: addWidthField.activeFocus ? "#3498db" : "#dce0e3"
                                }
                            }
                        }

                        Label {
                            id: addValidationError
                            Layout.fillWidth: true
                            Layout.preferredHeight: addValidationError.visible ? implicitHeight : 0
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
                onClicked: productAddDialog.reject()
            }

            Button {
                function validateAddForm() {
                    var errors = []

                    if (!addNameField.text.trim()) errors.push("• Введите название")
                    if (!addTypeField.text.trim()) errors.push("• Введите тип")

                    // Проверка цены
                    var price = parseFloat(addPriceField.text)
                    if (isNaN(price) || price <= 0) errors.push("• Введите корректную цену")

                    // Проверка количества
                    if (root.currentTable === "frame_materials") {
                        var stock = parseFloat(addStockField.text)
                        if (isNaN(stock) || stock < 0) errors.push("• Введите корректное количество")
                    } else {
                        var stockInt = parseInt(addStockField.text)
                        if (isNaN(stockInt) || stockInt < 0) errors.push("• Введите корректное количество")
                    }

                    if (root.currentTable === "frame_materials") {
                        if (!addColorField.text.trim()) errors.push("• Введите цвет")

                        var width = parseFloat(addWidthField.text)
                        if (isNaN(width) || width <= 0) errors.push("• Введите корректную ширину")
                    }

                    if (errors.length > 0) {
                        addValidationError.text = errors.join("\n")
                        addValidationError.visible = true
                        return false
                    }

                    addValidationError.visible = false
                    return true
                }
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
                    console.log("Кнопка Добавить нажата")
                    if (validateAddForm()) {
                        console.log("Валидация пройдена")
                        if (root.currentTable === "frame_materials") {
                            console.log("Добавляем материал рамки:", addNameField.text, addTypeField.text, addPriceField.text, addStockField.text, addColorField.text, addWidthField.text)
                            dbmanager.addFrameMaterial(
                                addNameField.text.trim(),
                                addTypeField.text.trim(),
                                parseFloat(addPriceField.text) || 0,
                                parseFloat(addStockField.text) || 0,
                                addColorField.text.trim(),
                                parseFloat(addWidthField.text) || 0
                            )
                        } else {
                            console.log("Добавляем комплектующую:", addNameField.text, addTypeField.text, addPriceField.text, addStockField.text)
                            dbmanager.addComponentFurniture(
                                addNameField.text.trim(),
                                addTypeField.text.trim(),
                                parseFloat(addPriceField.text) || 0,
                                parseInt(addStockField.text) || 0
                            )
                        }
                        refreshTable()
                        productAddDialog.close()
                        console.log("Диалог закрыт")
                    } else {
                        console.log("Валидация не пройдена")
                    }
                }
            }
        }

        onOpened: {
            addNameField.text = ""
            addTypeField.text = ""
            addPriceField.text = ""
            addStockField.text = ""
            addColorField.text = ""
            addWidthField.text = ""
            addValidationError.visible = false
            addNameField.forceActiveFocus()
        }
    }

    // Диалог редактирования (аналогичный добавлению, но с предзаполненными данными)
    Dialog {
        id: productEditDialog
        modal: true
        title: root.currentTable === "frame_materials" ? "📐 Редактировать материал" : "🔩 Редактировать фурнитуру"

        property int currentRow: -1
        property var currentData: ({})

        // Реализация аналогична productAddDialog, но с предзаполнением данных
        // Для краткости опускаю полный код, он очень похож на productAddDialog
    }

    // Диалог подтверждения удаления
    Dialog {
        id: deleteConfirmDialog
        modal: true
        title: "⚠️ Подтверждение удаления"
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
                text: "🗑️ Вы уверены, что хотите удалить эту запись?"
                wrapMode: Text.WordWrap
                font.pixelSize: 14
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                Layout.fillWidth: true
                text: "Это действие нельзя отменить."
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                color: "#7f8c8d"
                font.italic: true
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
                text: "❌ Нет"
                font.bold: true
                padding: 12
                width: 100
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
                onClicked: deleteConfirmDialog.reject()
            }

            Button {
                text: "✅ Да"
                font.bold: true
                padding: 12
                width: 100
                background: Rectangle {
                    color: parent.down ? "#c0392b" : "#e74c3c"
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
                    if (root.currentTable === "frame_materials") {
                        dbmanager.deleteFrameMaterial(productViewDialog.currentRow)
                    } else {
                        dbmanager.deleteComponentFurniture(productViewDialog.currentRow)
                    }
                    refreshTable()
                    productViewDialog.close()
                    deleteConfirmDialog.close()
                }
            }
        }
    }

    Component.onCompleted: refreshTable()

    onVisibleChanged: {
        if (visible) refreshTable()
    }
}
