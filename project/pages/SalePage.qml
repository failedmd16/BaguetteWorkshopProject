import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Database

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

        Label {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            text: "🛍️ Продажа наборов и фурнитуры"
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
                spacing: 20

                Label {
                    text: "Тип товара:"
                    font.bold: true
                    color: "#2c3e50"
                    font.pixelSize: 14
                    Layout.leftMargin: 10
                }

                ButtonGroup {
                    id: productTypeGroup
                    onCheckedButtonChanged: updateProductList()
                }

                Component {
                    id: radioStyle
                    RadioButton {
                        text: parent.text
                        checked: parent.checked
                        ButtonGroup.group: productTypeGroup

                        indicator: Rectangle {
                            implicitWidth: 20
                            implicitHeight: 20
                            x: parent.leftPadding
                            y: parent.height / 2 - height / 2
                            radius: 10
                            border.color: parent.checked ? "#3498db" : "#bdc3c7"
                            border.width: 2

                            Rectangle {
                                anchors.centerIn: parent
                                width: 10
                                height: 10
                                radius: 5
                                color: "#3498db"
                                visible: parent.parent.checked
                            }
                        }

                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: 14
                            color: "#2c3e50"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: parent.indicator.width + spacing
                        }
                    }
                }

                RadioButton {
                    id: kitsRadio
                    text: "Наборы для вышивки"
                    checked: true
                    ButtonGroup.group: productTypeGroup

                    indicator: Rectangle {
                        implicitWidth: 22
                        implicitHeight: 22
                        x: kitsRadio.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 11
                        border.color: kitsRadio.checked ? "#3498db" : "#bdc3c7"
                        border.width: 2

                        Rectangle {
                            anchors.centerIn: parent
                            width: 12
                            height: 12
                            radius: 6
                            color: "#3498db"
                            visible: kitsRadio.checked
                        }
                    }
                    contentItem: Text {
                        text: kitsRadio.text
                        font: kitsRadio.font
                        color: "#2c3e50"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: kitsRadio.indicator.width + kitsRadio.spacing
                    }
                }

                RadioButton {
                    id: consumablesRadio
                    text: "Расходная фурнитура"
                    ButtonGroup.group: productTypeGroup

                    indicator: Rectangle {
                        implicitWidth: 22
                        implicitHeight: 22
                        x: consumablesRadio.leftPadding
                        y: parent.height / 2 - height / 2
                        radius: 11
                        border.color: consumablesRadio.checked ? "#3498db" : "#bdc3c7"
                        border.width: 2

                        Rectangle {
                            anchors.centerIn: parent
                            width: 12
                            height: 12
                            radius: 6
                            color: "#3498db"
                            visible: consumablesRadio.checked
                        }
                    }
                    contentItem: Text {
                        text: consumablesRadio.text
                        font: consumablesRadio.font
                        color: "#2c3e50"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: consumablesRadio.indicator.width + consumablesRadio.spacing
                    }
                }

                Item {
                    Layout.fillWidth: true
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
                    model: productTypeGroup.checkedButton === kitsRadio ?
                        ["ID", "Название", "Описание", "Цена", "В наличии"] :
                        ["ID", "Название", "Тип", "Цена за ед.", "В наличии", "Ед. изм."]

                    Rectangle {
                        width: (parent.width - 5) / (productTypeGroup.checkedButton === kitsRadio ? 5 : 6)
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
                        DatabaseManager.getTableModel("embroidery_kits") :
                        DatabaseManager.getTableModel("consumable_furniture")

                    property int columnCount: productTypeGroup.checkedButton === kitsRadio ? 5 : 6

                    columnWidthProvider: function (column) {
                        return tableview.width / columnCount
                    }

                    delegate: Rectangle {
                        implicitHeight: 45
                        color: row % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#e9ecef"
                        border.width: 1

                        property var rowData: model ? (productTypeGroup.checkedButton === kitsRadio ?
                            DatabaseManager.getRowData("embroidery_kits", row) :
                            DatabaseManager.getRowData("consumable_furniture", row)) : ({})

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
                                    switch (column) {
                                    case 0:
                                        return parent.rowData.id || "—"
                                    case 1:
                                        return parent.rowData.name || "—"
                                    case 2:
                                        return parent.rowData.description || "—"
                                    case 3:
                                        return parent.rowData.price ? parent.rowData.price + " ₽" : "—"
                                    case 4:
                                        return parent.rowData.stock_quantity || "0"
                                    default:
                                        return ""
                                    }
                                } else {
                                    switch (column) {
                                    case 0:
                                        return parent.rowData.id || "—"
                                    case 1:
                                        return parent.rowData.name || "—"
                                    case 2:
                                        return parent.rowData.type || "—"
                                    case 3:
                                        return parent.rowData.price_per_unit ? parent.rowData.price_per_unit + " ₽" : "—"
                                    case 4:
                                        return parent.rowData.stock_quantity || "0"
                                    case 5:
                                        return parent.rowData.unit || "—"
                                    default:
                                        return ""
                                    }
                                }
                            }
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

        RowLayout {
            spacing: 15
            Layout.alignment: Qt.AlignRight

            Button {
                id: addProductButton
                text: "Добавить товар"
                font.bold: true
                font.pixelSize: 14
                padding: 12
                Layout.preferredWidth: 160
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
                text: "Оформить продажу"
                font.bold: true
                font.pixelSize: 14
                padding: 12
                Layout.preferredWidth: 160
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

    Dialog {
        id: productEditDialog
        modal: true
        header: null
        width: 420
        height: 420
        anchors.centerIn: parent
        padding: 0

        property int currentRow: -1
        property bool isKit: true
        property var currentData: ({})

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 12

            Label {
                Layout.fillWidth: true
                text: productEditDialog.isKit ? "Редактирование набора" : "Ред. фурнитуры"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
                Layout.bottomMargin: 5
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
                Label {
                    text: "Название:"
                    font.bold: true
                    color: "#34495e"
                    font.pixelSize: 13
                }
                TextField {
                    id: editNameField
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: parent.activeFocus ? "#3498db" : "#dce0e3"
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5
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
                    Layout.preferredHeight: 70
                    wrapMode: TextArea.Wrap
                    font.pixelSize: 14
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: parent.activeFocus ? "#3498db" : "#dce0e3"
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                visible: !productEditDialog.isKit

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 5
                    Label {
                        text: "Тип:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                    }
                    ComboBox {
                        id: editTypeField
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        model: ["инструменты", "материалы", "аксессуары", "прочее"]
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: "#dce0e3"
                        }
                        contentItem: Text {
                            text: editTypeField.displayText
                            font: editTypeField.font
                            color: "#000000"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 5
                    Label {
                        text: "Ед. изм.:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                    }
                    ComboBox {
                        id: editUnitField
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        model: ["шт", "набор", "метр", "упаковка"]
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: "#dce0e3"
                        }
                        contentItem: Text {
                            text: editUnitField.displayText
                            font: editUnitField.font
                            color: "#000000"
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 10
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 15

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 5
                    Label {
                        text: productEditDialog.isKit ? "Цена (₽):" : "Цена/ед. (₽):"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                    }
                    TextField {
                        id: editPriceField
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        validator: DoubleValidator {
                            bottom: 0
                            decimals: 2
                        }
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: parent.activeFocus ? "#3498db" : "#dce0e3"
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 5
                    Label {
                        text: "Количество:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                    }
                    SpinBox {
                        id: editQuantityField
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        from: 0
                        to: 10000
                        value: 0
                        editable: true

                        background: Rectangle {
                            color: "#f8f9fa"
                            border.color: editQuantityField.activeFocus ? "#3498db" : "#bdc3c7"
                            radius: 6
                        }

                        contentItem: TextInput {
                            z: 2
                            text: editQuantityField.textFromValue(editQuantityField.value, editQuantityField.locale)
                            font.pixelSize: 14
                            font.bold: true
                            color: "#2c3e50"
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            readOnly: !editQuantityField.editable
                            validator: editQuantityField.validator
                            inputMethodHints: Qt.ImhDigitsOnly
                        }

                        down.indicator: Rectangle {
                            x: 0
                            height: parent.height
                            width: height
                            radius: 6
                            color: editQuantityField.down.pressed ? "#bdc3c7" : "#e0e0e0"
                            border.color: "#bdc3c7"
                            Rectangle {
                                x: parent.width - radius
                                width: radius
                                height: parent.height
                                color: parent.color
                                visible: true
                            }
                            Text {
                                text: "-"
                                font.pixelSize: 18
                                font.bold: true
                                anchors.centerIn: parent
                                color: "#2c3e50"
                            }
                        }

                        up.indicator: Rectangle {
                            x: parent.width - width
                            height: parent.height
                            width: height
                            radius: 6
                            color: editQuantityField.up.pressed ? "#bdc3c7" : "#e0e0e0"
                            border.color: "#bdc3c7"
                            Rectangle {
                                x: 0
                                width: radius
                                height: parent.height
                                color: parent.color
                                visible: true
                            }
                            Text {
                                text: "+"
                                font.pixelSize: 18
                                font.bold: true
                                anchors.centerIn: parent
                                color: "#2c3e50"
                            }
                        }
                    }
                }
            }

            Label {
                id: editValidationError
                color: "#e74c3c"
                visible: false
                font.pixelSize: 13
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Layout.topMargin: 10

                Button {
                    text: "Удалить"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 38
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
                        font.pixelSize: 13
                    }
                    onClicked: deleteConfirmationDialog.open()
                }

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "Отмена"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 38
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
                        font.pixelSize: 13
                    }
                    onClicked: productEditDialog.close()
                }

                Button {
                    text: "Сохранить"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 38
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
                        font.pixelSize: 13
                    }
                    onClicked: {
                        if (productEditDialog.validateForm()) {
                            if (productEditDialog.isKit) {
                                DatabaseManager.updateEmbroideryKit(
                                    productEditDialog.currentData.id,
                                    editNameField.text,
                                    editDescriptionField.text,
                                    parseFloat(editPriceField.text),
                                    editQuantityField.value
                                )
                            } else {
                                DatabaseManager.updateConsumableFurniture(
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

        function validateForm() {
            var errors = []
            if (editNameField.text.trim().length < 2) errors.push("• Название слишком короткое")
            if (parseFloat(editPriceField.text) <= 0) errors.push("• Цена должна быть > 0")
            if (editQuantityField.value < 0) errors.push("• Неверное количество")

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
            productEditDialog.currentData = isKit ? DatabaseManager.getRowData("embroidery_kits", row) : DatabaseManager.getRowData("consumable_furniture", row)
            loadCurrentData()
            open()
        }

        function loadCurrentData() {
            editNameField.text = productEditDialog.currentData.name || ""
            editPriceField.text = productEditDialog.isKit ? (productEditDialog.currentData.price || "") : (productEditDialog.currentData.price_per_unit || "")
            editQuantityField.value = productEditDialog.currentData.stock_quantity || 0
            editValidationError.visible = false

            if (productEditDialog.isKit) {
                editDescriptionField.text = productEditDialog.currentData.description || ""
            } else {
                var typeIndex = ["инструменты", "материалы", "аксессуары", "прочее"].indexOf(productEditDialog.currentData.type || "")
                editTypeField.currentIndex = typeIndex >= 0 ? typeIndex : 0
                var unitIndex = ["шт", "набор", "метр", "упаковка"].indexOf(productEditDialog.currentData.unit || "")
                editUnitField.currentIndex = unitIndex >= 0 ? unitIndex : 0
            }
        }
    }

    Dialog {
        id: deleteConfirmationDialog
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
                text: "Удаление товара"
                font.bold: true
                font.pixelSize: 18
                color: "#c0392b"
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                Layout.fillWidth: true
                text: "Вы уверены, что хотите удалить:\n" + (productEditDialog.currentData ? productEditDialog.currentData.name : "")
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                color: "#2c3e50"
            }

            Item {
                Layout.fillHeight: true
            }

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
                    }
                    onClicked: deleteConfirmationDialog.close()
                }

                Button {
                    text: "Удалить"
                    Layout.preferredWidth: 120
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
                    }
                    onClicked: {
                        if (productEditDialog.isKit) {
                            DatabaseManager.deleteEmbroideryKit(productEditDialog.currentData.id)
                        } else {
                            DatabaseManager.deleteConsumableFurniture(productEditDialog.currentData.id)
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
        header: null
        width: 400
        height: 500
        anchors.centerIn: parent
        padding: 20

        property double unitPrice: 0
        property int availableStock: 0
        property int productId: -1
        property bool isKit: true

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
                text: "Оформление продажи"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Label {
                    text: "Выберите товар:"
                    font.bold: true
                    color: "#34495e"
                }
                ComboBox {
                    id: productComboBox
                    Layout.fillWidth: true
                    model: ListModel {
                        id: productsComboModel
                    }
                    textRole: "display"
                    onActivated: saleDialog.updateProductInfo()
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: parent.activeFocus ? "#3498db" : "#dce0e3"
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
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 15
                visible: productComboBox.currentIndex >= 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 70
                    color: "#e8f5e8"
                    radius: 8
                    border.color: "#27ae60"
                    ColumnLayout {
                        anchors.centerIn: parent
                        Label {
                            text: "Цена за ед."
                            color: "#27ae60"
                            font.pixelSize: 12
                        }
                        Label {
                            text: saleDialog.unitPrice.toFixed(2) + " ₽"
                            font.bold: true
                            font.pixelSize: 16
                            color: "#2ecc71"
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 70
                    color: "#e3f2fd"
                    radius: 8
                    border.color: "#3498db"
                    ColumnLayout {
                        anchors.centerIn: parent
                        Label {
                            text: "На складе"
                            color: "#3498db"
                            font.pixelSize: 12
                        }
                        Label {
                            text: saleDialog.availableStock + " шт"
                            font.bold: true
                            font.pixelSize: 16
                            color: "#2980b9"
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                Label {
                    text: "Количество:"
                    font.bold: true
                    color: "#34495e"
                }

                SpinBox {
                    id: quantitySpinBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    from: 1
                    to: 1000
                    value: 1
                    editable: true
                    onValueChanged: saleDialog.updateTotalAmount()

                    contentItem: TextInput {
                        z: 2
                        text: quantitySpinBox.textFromValue(quantitySpinBox.value, quantitySpinBox.locale)
                        font.pixelSize: 16
                        font.bold: true
                        color: "#2c3e50"
                        horizontalAlignment: Qt.AlignHCenter
                        verticalAlignment: Qt.AlignVCenter
                        validator: quantitySpinBox.validator
                        inputMethodHints: Qt.ImhDigitsOnly
                    }

                    background: Rectangle {
                        implicitWidth: 140
                        color: "#f8f9fa"
                        border.color: quantitySpinBox.activeFocus ? "#3498db" : "#bdc3c7"
                        radius: 6
                    }

                    down.indicator: Rectangle {
                        x: 0
                        height: parent.height
                        width: height
                        radius: 6
                        color: quantitySpinBox.down.pressed ? "#bdc3c7" : "#e0e0e0"
                        border.color: "#bdc3c7"

                        Rectangle {
                            x: parent.width - radius
                            width: radius
                            height: parent.height
                            color: parent.color
                            visible: true
                        }

                        Text {
                            text: "-"
                            font.pixelSize: 18
                            font.bold: true
                            anchors.centerIn: parent
                            color: "#2c3e50"
                        }
                    }

                    up.indicator: Rectangle {
                        x: parent.width - width
                        height: parent.height
                        width: height
                        radius: 6
                        color: quantitySpinBox.up.pressed ? "#bdc3c7" : "#e0e0e0"
                        border.color: "#bdc3c7"

                        Rectangle {
                            x: 0
                            width: radius
                            height: parent.height
                            color: parent.color
                            visible: true
                        }

                        Text {
                            text: "+"
                            font.pixelSize: 18
                            font.bold: true
                            anchors.centerIn: parent
                            color: "#2c3e50"
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 60
                color: "#fff3cd"
                radius: 8
                border.color: "#ffc107"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    Label {
                        text: "Итого к оплате:"
                        font.bold: true
                        color: "#e67e22"
                        font.pixelSize: 16
                    }
                    Item {
                        Layout.fillWidth: true
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
                color: "#e74c3c"
                visible: false
                wrapMode: Text.WordWrap
                font.pixelSize: 13
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "transparent"

                RowLayout {
                    anchors.centerIn: parent
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
                            font.pixelSize: 13
                        }
                        onClicked: saleDialog.close()
                    }

                    Button {
                        text: "Продать"
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
                            font.pixelSize: 13
                        }
                        onClicked: saleDialog.processSale()
                    }
                }
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
            if (quantitySpinBox.value <= 0 || quantitySpinBox.value > saleDialog.availableStock) {
                saleValidationError.text = "Неверное количество"
                saleValidationError.visible = true
                return
            }
            var productItem = productsComboModel.get(productComboBox.currentIndex)
            var retailId = DatabaseManager.getRetailCustomerId()
            if (retailId === -1) return

            var orderId = DatabaseManager.createOrder("SALE-" + new Date().getTime(), retailId, "Продажа набора", saleDialog.unitPrice * quantitySpinBox.value, "Завершён", "Быстрая продажа")

            if (orderId !== -1) {
                var itemType = saleDialog.isKit ? "Готовый набор" : "Фурнитура"
                DatabaseManager.createOrderItem(orderId, productItem.id, itemType, productItem.name, quantitySpinBox.value, saleDialog.unitPrice)
                saleDialog.close()
                updateProductList()
                saleSuccessDialog.openWithData(productItem.name, quantitySpinBox.value, saleDialog.unitPrice * quantitySpinBox.value)
            }
        }
        onOpened: {
            saleValidationError.visible = false
            quantitySpinBox.value = 1
            productsComboModel.clear()
            var tableName = productTypeGroup.checkedButton === kitsRadio ? "embroidery_kits" : "consumable_furniture"
            var rowCount = DatabaseManager.getRowCount(tableName)
            for (var i = 0; i < rowCount; i++) {
                var item = DatabaseManager.getRowData(tableName, i)
                if (item) {
                    var price = productTypeGroup.checkedButton === kitsRadio ? item.price : item.price_per_unit
                    productsComboModel.append({
                        id: item.id,
                        name: item.name,
                        display: item.name + " - " + (price || 0) + " ₽",
                        price: price,
                        stock_quantity: item.stock_quantity
                    })
                }
            }
            updateProductInfo()
        }
    }

    Dialog {
        id: saleSuccessDialog
        modal: true
        header: null
        width: 350
        height: 250
        anchors.centerIn: parent
        padding: 20

        property string productName: ""
        property int quantity: 0
        property double totalAmount: 0

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
                text: "Успех!"
                font.bold: true
                font.pixelSize: 18
                color: "#27ae60"
                horizontalAlignment: Text.AlignHCenter
            }

            Label {
                text: "Продажа успешно оформлена"
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 14
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "#f8f9fa"
                radius: 8
                ColumnLayout {
                    anchors.centerIn: parent
                    Label {
                        text: saleSuccessDialog.productName
                        font.bold: true
                        font.pixelSize: 14
                    }
                    Label {
                        text: saleSuccessDialog.quantity + " шт. x " + (saleSuccessDialog.totalAmount / saleSuccessDialog.quantity).toFixed(2)
                        font.pixelSize: 14
                    }
                    Label {
                        text: "Итого: " + saleSuccessDialog.totalAmount.toFixed(2) + " ₽"
                        color: "#27ae60"
                        font.bold: true
                        font.pixelSize: 14
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: "transparent"
                Button {
                    text: "OK"
                    anchors.centerIn: parent
                    width: 100
                    height: 40
                    background: Rectangle {
                        color: parent.down ? "#27ae60" : "#2ecc71"
                        radius: 8
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: saleSuccessDialog.close()
                }
            }
        }

        function openWithData(name, qty, total) {
            productName = name
            quantity = qty
            totalAmount = total
            open()
        }
    }

    Dialog {
        id: kitAddDialog
        modal: true
        header: null
        width: 450
        height: 450
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
                text: "Новый набор"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "Название:"
                    font.bold: true
                    font.pixelSize: 14
                }
                TextField {
                    id: addKitNameField
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: "#dce0e3"
                    }
                }

                Label {
                    text: "Описание:"
                    font.bold: true
                    font.pixelSize: 14
                }
                TextArea {
                    id: addKitDescriptionField
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    Layout.preferredHeight: 80
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: "#dce0e3"
                    }
                }

                RowLayout {
                    spacing: 15
                    ColumnLayout {
                        Label {
                            text: "Цена:"
                            font.bold: true
                            font.pixelSize: 14
                        }
                        TextField {
                            id: addKitPriceField
                            Layout.fillWidth: true
                            font.pixelSize: 14
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 6
                                border.color: "#dce0e3"
                            }
                        }
                    }
                    ColumnLayout {
                        Label {
                            text: "Кол-во:"
                            font.bold: true
                            font.pixelSize: 14
                        }
                        SpinBox {
                            id: addKitQuantityField
                            value: 0
                            to: 1000
                            Layout.preferredHeight: 30
                            background: Rectangle {
                                implicitWidth: 140
                                color: "#f8f9fa"
                                border.color: addKitQuantityField.activeFocus ? "#3498db" : "#bdc3c7"
                                radius: 6
                            }

                            contentItem: TextInput {
                                z: 2
                                text: addKitQuantityField.textFromValue(addKitQuantityField.value, addKitQuantityField.locale)
                                font.pixelSize: 16
                                font.bold: true
                                color: "#2c3e50"
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                validator: addKitQuantityField.validator
                                inputMethodHints: Qt.ImhDigitsOnly
                            }

                            down.indicator: Rectangle {
                                x: 0
                                height: parent.height
                                width: height
                                radius: 6
                                color: addKitQuantityField.down.pressed ? "#bdc3c7" : "#e0e0e0"
                                border.color: "#bdc3c7"

                                Rectangle {
                                    x: parent.width - radius
                                    width: radius
                                    height: parent.height
                                    color: parent.color
                                    visible: true
                                }

                                Text {
                                    text: "-"
                                    font.pixelSize: 18
                                    font.bold: true
                                    anchors.centerIn: parent
                                    color: "#2c3e50"
                                }
                            }

                            up.indicator: Rectangle {
                                x: parent.width - width
                                height: parent.height
                                width: height
                                radius: 6
                                color: addKitQuantityField.up.pressed ? "#bdc3c7" : "#e0e0e0"
                                border.color: "#bdc3c7"

                                Rectangle {
                                    x: 0
                                    width: radius
                                    height: parent.height
                                    color: parent.color
                                    visible: true
                                }

                                Text {
                                    text: "+"
                                    font.pixelSize: 18
                                    font.bold: true
                                    anchors.centerIn: parent
                                    color: "#2c3e50"
                                }
                            }
                        }
                    }
                }

                Label {
                    id: kitValidationError
                    color: "#e74c3c"
                    visible: false
                    font.pixelSize: 13
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "transparent"

                RowLayout {
                    anchors.centerIn: parent
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
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 13
                        }
                        onClicked: kitAddDialog.close()
                    }
                    Button {
                        text: "Добавить"
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 40
                        background: Rectangle {
                            color: parent.down ? "#27ae60" : "#2ecc71"
                            radius: 8
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 13
                        }
                        onClicked: {
                            if (addKitNameField.text.length > 0 && parseFloat(addKitPriceField.text) > 0) {
                                DatabaseManager.addEmbroideryKit(addKitNameField.text, addKitDescriptionField.text, parseFloat(addKitPriceField.text), addKitQuantityField.value)
                                updateProductList()
                                kitAddDialog.close()
                            } else {
                                kitValidationError.text = "Проверьте данные"
                                kitValidationError.visible = true
                            }
                        }
                    }
                }
            }
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
        header: null
        width: 450
        height: 450
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
                text: "Новая фурнитура"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                Label {
                    text: "Название:"
                    font.bold: true
                    font.pixelSize: 14
                }
                TextField {
                    id: addConsumableNameField
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: "#dce0e3"
                    }
                }

                Label {
                    text: "Тип:"
                    font.bold: true
                    font.pixelSize: 14
                }
                ComboBox {
                    id: addConsumableTypeField
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    model: ["инструменты", "материалы", "аксессуары", "прочее"]

                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 6
                        border.color: "#dce0e3"
                    }
                    contentItem: Text {
                        text: addConsumableTypeField.displayText
                        font: addConsumableTypeField.font
                        color: "#000000"
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }
                }

                RowLayout {
                    spacing: 10
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Label {
                            text: "Цена за ед.:"
                            font.bold: true
                            font.pixelSize: 14
                        }
                        TextField {
                            id: addConsumablePriceField
                            Layout.fillWidth: true
                            font.pixelSize: 14
                            placeholderText: "0.00"
                            validator: DoubleValidator {
                                bottom: 0.0
                                decimals: 2
                            }
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 6
                                border.color: "#dce0e3"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Label {
                            text: "Ед. изм.:"
                            font.bold: true
                            font.pixelSize: 14
                        }
                        ComboBox {
                            id: addConsumableUnitField
                            Layout.fillWidth: true
                            font.pixelSize: 14
                            model: ["шт", "набор", "метр", "упаковка"]

                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 6
                                border.color: "#dce0e3"
                            }
                            contentItem: Text {
                                text: addConsumableUnitField.displayText
                                font: addConsumableUnitField.font
                                color: "#000000"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 10
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Label {
                            text: "Количество:"
                            font.bold: true
                            font.pixelSize: 14
                        }
                        SpinBox {
                            id: addConsumableQuantityField
                            value: 0
                            to: 10000
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            editable: true

                            background: Rectangle {
                                color: "#f8f9fa"
                                border.color: addConsumableQuantityField.activeFocus ? "#3498db" : "#bdc3c7"
                                radius: 6
                            }

                            contentItem: TextInput {
                                z: 2
                                text: addConsumableQuantityField.textFromValue(addConsumableQuantityField.value, addConsumableQuantityField.locale)
                                font.pixelSize: 16
                                font.bold: true
                                color: "#2c3e50"
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                readOnly: !addConsumableQuantityField.editable
                                validator: addConsumableQuantityField.validator
                                inputMethodHints: Qt.ImhDigitsOnly
                            }

                            down.indicator: Rectangle {
                                x: 0
                                height: parent.height
                                width: height
                                radius: 6
                                color: addConsumableQuantityField.down.pressed ? "#bdc3c7" : "#e0e0e0"
                                border.color: "#bdc3c7"

                                Rectangle {
                                    x: parent.width - radius
                                    width: radius
                                    height: parent.height
                                    color: parent.color
                                    visible: true
                                }

                                Text {
                                    text: "-"
                                    font.pixelSize: 18
                                    font.bold: true
                                    anchors.centerIn: parent
                                    color: "#2c3e50"
                                }
                            }

                            up.indicator: Rectangle {
                                x: parent.width - width
                                height: parent.height
                                width: height
                                radius: 6
                                color: addConsumableQuantityField.up.pressed ? "#bdc3c7" : "#e0e0e0"
                                border.color: "#bdc3c7"

                                Rectangle {
                                    x: 0
                                    width: radius
                                    height: parent.height
                                    color: parent.color
                                    visible: true
                                }

                                Text {
                                    text: "+"
                                    font.pixelSize: 18
                                    font.bold: true
                                    anchors.centerIn: parent
                                    color: "#2c3e50"
                                }
                            }
                        }
                    }
                }

                Label {
                    id: consumableValidationError
                    color: "#e74c3c"
                    visible: false
                    font.pixelSize: 13
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "transparent"

                RowLayout {
                    anchors.centerIn: parent
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
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: consumableAddDialog.close()
                    }
                    Button {
                        text: "Добавить"
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 40
                        background: Rectangle {
                            color: parent.down ? "#27ae60" : "#2ecc71"
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
                            if (addConsumableNameField.text.length > 0 && parseFloat(addConsumablePriceField.text) > 0) {
                                DatabaseManager.addConsumableFurniture(
                                    addConsumableNameField.text,
                                    addConsumableTypeField.currentText,
                                    parseFloat(addConsumablePriceField.text),
                                    addConsumableQuantityField.value,
                                    addConsumableUnitField.currentText
                                )
                                updateProductList()
                                consumableAddDialog.close()
                            } else {
                                consumableValidationError.text = "Проверьте данные (Цена > 0)"
                                consumableValidationError.visible = true
                            }
                        }
                    }
                }
            }
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
            DatabaseManager.getTableModel("embroidery_kits") :
            DatabaseManager.getTableModel("consumable_furniture")
    }

    onVisibleChanged: {
        if (visible) updateProductList()
    }

    Component.onCompleted: {
        updateProductList()
    }
}
