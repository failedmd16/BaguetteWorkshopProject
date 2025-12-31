import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Database

Page {
    id: root
    property string currentTable: "frame_materials"
    property int selectedRow: -1

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
                    text: "Материалы рамок"
                    font.bold: true
                    font.pixelSize: 14
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
                    text: "Комплектующая фурнитура"
                    font.bold: true
                    font.pixelSize: 14
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
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                TableView {
                    id: tableview
                    anchors.fill: parent
                    clip: true
                    model: DatabaseManager.getTableModel(root.currentTable)

                    columnWidthProvider: function(column) {
                        var columnsCount = root.currentTable === "frame_materials" ? 6 : 4
                        return tableview.width / columnsCount
                    }

                    delegate: Rectangle {
                        implicitHeight: 45
                        color: row % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#e9ecef"
                        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#e9ecef" }

                        property var rowData: model ? DatabaseManager.getRowData(root.currentTable, row) : ({})

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
                                if (!parent.rowData) return ""

                                if (root.currentTable === "frame_materials") {
                                    switch(column) {
                                        case 0: return parent.rowData.name || ""
                                        case 1: return parent.rowData.type || ""
                                        case 2: return (parent.rowData.price_per_meter || 0).toFixed(2) + " ₽"
                                        case 3: return (parent.rowData.stock_quantity || 0) + " м"
                                        case 4: return parent.rowData.color || ""
                                        case 5: return (parent.rowData.width || 0) + " см"
                                        default: return ""
                                    }
                                } else {
                                    switch(column) {
                                        case 0: return parent.rowData.name || ""
                                        case 1: return parent.rowData.type || ""
                                        case 2: return (parent.rowData.price_per_unit || 0).toFixed(2) + " ₽"
                                        case 3: return (parent.rowData.stock_quantity || 0) + " шт"
                                        default: return ""
                                    }
                                }
                            }
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            color: "#2c3e50"
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            Button {
                id: addProductButton
                text: "Добавить"
                font.bold: true
                font.pixelSize: 14
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

                Shortcut {
                    sequence: "Ctrl+N"
                    onActivated: addProductButton.click()
                }
            }

            Button {
                id: refreshButton
                text: "Обновить"
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

                Shortcut {
                    sequence: "F5"
                    onActivated: refreshButton.click()
                }
            }
        }
    }

    function refreshTable() {
        tableview.model = DatabaseManager.getTableModel(root.currentTable)
    }

    Dialog {
        id: productViewDialog
        modal: true
        header: null
        width: 450
        height: 450
        anchors.centerIn: parent
        padding: 20

        property int currentRow: -1
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
                text: root.currentTable === "frame_materials" ? "Данные материала" : "Данные фурнитуры"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignTop
            }

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: detailsCol.implicitHeight + 30
                color: "#f8f9fa"
                radius: 10
                border.color: "#ecf0f1"

                ColumnLayout {
                    id: detailsCol
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
                            Layout.preferredWidth: 120
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
                        labelText: "Название:"
                        valueText: productViewDialog.currentData.name || "—"
                        isBold: true
                    }
                    DetailRow {
                        labelText: "Тип:"
                        valueText: productViewDialog.currentData.type || "—"
                    }
                    DetailRow {
                        labelText: "Цена:"
                        valueText: {
                             var price = (root.currentTable === "frame_materials") ?
                                productViewDialog.currentData.price_per_meter :
                                productViewDialog.currentData.price_per_unit
                             return (price ? price.toFixed(2) : "0.00") + " ₽"
                        }
                        valueColor: "#27ae60"
                        isBold: true
                    }
                    DetailRow {
                        labelText: "На складе:"
                        valueText: {
                            var stock = productViewDialog.currentData.stock_quantity || 0
                            var unit = (root.currentTable === "frame_materials") ? " м" : " шт"
                            return stock + unit
                        }
                    }
                    DetailRow {
                        visible: root.currentTable === "frame_materials"
                        labelText: "Цвет:"
                        valueText: productViewDialog.currentData.color || "—"
                    }
                    DetailRow {
                        visible: root.currentTable === "frame_materials"
                        labelText: "Ширина:"
                        valueText: (productViewDialog.currentData.width || 0) + " см"
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 15

                Button {
                    text: "Изменить"
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 40
                    background: Rectangle {
                        color: parent.down ? "#f39c12" : "#f1c40f"
                        radius: 8
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: 14
                    }
                    onClicked: {
                        productViewDialog.close()
                        productEditDialog.openWithData(productViewDialog.currentRow, productViewDialog.currentData)
                    }
                }

                Button {
                    text: "Удалить"
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 40
                    background: Rectangle {
                        color: parent.down ? "#c0392b" : "#e74c3c"
                        radius: 8
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: 14
                    }
                    onClicked: deleteConfirmDialog.open()
                }

                Button {
                    text: "Закрыть"
                    Layout.preferredWidth: 110
                    Layout.preferredHeight: 40
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
                        font.pixelSize: 14
                    }
                    onClicked: productViewDialog.close()
                }
            }
        }

        function openWithData(row) {
            currentRow = row
            currentData = DatabaseManager.getRowData(root.currentTable, row)
            open()
        }
    }

    Dialog {
        id: productEditDialog
        modal: true
        header: null
        width: 450
        height: 550
        anchors.centerIn: parent
        padding: 20

        property int currentRow: -1
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
                text: root.currentTable === "frame_materials" ? "Редактировать материал" : "Редактировать фурнитуру"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignTop
            }

            Item { Layout.fillHeight: true }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                spacing: 12

                component InputField: ColumnLayout {
                    property alias label: labelItem.text
                    property alias placeholder: fieldItem.placeholderText
                    property alias text: fieldItem.text
                    property alias validator: fieldItem.validator
                    property alias inputField: fieldItem

                    spacing: 4
                    Layout.alignment: Qt.AlignHCenter

                    Label {
                        id: labelItem
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 14
                    }
                    TextField {
                        id: fieldItem
                        Layout.preferredWidth: 300
                        font.pixelSize: 14
                        color: "black"
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: fieldItem.activeFocus ? "#3498db" : "#dce0e3"
                            border.width: 1
                        }
                    }
                }

                InputField {
                    id: editNameField
                    label: "Название:"
                    placeholder: "Введите название"
                }

                InputField {
                    id: editTypeField
                    label: "Тип:"
                    placeholder: "Введите тип"
                }

                InputField {
                    id: editPriceField
                    label: root.currentTable === "frame_materials" ? "Цена за метр (₽):" : "Цена за шт (₽):"
                    placeholder: "0.00"
                    validator: DoubleValidator { bottom: 0.01 }
                }

                InputField {
                    id: editStockField
                    label: root.currentTable === "frame_materials" ? "На складе (м):" : "На складе (шт):"
                    placeholder: "0"
                    validator: root.currentTable === "frame_materials" ? doubleValidator : intValidator
                }

                InputField {
                    id: editColorField
                    visible: root.currentTable === "frame_materials"
                    label: "Цвет:"
                    placeholder: "Введите цвет"
                }

                InputField {
                    id: editWidthField
                    visible: root.currentTable === "frame_materials"
                    label: "Ширина (см):"
                    placeholder: "0.0"
                    validator: DoubleValidator { bottom: 0.1 }
                }

                Label {
                    id: editValidationError
                    Layout.preferredWidth: 300
                    Layout.alignment: Qt.AlignHCenter
                    color: "#e74c3c"
                    visible: false
                    wrapMode: Text.WordWrap
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 15

                Button {
                    text: "Отмена"
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 40
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
                        font.pixelSize: 14
                    }
                    onClicked: productEditDialog.close()
                }

                Button {
                    text: "Сохранить"
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 40
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
                        font.pixelSize: 14
                    }
                    onClicked: {
                        if (validateEditForm()) {
                            if (root.currentTable === "frame_materials") {
                                DatabaseManager.updateFrameMaterial(
                                    productEditDialog.currentRow,
                                    editNameField.text.trim(),
                                    editTypeField.text.trim(),
                                    parseFloat(editPriceField.text) || 0,
                                    parseFloat(editStockField.text) || 0,
                                    editColorField.text.trim(),
                                    parseFloat(editWidthField.text) || 0
                                )
                            } else {
                                DatabaseManager.updateComponentFurniture(
                                    productEditDialog.currentRow,
                                    editNameField.text.trim(),
                                    editTypeField.text.trim(),
                                    parseFloat(editPriceField.text) || 0,
                                    parseInt(editStockField.text) || 0
                                )
                            }
                            refreshTable()
                            productEditDialog.close()
                        }
                    }

                    function validateEditForm() {
                        var errors = []
                        if (!editNameField.text.trim()) errors.push("• Введите название")
                        if (!editTypeField.text.trim()) errors.push("• Введите тип")
                        var price = parseFloat(editPriceField.text)
                        if (isNaN(price) || price <= 0) errors.push("• Введите корректную цену")

                        if (root.currentTable === "frame_materials") {
                            var stock = parseFloat(editStockField.text)
                            if (isNaN(stock) || stock < 0) errors.push("• Введите корректное количество")
                            if (!editColorField.text.trim()) errors.push("• Введите цвет")
                            var width = parseFloat(editWidthField.text)
                            if (isNaN(width) || width <= 0) errors.push("• Введите ширину")
                        } else {
                            var stockInt = parseInt(editStockField.text)
                            if (isNaN(stockInt) || stockInt < 0) errors.push("• Введите корректное количество")
                        }

                        if (errors.length > 0) {
                            editValidationError.text = errors.join("\n")
                            editValidationError.visible = true
                            return false
                        }
                        return true
                    }
                }
            }
        }

        function openWithData(row, data) {
            currentRow = row
            currentData = data
            editNameField.text = data.name || ""
            editTypeField.text = data.type || ""

            if (root.currentTable === "frame_materials") {
                editPriceField.text = data.price_per_meter || ""
                editStockField.text = data.stock_quantity || ""
                editColorField.text = data.color || ""
                editWidthField.text = data.width || ""
            } else {
                editPriceField.text = data.price_per_unit || ""
                editStockField.text = data.stock_quantity || ""
            }

            editValidationError.visible = false
            open()
            editNameField.inputField.forceActiveFocus()
        }
    }

    Dialog {
        id: productAddDialog
        modal: true
        header: null
        width: 450
        height: 550
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
                Layout.fillWidth: true
                text: root.currentTable === "frame_materials" ? "Новый материал" : "Новая фурнитура"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignTop
            }

            Item { Layout.fillHeight: true }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                spacing: 12

                component InputFieldAdd: ColumnLayout {
                    property alias label: labelItemAdd.text
                    property alias placeholder: fieldItemAdd.placeholderText
                    property alias text: fieldItemAdd.text
                    property alias validator: fieldItemAdd.validator
                    property alias inputField: fieldItemAdd

                    spacing: 4
                    Layout.alignment: Qt.AlignHCenter

                    Label {
                        id: labelItemAdd
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 14
                    }
                    TextField {
                        id: fieldItemAdd
                        Layout.preferredWidth: 300
                        font.pixelSize: 14
                        color: "black"
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: fieldItemAdd.activeFocus ? "#3498db" : "#dce0e3"
                            border.width: 1
                        }
                    }
                }

                InputFieldAdd {
                    id: addNameField
                    label: "Название:"
                    placeholder: "Введите название"
                }

                InputFieldAdd {
                    id: addTypeField
                    label: "Тип:"
                    placeholder: "Введите тип"
                }

                InputFieldAdd {
                    id: addPriceField
                    label: root.currentTable === "frame_materials" ? "Цена за метр (₽):" : "Цена за шт (₽):"
                    placeholder: "0.00"
                    validator: DoubleValidator { bottom: 0.01 }
                }

                InputFieldAdd {
                    id: addStockField
                    label: root.currentTable === "frame_materials" ? "На складе (м):" : "На складе (шт):"
                    placeholder: "0"
                    validator: root.currentTable === "frame_materials" ? doubleValidator : intValidator
                }

                InputFieldAdd {
                    id: addColorField
                    visible: root.currentTable === "frame_materials"
                    label: "Цвет:"
                    placeholder: "Введите цвет"
                }

                InputFieldAdd {
                    id: addWidthField
                    visible: root.currentTable === "frame_materials"
                    label: "Ширина (см):"
                    placeholder: "0.0"
                    validator: DoubleValidator { bottom: 0.1 }
                }

                Label {
                    id: addValidationError
                    Layout.preferredWidth: 300
                    Layout.alignment: Qt.AlignHCenter
                    color: "#e74c3c"
                    visible: false
                    wrapMode: Text.WordWrap
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 15

                Button {
                    text: "Отмена"
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 40
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
                        font.pixelSize: 14
                    }
                    onClicked: productAddDialog.reject()
                }

                Button {
                    text: "Создать"
                    Layout.preferredWidth: 120
                    Layout.preferredHeight: 40
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
                        font.pixelSize: 14
                    }
                    onClicked: {
                        if (validateAddForm()) {
                            if (root.currentTable === "frame_materials") {
                                DatabaseManager.addFrameMaterial(
                                    addNameField.text.trim(),
                                    addTypeField.text.trim(),
                                    parseFloat(addPriceField.text) || 0,
                                    parseFloat(addStockField.text) || 0,
                                    addColorField.text.trim(),
                                    parseFloat(addWidthField.text) || 0
                                )
                            } else {
                                DatabaseManager.addComponentFurniture(
                                    addNameField.text.trim(),
                                    addTypeField.text.trim(),
                                    parseFloat(addPriceField.text) || 0,
                                    parseInt(addStockField.text) || 0
                                )
                            }
                            refreshTable()
                            productAddDialog.close()
                        }
                    }

                    function validateAddForm() {
                        var errors = []
                        if (!addNameField.text.trim()) errors.push("• Введите название")
                        if (!addTypeField.text.trim()) errors.push("• Введите тип")
                        var price = parseFloat(addPriceField.text)
                        if (isNaN(price) || price <= 0) errors.push("• Введите корректную цену")

                        if (root.currentTable === "frame_materials") {
                            var stock = parseFloat(addStockField.text)
                            if (isNaN(stock) || stock < 0) errors.push("• Введите корректное количество")
                            if (!addColorField.text.trim()) errors.push("• Введите цвет")
                            var width = parseFloat(addWidthField.text)
                            if (isNaN(width) || width <= 0) errors.push("• Введите ширину")
                        } else {
                            var stockInt = parseInt(addStockField.text)
                            if (isNaN(stockInt) || stockInt < 0) errors.push("• Введите корректное количество")
                        }

                        if (errors.length > 0) {
                            addValidationError.text = errors.join("\n")
                            addValidationError.visible = true
                            return false
                        }
                        return true
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
            addNameField.inputField.forceActiveFocus()
        }
    }

    Dialog {
        id: deleteConfirmDialog
        modal: true
        header: null
        width: 350
        height: 200
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
                Layout.fillWidth: true
                text: "Удаление"
                font.bold: true
                font.pixelSize: 18
                color: "#c0392b"
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                Layout.fillWidth: true
                text: "Вы действительно хотите удалить эту запись? Это действие необратимо."
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                color: "#2c3e50"
                font.pixelSize: 14
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

                Button {
                    text: "Нет"
                    Layout.preferredWidth: 100
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
                    onClicked: deleteConfirmDialog.close()
                }

                Button {
                    text: "Да, удалить"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 40
                    background: Rectangle {
                        color: parent.down ? "#c0392b" : "#e74c3c"
                        radius: 8
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (root.currentTable === "frame_materials") {
                            DatabaseManager.deleteFrameMaterial(productViewDialog.currentRow)
                        } else {
                            DatabaseManager.deleteComponentFurniture(productViewDialog.currentRow)
                        }
                        refreshTable()
                        productViewDialog.close()
                        deleteConfirmDialog.close()
                    }
                }
            }
        }
    }

    Component.onCompleted: refreshTable()

    onVisibleChanged: {
        if (visible) refreshTable()
    }

    function formatDate(dateString) {
        if (!dateString) return "Не указана"
        var date = new Date(dateString)
        if (isNaN(date.getTime())) return "Неверная дата"
        return date.toLocaleDateString(Qt.locale("ru_RU"), "dd.MM.yyyy HH:mm")
    }
}
