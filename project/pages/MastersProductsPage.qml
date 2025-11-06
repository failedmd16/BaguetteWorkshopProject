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
                        tableview.model = dbmanager.getFrameMaterialsModel()
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
                        tableview.model = dbmanager.getComponentFurnitureModel()
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
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff  // Отключаем горизонтальную прокрутку

                TableView {
                    id: tableview
                    width: parent.width  // Фиксируем ширину, чтобы не было горизонтальной прокрутки
                    model: root.currentTable === "frame_materials" ?
                          dbmanager.getFrameMaterialsModel() :
                          dbmanager.getComponentFurnitureModel()

                    columnWidthProvider: function(column) {
                        var columnsCount = root.currentTable === "frame_materials" ? 6 : 4
                        return tableview.width / columnsCount
                    }

                    delegate: Rectangle {
                        implicitHeight: 45
                        color: row % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#e9ecef"

                        property var rowData: root.currentTable === "frame_materials" ?
                                                    dbmanager.getFrameMaterialRowData(row) :
                                                    dbmanager.getComponentFurnitureRowData(row)

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
                                        case 2: return (parent.rowData.price_per_meter || 0) + " ₽"
                                        case 3: return (parent.rowData.stock_quantity || 0) + " м"
                                        case 4: return parent.rowData.color || ""
                                        case 5: return (parent.rowData.width || 0) + " см"
                                        default: return ""
                                    }
                                } else {
                                    switch(column) {
                                        case 0: return parent.rowData.name || ""
                                        case 1: return parent.rowData.type || ""
                                        case 2: return (parent.rowData.price_per_unit || 0) + " ₽"
                                        case 3: return (parent.rowData.stock_quantity || 0) + " шт"
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

    function refreshTable() {
        if (root.currentTable === "frame_materials") {
            tableview.model = dbmanager.getFrameMaterialsModel()
        } else {
            tableview.model = dbmanager.getComponentFurnitureModel()
        }
    }

    // Диалог просмотра/редактирования
    Dialog {
        id: productViewDialog
        modal: true
        title: root.currentTable === "frame_materials" ? "📐 Данные материала" : "🔩 Данные фурнитуры"
        width: 350
        height: 600
        anchors.centerIn: parent
        padding: 0

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
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: root.currentTable === "frame_materials" ? "📐 Данные материала" : "🔩 Данные фурнитуры"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            ScrollView {
                clip: true
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.margins: 15

                ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: parent.width
                    spacing: 15
                    anchors.top: parent.top
                    anchors.topMargin: 10

                    // Название
                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📝 Название:"
                            font.bold: true
                            color: "#34495e"
                        }
                        Label {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: productViewDialog.currentData.name || "Не указано"
                            wrapMode: Text.Wrap
                            color: "#2c3e50"
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                            }
                        }
                    }

                    // Тип
                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "🔧 Тип:"
                            font.bold: true
                            color: "#34495e"
                        }
                        Label {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: productViewDialog.currentData.type || "Не указано"
                            wrapMode: Text.Wrap
                            color: "#2c3e50"
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                            }
                        }
                    }

                    // Цена
                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.currentTable === "frame_materials" ? "💰 Цена за метр:" : "💰 Цена за шт:"
                            font.bold: true
                            color: "#34495e"
                        }
                        Label {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (root.currentTable === "frame_materials")
                                    return (productViewDialog.currentData.price_per_meter || 0) + " ₽"
                                else
                                    return (productViewDialog.currentData.price_per_unit || 0) + " ₽"
                            }
                            wrapMode: Text.Wrap
                            color: "#27ae60"
                            font.bold: true
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                            }
                        }
                    }

                    // Количество на складе
                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.currentTable === "frame_materials" ? "📦 На складе (м):" : "📦 На складе (шт):"
                            font.bold: true
                            color: "#34495e"
                        }
                        Label {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (root.currentTable === "frame_materials")
                                    return (productViewDialog.currentData.stock_quantity || 0) + " м"
                                else
                                    return (productViewDialog.currentData.stock_quantity || 0) + " шт"
                            }
                            wrapMode: Text.Wrap
                            color: "#2c3e50"
                            font.bold: true
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                            }
                        }
                    }

                    // Только для материалов рамок - Цвет
                    Column {
                        width: parent.width
                        spacing: 5
                        visible: root.currentTable === "frame_materials"

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "🎨 Цвет:"
                            font.bold: true
                            color: "#34495e"
                        }
                        Label {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: productViewDialog.currentData.color || "Не указан"
                            wrapMode: Text.Wrap
                            color: "#2c3e50"
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                            }
                        }
                    }

                    // Только для материалов рамок - Ширина
                    Column {
                        width: parent.width
                        spacing: 5
                        visible: root.currentTable === "frame_materials"

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📏 Ширина:"
                            font.bold: true
                            color: "#34495e"
                        }
                        Label {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (productViewDialog.currentData.width || 0) + " см"
                            wrapMode: Text.Wrap
                            color: "#2c3e50"
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                            }
                        }
                    }

                    // Информация о создании
                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📅 Дата создания:"
                            font.bold: true
                            color: "#34495e"
                        }
                        Label {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: productViewDialog.currentData.created_at ?
                                  formatDate(productViewDialog.currentData.created_at) : "Не указана"
                            wrapMode: Text.Wrap
                            color: "#7f8c8d"
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                color: "transparent"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Button {
                        text: "✏️ Изменить"
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 40
                        background: Rectangle {
                            color: parent.down ? "#2980b9" : "#3498db"
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
                            productViewDialog.close()
                            productEditDialog.openWithData(productViewDialog.currentRow, productViewDialog.currentData)
                        }
                    }

                    Button {
                        text: "🗑️ Удалить"
                        Layout.preferredWidth: 100
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
                        onClicked: deleteConfirmDialog.open()
                    }

                    Button {
                        text: "❌ Закрыть"
                        Layout.preferredWidth: 100
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
                        onClicked: productViewDialog.close()
                    }
                }
            }
            function openWithData(row) {
                    currentRow = row
                    if (root.currentTable === "frame_materials") {
                        currentData = dbmanager.getFrameMaterialRowData(row)
                    } else {
                        currentData = dbmanager.getComponentFurnitureRowData(row)
                    }
                    open()
                }
        }

        function openWithData(row) {
            currentRow = row
            if (root.currentTable === "frame_materials") {
                currentData = dbmanager.getFrameMaterialRowData(row)
            } else {
                currentData = dbmanager.getComponentFurnitureRowData(row)
            }
            open()
        }
    }

    // Диалог редактирования материала/фурнитуры
    Dialog {
        id: productEditDialog
        modal: true
        title: root.currentTable === "frame_materials" ? "✏️ Редактировать материал" : "✏️ Редактировать фурнитуру"
        width: 400
        height: root.currentTable === "frame_materials" ? 550 : 450
        anchors.centerIn: parent
        padding: 0

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
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: root.currentTable === "frame_materials" ? "✏️ Редактировать материал" : "✏️ Редактировать фурнитуру"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            ScrollView {
                clip: true
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.topMargin: 10
                Layout.bottomMargin: 10

                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: parent.width
                    spacing: 15
                    anchors.top: parent.top
                    anchors.topMargin: 10

                    // Название
                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📝 Название:"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            id: editNameField
                            color: "black"
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            placeholderText: "Введите название"
                            font.pixelSize: 14
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                                border.color: editNameField.activeFocus ? "#3498db" : "#dce0e3"
                                border.width: 2
                            }
                        }
                    }

                    // Тип
                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "🔧 Тип:"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            id: editTypeField
                            color: "black"
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            placeholderText: "Введите тип"
                            font.pixelSize: 14
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                                border.color: editTypeField.activeFocus ? "#3498db" : "#dce0e3"
                                border.width: 2
                            }
                        }
                    }

                    // Цена
                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.currentTable === "frame_materials" ? "💰 Цена за метр (₽):" : "💰 Цена за шт (₽):"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            id: editPriceField
                            color: "black";
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            placeholderText: "0.00"
                            validator: DoubleValidator { bottom: 0.01 }
                            font.pixelSize: 14
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                                border.color: editPriceField.activeFocus ? "#3498db" : "#dce0e3"
                                border.width: 2
                            }
                        }
                    }

                    // Количество на складе
                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.currentTable === "frame_materials" ? "📦 На складе (м):" : "📦 На складе (шт):"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            id: editStockField
                            color: "black"
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            placeholderText: root.currentTable === "frame_materials" ? "0.0" : "0"
                            validator: root.currentTable === "frame_materials" ? doubleValidator : intValidator
                            font.pixelSize: 14
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                                border.color: editStockField.activeFocus ? "#3498db" : "#dce0e3"
                                border.width: 2
                            }
                        }
                    }

                    // Только для материалов рамок - Цвет
                    Column {
                        width: parent.width
                        spacing: 5
                        visible: root.currentTable === "frame_materials"

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "🎨 Цвет:"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            id: editColorField
                            color: "black"
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            placeholderText: "Введите цвет"
                            font.pixelSize: 14
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                                border.color: editColorField.activeFocus ? "#3498db" : "#dce0e3"
                                border.width: 2
                            }
                        }
                    }

                    // Только для материалов рамок - Ширина
                    Column {
                        width: parent.width
                        spacing: 5
                        visible: root.currentTable === "frame_materials"

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📏 Ширина (см):"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            id: editWidthField
                            color: "black"
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            placeholderText: "0.0"
                            validator: DoubleValidator { bottom: 0.1 }
                            font.pixelSize: 14
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                                border.color: editWidthField.activeFocus ? "#3498db" : "#dce0e3"
                                border.width: 2
                            }
                        }
                    }

                    Label {
                        id: editValidationError
                        width: 300
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#e74c3c"
                        visible: false
                        wrapMode: Text.Wrap
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                color: "transparent"

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Button {
                        text: "💾 Сохранить"
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
                        }
                        onClicked: {
                            if (validateEditForm()) {
                                if (root.currentTable === "frame_materials") {
                                    dbmanager.updateFrameMaterial(
                                        productEditDialog.currentRow,
                                        editNameField.text.trim(),
                                        editTypeField.text.trim(),
                                        parseFloat(editPriceField.text) || 0,
                                        parseFloat(editStockField.text) || 0,
                                        editColorField.text.trim(),
                                        parseFloat(editWidthField.text) || 0
                                    )
                                } else {
                                    dbmanager.updateComponentFurniture(
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

                            // Проверка цены
                            var price = parseFloat(editPriceField.text)
                            if (isNaN(price) || price <= 0) errors.push("• Введите корректную цену")

                            // Проверка количества
                            if (root.currentTable === "frame_materials") {
                                var stock = parseFloat(editStockField.text)
                                if (isNaN(stock) || stock < 0) errors.push("• Введите корректное количество")
                            } else {
                                var stockInt = parseInt(editStockField.text)
                                if (isNaN(stockInt) || stockInt < 0) errors.push("• Введите корректное количество")
                            }

                            if (root.currentTable === "frame_materials") {
                                if (!editColorField.text.trim()) errors.push("• Введите цвет")

                                var width = parseFloat(editWidthField.text)
                                if (isNaN(width) || width <= 0) errors.push("• Введите корректную ширину")
                            }

                            if (errors.length > 0) {
                                editValidationError.text = errors.join("\n")
                                editValidationError.visible = true
                                return false
                            }

                            editValidationError.visible = false
                            return true
                        }
                    }

                    Button {
                        text: "❌ Отмена"
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
                        onClicked: productEditDialog.close()
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
            editNameField.forceActiveFocus()
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

    // Добавьте эту функцию форматирования даты, если её нет
    function formatDate(dateString) {
        if (!dateString) return "Не указана"
        var date = new Date(dateString)
        if (isNaN(date.getTime())) return "Неверная дата"
        return date.toLocaleDateString(Qt.locale("ru_RU"), "dd.MM.yyyy HH:mm")
    }
}
