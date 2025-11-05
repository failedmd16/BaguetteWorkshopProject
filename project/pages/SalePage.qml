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
                    onCheckedButtonChanged: updateProductList()
                }

                RadioButton {
                    id: kitsRadio
                    text: "🎨 Наборы для вышивки"
                    checked: true
                    ButtonGroup.group: productTypeGroup
                }

                RadioButton {
                    id: consumablesRadio
                    text: "🧵 Расходная фурнитура"
                    ButtonGroup.group: productTypeGroup
                }
            }
        }

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
                    model: productTypeGroup.checkedButton === kitsRadio ?
                           ["ID", "Название", "Описание", "Цена", "В наличии"] :
                           ["ID", "Название", "Тип", "Цена за ед.", "В наличии", "Ед. изм."]

                    Rectangle {
                        width: tableview.width / (productTypeGroup.checkedButton === kitsRadio ? 5 : 6)
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
                    model: productTypeGroup.checkedButton === kitsRadio ?
                           dbmanager.getTableModel("embroidery_kits") :
                           dbmanager.getTableModel("consumable_furniture")

                    property int columnCount: productTypeGroup.checkedButton === kitsRadio ? 5 : 6

                    columnWidthProvider: function(column) {
                        return tableview.width / columnCount
                    }

                    delegate: Rectangle {
                        implicitHeight: 45
                        color: row % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#e9ecef"

                        property var rowData: model ? (productTypeGroup.checkedButton === kitsRadio ?
                                              dbmanager.getRowData("embroidery_kits", row) :
                                              dbmanager.getRowData("consumable_furniture", row)) : ({})

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedRow = row
                                productEditDialog.openWithData(row, productTypeGroup.checkedButton === kitsRadio)
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: parent.containsMouse ? "#e3f2fd" : "transparent"
                            }
                        }

                        Text {
                            anchors.fill: parent
                            anchors.margins: 8
                            text: {
                                if (!parent.rowData) return ""

                                if (productTypeGroup.checkedButton === kitsRadio) {
                                    switch(column) {
                                        case 0: return parent.rowData.id || "—"
                                        case 1: return parent.rowData.name || "—"
                                        case 2: return parent.rowData.description || "—"
                                        case 3: return parent.rowData.price ? parent.rowData.price + " ₽" : "—"
                                        case 4: return parent.rowData.stock_quantity || "0"
                                        default: return ""
                                    }
                                } else {
                                    switch(column) {
                                        case 0: return parent.rowData.id || "—"
                                        case 1: return parent.rowData.name || "—"
                                        case 2: return parent.rowData.type || "—"
                                        case 3: return parent.rowData.price_per_unit ? parent.rowData.price_per_unit + " ₽" : "—"
                                        case 4: return parent.rowData.stock_quantity || "0"
                                        case 5: return parent.rowData.unit || "—"
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

        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignRight

                Button {
                    text: "➕ Добавить товар"
                    font.bold: true
                    font.pixelSize: 14
                    padding: 12
                    Layout.preferredWidth: 200
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
                        if (productTypeGroup.checkedButton === kitsRadio) {
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
                    Layout.preferredWidth: 200
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
    }

    Dialog {
        id: productEditDialog
        modal: true
        title: "✏️ Редактирование товара"

        property int currentRow: -1
        property bool isKit: true
        property var currentData: ({})

        width: 500
        height: 550
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
                text: productEditDialog.isKit ? "🎨 Редактирование набора" : "🧵 Редактирование фурнитуры"
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
                    spacing: 6

                    Label {
                        text: "Название:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                    }
                    TextField {
                        id: editNameField
                        Layout.fillWidth: true
                        placeholderText: "Введите название"
                        font.pixelSize: 14
                        padding: 10
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: editNameField.activeFocus ? "#3498db" : "#dce0e3"
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: productEditDialog.isKit

                    Label {
                        text: "Описание:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                    }
                    TextArea {
                        id: editDescriptionField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        placeholderText: "Введите описание набора"
                        font.pixelSize: 14
                        padding: 10
                        wrapMode: TextArea.Wrap
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: editDescriptionField.activeFocus ? "#3498db" : "#dce0e3"
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    visible: !productEditDialog.isKit

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
                            id: editTypeField
                            Layout.fillWidth: true
                            model: ["инструменты", "материалы", "аксессуары", "прочее"]

                            contentItem: Text {
                                text: editTypeField.displayText
                                color: "#000000"
                                font: editTypeField.font
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
                                elide: Text.ElideRight
                                leftPadding: 12
                            }

                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 6
                                border.color: editTypeField.activeFocus ? "#3498db" : "#dce0e3"
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
                            id: editUnitField
                            Layout.fillWidth: true
                            model: ["шт", "набор", "метр", "упаковка"]

                            contentItem: Text {
                                text: editUnitField.displayText
                                color: "#000000"
                                font: editUnitField.font
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
                                elide: Text.ElideRight
                                leftPadding: 12
                            }

                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 6
                                border.color: editUnitField.activeFocus ? "#3498db" : "#dce0e3"
                            }
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
                            text: productEditDialog.isKit ? "Цена (₽):" : "Цена за ед. (₽):"
                            font.bold: true
                            color: "#34495e"
                            font.pixelSize: 13
                        }
                        TextField {
                            id: editPriceField
                            Layout.fillWidth: true
                            placeholderText: "0.00"
                            font.pixelSize: 14
                            padding: 10
                            validator: DoubleValidator { bottom: 0; decimals: 2 }
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 6
                                border.color: editPriceField.activeFocus ? "#3498db" : "#dce0e3"
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
                            id: editQuantityField
                            Layout.fillWidth: true
                            from: 0
                            to: 10000
                            value: 0
                        }
                    }
                }

                Label {
                    id: editValidationError
                    Layout.fillWidth: true
                    Layout.preferredHeight: editValidationError.visible ? implicitHeight : 0
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

        footer: Rectangle {
                implicitHeight: 80
                color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    // Кнопка удаления (слева)
                    Button {
                        text: "🗑️ Удалить"
                        font.bold: true
                        padding: 12
                        Layout.preferredWidth: 120
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
                            deleteConfirmationDialog.open()
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // Кнопки отмены и сохранения (справа)
                    RowLayout {
                        spacing: 10

                        Button {
                            text: "❌ Отмена"
                            font.bold: true
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
                            onClicked: productEditDialog.reject()
                        }

                        Button {
                            text: "💾 Сохранить"
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
                            onClicked: {
                                if (productEditDialog.validateForm()) {
                                    if (productEditDialog.isKit) {
                                        dbmanager.updateEmbroideryKit(
                                            productEditDialog.currentData.id,
                                            editNameField.text,
                                            editDescriptionField.text,
                                            parseFloat(editPriceField.text),
                                            editQuantityField.value
                                        )
                                    } else {
                                        dbmanager.updateConsumableFurniture(
                                            productEditDialog.currentData.id,
                                            editNameField.text,
                                            editTypeField.currentText,
                                            parseFloat(editPriceField.text),
                                            editQuantityField.value,
                                            editUnitField.currentText
                                        )
                                    }
                                    updateProductList()
                                    productEditDialog.close()
                                }
                            }
                        }
                    }
                }
            }

        function validateForm() {
            const errors = []

            if (editNameField.text.trim().length < 2) {
                errors.push("• Название должно содержать минимум 2 символа")
            }

            if (parseFloat(editPriceField.text) <= 0) {
                errors.push("• Цена должна быть больше 0")
            }

            if (editQuantityField.value < 0) {
                errors.push("• Количество не может быть отрицательным")
            }

            if (errors.length > 0) {
                editValidationError.text = errors.join("\n")
                editValidationError.visible = true
                return false
            }

            editValidationError.visible = false
            return true
        }

        function openWithData(row, isKit) {
            productEditDialog.currentRow = row
            productEditDialog.isKit = isKit

            productEditDialog.currentData = isKit ?
                dbmanager.getRowData("embroidery_kits", row) :
                dbmanager.getRowData("consumable_furniture", row)

            if (productEditDialog.currentData) {
                loadCurrentData()
                open()
            }
        }

        function loadCurrentData() {
            editNameField.text = productEditDialog.currentData.name || ""
            editPriceField.text = productEditDialog.isKit ?
                (productEditDialog.currentData.price || "") :
                (productEditDialog.currentData.price_per_unit || "")
            editQuantityField.value = productEditDialog.currentData.stock_quantity || 0

            if (productEditDialog.isKit) {
                editDescriptionField.text = productEditDialog.currentData.description || ""
            } else {
                var typeIndex = ["инструменты", "материалы", "аксессуары", "прочее"].indexOf(productEditDialog.currentData.type || "")
                editTypeField.currentIndex = typeIndex >= 0 ? typeIndex : 0

                var unitIndex = ["шт", "набор", "метр", "упаковка"].indexOf(productEditDialog.currentData.unit || "")
                editUnitField.currentIndex = unitIndex >= 0 ? unitIndex : 0
            }
        }

        onOpened: {
            editValidationError.visible = false
        }
    }

    Dialog {
        id: deleteConfirmationDialog
        modal: true
        title: "🗑️ Удаление товара"
        width: 400
        height: 200
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
                text: "Вы уверены, что хотите удалить этот товар?"
                wrapMode: Text.WordWrap
                font.pixelSize: 16
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                Layout.fillWidth: true
                text: "Товар: " + (productEditDialog.currentData ? productEditDialog.currentData.name : "")
                wrapMode: Text.WordWrap
                font.pixelSize: 14
                color: "#e74c3c"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                Layout.fillWidth: true
                text: "Это действие нельзя отменить!"
                wrapMode: Text.WordWrap
                font.pixelSize: 12
                color: "#7f8c8d"
                horizontalAlignment: Text.AlignHCenter
            }
        }

        // ЗАМЕНИТЕ footer НА ЭТОТ КОД:
        footer: Rectangle {
            implicitHeight: 80
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 20

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "❌ Отмена"
                    font.bold: true
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
                    onClicked: deleteConfirmationDialog.reject()
                }

                Button {
                    text: "🗑️ Удалить"
                    font.bold: true
                    padding: 12
                    Layout.preferredWidth: 120
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
                        if (productEditDialog.isKit) {
                            // Используем удаление вместо деактивации
                            dbmanager.deleteEmbroideryKit(productEditDialog.currentData.id)
                        } else {
                            dbmanager.deleteConsumableFurniture(productEditDialog.currentData.id)
                        }
                        updateProductList()
                        deleteConfirmationDialog.close()
                        productEditDialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: saleDialog
        modal: true
        title: "🛒 Оформление продажи"

        property double unitPrice: 0
        property int availableStock: 0
        property int productId: -1
        property bool isKit: true

        width: 600
        height: 500
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
                text: "🛒 Оформление продажи товара"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Label {
                    text: productTypeGroup.checkedButton === kitsRadio ? "🎨 Товар:" : "🧵 Товар:"
                    font.bold: true
                    color: "#34495e"
                    font.pixelSize: 14
                }

                ComboBox {
                    id: productComboBox
                    Layout.fillWidth: true
                    model: ListModel {
                        id: productsComboModel
                    }
                    textRole: "display"

                    onActivated: {
                        saleDialog.updateProductInfo()
                    }

                    contentItem: Text {
                        text: productComboBox.displayText
                        color: "#000000"
                        font: productComboBox.font
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignLeft
                        elide: Text.ElideRight
                        leftPadding: 12
                    }

                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: productComboBox.activeFocus ? "#3498db" : "#dce0e3"
                    }

                    onCurrentIndexChanged: saleDialog.updateProductInfo()
                }
            }

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
                            text: saleDialog.unitPrice.toFixed(2) + " ₽"
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
                    onValueChanged: saleDialog.updateTotalAmount()
                }
            }

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
                onClicked: saleDialog.processSale()
            }
        }

        function updateProductInfo() {
            if (productComboBox.currentIndex >= 0) {
                var currentItem = productsComboModel.get(productComboBox.currentIndex)
                if (currentItem) {
                    saleDialog.unitPrice = currentItem.price || 0
                    saleDialog.availableStock = currentItem.stock_quantity || 0
                    saleDialog.productId = currentItem.id || -1
                    saleDialog.isKit = productTypeGroup.checkedButton === kitsRadio
                    quantitySpinBox.to = Math.max(saleDialog.availableStock, 1)
                    updateTotalAmount()
                }
            }
        }

        function updateTotalAmount() {
            var total = saleDialog.unitPrice * quantitySpinBox.value
            totalAmountLabel.text = total.toFixed(2) + " ₽"
        }

        function processSale() {
            if (saleDialog.validateSaleForm()) {
                var productItem = productsComboModel.get(productComboBox.currentIndex)
                var productId = productItem ? productItem.id : -1
                var productName = productItem ? productItem.name : ""
                var quantity = quantitySpinBox.value
                var totalAmount = saleDialog.unitPrice * quantity

                var newStock = saleDialog.availableStock - quantity
                if (saleDialog.isKit) {
                    dbmanager.updateEmbroideryKitStock(productId, newStock)
                } else {
                    dbmanager.updateConsumableStock(productId, newStock)
                }

                saleDialog.close()
                saleSuccessDialog.openWithData(productName, quantity, totalAmount)
            }
        }

        function validateSaleForm() {
            const errors = []

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

            productsComboModel.clear()

            var tableName = productTypeGroup.checkedButton === kitsRadio ? "embroidery_kits" : "consumable_furniture"
            var rowCount = dbmanager.getRowCount(tableName)

            for (var i = 0; i < rowCount; i++) {
                var item = dbmanager.getRowData(tableName, i)
                if (item) {
                    if (productTypeGroup.checkedButton === kitsRadio) {
                        productsComboModel.append({
                            id: item.id,
                            name: item.name,
                            display: item.name + " - " + (item.price || 0) + " ₽",
                            price: item.price,
                            stock_quantity: item.stock_quantity
                        })
                    } else {
                        productsComboModel.append({
                            id: item.id,
                            name: item.name,
                            display: item.name + " - " + (item.price_per_unit || 0) + " ₽",
                            price: item.price_per_unit,
                            stock_quantity: item.stock_quantity
                        })
                    }
                }
            }

            updateProductInfo()
        }
    }

    Dialog {
        id: saleSuccessDialog
        modal: true
        title: "✅ Продажа оформлена"

        property string productName: ""
        property int quantity: 0
        property double totalAmount: 0

        width: 450
        height: 250
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

    Dialog {
        id: kitAddDialog
        modal: true
        title: "🎨 Добавить набор для вышивки"

        width: 500
        height: 450
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
                    if (kitAddDialog.validateKitForm()) {
                        dbmanager.addEmbroideryKit(addKitNameField.text, addKitDescriptionField.text, parseFloat(addKitPriceField.text), addKitQuantityField.value)
                        updateProductList()
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

    Dialog {
        id: consumableAddDialog
        modal: true
        title: "🧵 Добавить расходную фурнитуру"

        width: 500
        height: 500
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

                        contentItem: Text {
                            text: addConsumableTypeField.displayText
                            color: "#000000"
                            font: addConsumableTypeField.font
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            elide: Text.ElideRight
                            leftPadding: 12
                        }

                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: addConsumableTypeField.activeFocus ? "#3498db" : "#dce0e3"
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

                            contentItem: Text {
                                text: addConsumableUnitField.displayText
                                color: "#000000"
                                font: addConsumableUnitField.font
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignLeft
                                elide: Text.ElideRight
                                leftPadding: 12
                            }

                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 6
                                border.color: addConsumableUnitField.activeFocus ? "#3498db" : "#dce0e3"
                            }
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
                    if (consumableAddDialog.validateConsumableForm()) {
                        dbmanager.addConsumableFurniture(addConsumableNameField.text, addConsumableTypeField.currentText, parseFloat(addConsumablePriceField.text), addConsumableQuantityField.value, addConsumableUnitField.currentText)
                        updateProductList()
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

    function updateProductList() {
        tableview.model = productTypeGroup.checkedButton === kitsRadio ?
               dbmanager.getTableModel("embroidery_kits") :
               dbmanager.getTableModel("consumable_furniture")
    }

    onVisibleChanged: {
        if (visible) updateProductList()
    }

    Component.onCompleted: {
        updateProductList()
    }
}
