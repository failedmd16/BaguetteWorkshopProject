import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Database

Page {
    id: root
    property string currentTable: "frame_materials"
    property int selectedRow: -1
    property bool isLoading: false

    property var allMaterialsData: []

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

    MouseArea {
        anchors.fill: parent
        visible: root.isLoading
        hoverEnabled: true
        z: 99
        onClicked: {}
        BusyIndicator {
            anchors.centerIn: parent
            running: root.isLoading
        }
    }

    ListModel {
        id: materialsModel
    }

    Shortcut {
        sequence: "Ctrl+N"
        enabled: root.visible && !root.isLoading
        onActivated: {
            if (!productAddDialog.opened && !productEditDialog.opened)
                productAddDialog.open()
        }
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
            if (deleteConfirmDialog.opened) deleteConfirmDialog.close()
            else if (productAddDialog.opened) productAddDialog.close()
            else if (productEditDialog.opened) productEditDialog.close()
            else if (productViewDialog.opened) productViewDialog.close()
        }
    }

    Connections {
        target: DatabaseManager

        function onMaterialsLoaded(data) {
            root.allMaterialsData = data
            applyFilters()
            root.isLoading = false
        }

        function onMaterialOperationResult(success, message) {
            root.isLoading = false
            if (success) {
                refreshTable()
                if (productAddDialog.opened) productAddDialog.close()
                if (productEditDialog.opened) productEditDialog.close()
                if (deleteConfirmDialog.opened) deleteConfirmDialog.close()
                if (productViewDialog.opened) productViewDialog.close()
            } else {
                console.log("Error: " + message)
            }
        }
    }

    function refreshTable() {
        root.isLoading = true
        DatabaseManager.fetchMaterialsAsync(root.currentTable)
    }

    function applyFilters() {
        materialsModel.clear()
        var searchText = searchField.text.toLowerCase().trim()

        if (!root.allMaterialsData) return

        for (var i = 0; i < root.allMaterialsData.length; i++) {
            var item = root.allMaterialsData[i]

            if (searchText === "" || (item.name && item.name.toLowerCase().includes(searchText)))
                materialsModel.append(item)
        }
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
                    Layout.preferredWidth: 180
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
                    text: "Комплектующие"
                    font.bold: true
                    font.pixelSize: 14
                    Layout.preferredWidth: 180
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

                Item { Layout.fillWidth: true }

                TextField {
                    id: searchField
                    Layout.preferredWidth: 250
                    Layout.maximumWidth: 400
                    Layout.rightMargin: 10

                    placeholderText: "Поиск по названию..."
                    font.pixelSize: 14
                    color: "#000000"

                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 8
                        border.color: searchField.activeFocus ? "#3498db" : "#dce0e3"
                        border.width: 1
                    }

                    onTextChanged: applyFilters()
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

                ListView {
                    id: tableview
                    anchors.fill: parent
                    clip: true
                    model: materialsModel

                    delegate: Rectangle {
                        implicitHeight: 45
                        color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#e9ecef"
                        width: tableview.width
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: "#e9ecef"
                        }

                        property var rowData: materialsModel.get(index)

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedRow = index
                                productViewDialog.openWithData(index, parent.rowData)
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: parent.containsMouse ? "#e3f2fd" : "transparent"
                            }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 12

                            Repeater {
                                model: root.currentTable === "frame_materials" ? 6 : 4

                                Rectangle {
                                    width: tableview.width / (root.currentTable === "frame_materials" ? 6 : 4)
                                    height: parent.height
                                    color: "transparent"

                                    Text {
                                        anchors.fill: parent
                                        text: {
                                            if (!parent.parent.parent.rowData) return ""
                                            var d = parent.parent.parent.rowData

                                            if (root.currentTable === "frame_materials") {
                                                switch(index) {
                                                    case 0: return d.name || ""
                                                    case 1: return d.type || ""
                                                    case 2: return (d.price_per_meter || 0).toFixed(2) + " ₽"
                                                    case 3: return (d.stock_quantity || 0) + " м"
                                                    case 4: return d.color || ""
                                                    case 5: return (d.width || 0) + " см"
                                                    default: return ""
                                                }
                                            } else {
                                                switch(index) {
                                                    case 0: return d.name || ""
                                                    case 1: return d.type || ""
                                                    case 2: return (d.price_per_unit || 0).toFixed(2) + " ₽"
                                                    case 3: return (d.stock_quantity || 0) + " шт"
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

                ToolTip.delay: 1000
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Добавить новый материал (Ctrl+N)")
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

                ToolTip.delay: 1000
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: qsTr("Обновить таблицу (F5)")
            }
        }
    }

    Dialog {
        id: productViewDialog
        modal: true
        header: null
        width: 450
        height: 400
        anchors.centerIn: parent
        padding: 20

        property int currentRow: -1
        property var currentData: ({})

        property string displayPrice: "0.00 ₽"
        property string displayStock: "0"

        function updateDisplayStrings() {
            if (!currentData) {
                displayPrice = "0.00 ₽"
                displayStock = "0"
                return
            }

            var val = (root.currentTable === "frame_materials") ? currentData.price_per_meter : currentData.price_per_unit
            var num = parseFloat(val)
            displayPrice = (isNaN(num) ? "0.00" : num.toFixed(2)) + " ₽"

            var stock = currentData.stock_quantity || 0
            var unit = (root.currentTable === "frame_materials") ? " м" : " шт"
            displayStock = stock + unit
        }

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

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

                    DetailRow {
                        labelText: "Название:"
                        valueText: (productViewDialog.currentData && productViewDialog.currentData.name) ?
                                        productViewDialog.currentData.name : "—"
                        isBold: true
                    }
                    DetailRow {
                        labelText: "Тип:"
                        valueText: (productViewDialog.currentData && productViewDialog.currentData.type) ?
                                       productViewDialog.currentData.type : "—"
                    }

                    DetailRow {
                        labelText: "Цена:"
                        valueText: productViewDialog.displayPrice
                        valueColor: "#27ae60"
                        isBold: true
                    }
                    DetailRow {
                        labelText: "На складе:"
                        valueText: productViewDialog.displayStock
                    }

                    DetailRow {
                        visible: root.currentTable === "frame_materials"
                        labelText: "Цвет:"
                        valueText: (productViewDialog.currentData && productViewDialog.currentData.color) ?
                                       productViewDialog.currentData.color : "—"
                    }
                    DetailRow {
                        visible: root.currentTable === "frame_materials"
                        labelText: "Ширина:"
                        valueText: {
                            if (!productViewDialog.currentData) return "—"
                            return (productViewDialog.currentData.width || 0) + " см"
                        }
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
                        if (productViewDialog.currentData) {
                            var dataToPass = productViewDialog.currentData
                            productViewDialog.close()
                            productEditDialog.openWithData(productViewDialog.currentRow, dataToPass)
                        }
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

        function openWithData(row, data) {
            currentRow = row
            currentData = data || {}
            updateDisplayStrings()
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
                            root.isLoading = true
                            if (root.currentTable === "frame_materials") {
                                DatabaseManager.updateFrameMaterialAsync(
                                    productEditDialog.currentData.id,
                                    editNameField.text.trim(),
                                    editTypeField.text.trim(),
                                    parseFloat(editPriceField.text) || 0,
                                    parseFloat(editStockField.text) || 0,
                                    editColorField.text.trim(),
                                    parseFloat(editWidthField.text) || 0
                                )
                            } else {
                                DatabaseManager.updateComponentFurnitureAsync(
                                    productEditDialog.currentData.id,
                                    editNameField.text.trim(),
                                    editTypeField.text.trim(),
                                    parseFloat(editPriceField.text) || 0,
                                    parseInt(editStockField.text) || 0
                                )
                            }
                        }
                    }

                    function validateEditForm() {
                        var errors = []

                        if (!editNameField.text.trim())
                            errors.push("• Введите название")
                        if (!editTypeField.text.trim())
                            errors.push("• Введите тип")
                        var price = parseFloat(editPriceField.text)
                        if (isNaN(price) || price <= 0)
                            errors.push("• Введите корректную цену")

                        if (root.currentTable === "frame_materials") {
                            var stock = parseFloat(editStockField.text)
                            if (isNaN(stock) || stock < 0)
                                errors.push("• Введите корректное количество")
                            if (!editColorField.text.trim())
                                errors.push("• Введите цвет")
                            var width = parseFloat(editWidthField.text)
                            if (isNaN(width) || width <= 0)
                                errors.push("• Введите ширину")
                        } else {
                            var stockInt = parseInt(editStockField.text)
                            if (isNaN(stockInt) || stockInt < 0)
                                errors.push("• Введите корректное количество")
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
                    validator: DoubleValidator {
                        bottom: 0.01
                    }
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
                    validator: DoubleValidator {
                        bottom: 0.1
                    }
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
                            root.isLoading = true
                            if (root.currentTable === "frame_materials") {
                                DatabaseManager.addFrameMaterialAsync(
                                    addNameField.text.trim(),
                                    addTypeField.text.trim(),
                                    parseFloat(addPriceField.text) || 0,
                                    parseFloat(addStockField.text) || 0,
                                    addColorField.text.trim(),
                                    parseFloat(addWidthField.text) || 0
                                )
                            } else {
                                DatabaseManager.addComponentFurnitureAsync(
                                    addNameField.text.trim(),
                                    addTypeField.text.trim(),
                                    parseFloat(addPriceField.text) || 0,
                                    parseInt(addStockField.text) || 0
                                )
                            }
                        }
                    }

                    function validateAddForm() {
                        var errors = []
                        if (!addNameField.text.trim())
                            errors.push("• Введите название")
                        if (!addTypeField.text.trim())
                            errors.push("• Введите тип")
                        var price = parseFloat(addPriceField.text)
                        if (isNaN(price) || price <= 0)
                            errors.push("• Введите корректную цену")

                        if (root.currentTable === "frame_materials") {
                            var stock = parseFloat(addStockField.text)
                            if (isNaN(stock) || stock < 0)
                                errors.push("• Введите корректное количество")
                            if (!addColorField.text.trim())
                                errors.push("• Введите цвет")
                            var width = parseFloat(addWidthField.text)
                            if (isNaN(width) || width <= 0)
                                errors.push("• Введите ширину")
                        } else {
                            var stockInt = parseInt(addStockField.text)
                            if (isNaN(stockInt) || stockInt < 0)
                                errors.push("• Введите корректное количество")
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

            Item { Layout.fillHeight: true }

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
                        root.isLoading = true
                        if (root.currentTable === "frame_materials")
                            DatabaseManager.deleteFrameMaterialAsync(productViewDialog.currentData.id)
                        else
                            DatabaseManager.deleteComponentFurnitureAsync(productViewDialog.currentData.id)
                    }
                }
            }
        }
    }

    Component.onCompleted: refreshTable()

    onVisibleChanged: {
        if (visible) {
            forceActiveFocus()
            refreshTable()
        }
    }

    function formatDate(dateString) {
        if (!dateString)
            return "Не указана"
        var date = new Date(dateString)

        if (isNaN(date.getTime()))
            return "Неверная дата"

        return date.toLocaleDateString(Qt.locale("ru_RU"), "dd.MM.yyyy HH:mm")
    }
}
