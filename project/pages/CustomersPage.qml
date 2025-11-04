import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import databasemanager

Page {
    id: root
    property string tableName: "customers"
    property int selectedRow: -1 // Выбранная строка таблицы

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
            text: "👥 Управление покупателями"
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
            Layout.preferredHeight: 50
            color: "#3498db"
            radius: 8

            Row {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 1

                Repeater {
                    model: ["ФИО", "Телефон", "Email", "Адрес", "Дата создания"]

                    Rectangle {
                        width: tableview.width / 5
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

                TableView {
                    id: tableview
                    anchors.fill: parent
                    clip: true
                    model: dbmanager.getTableModel(root.tableName)

                    columnWidthProvider: function(column) {
                        return tableview.width / 5
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
                                customerViewDialog.openWithData(row)
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
                                switch(column) {
                                    case 0: return model.display || ""
                                    case 1: return model.phone || ""
                                    case 2: return model.email || ""
                                    case 3: return model.address || ""
                                    case 4: return formatDate(model.created_at)
                                    default: return ""
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

        // Кнопки справа снизу
        ColumnLayout {
            Layout.alignment: Qt.AlignRight

            Button {
                id: newCustomerButton
                text: "➕ Добавить покупателя"
                font.bold: true
                padding: 12
                Layout.preferredWidth: 180
                background: Rectangle {
                    color: newCustomerButton.down ? "#27ae60" : "#2ecc71"
                    radius: 8
                }
                contentItem: Text {
                    text: newCustomerButton.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: newCustomerButton.font
                }
                onClicked: customerAddDialog.open()
            }

            Button {
                id: refreshButton
                text: "🔄 Обновить"
                font.bold: true
                padding: 12
                Layout.preferredWidth: 120
                background: Rectangle {
                    color: refreshButton.down ? "#2980b9" : "#3498db"
                    radius: 8
                }
                contentItem: Text {
                    text: refreshButton.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font: refreshButton.font
                }
                onClicked: tableview.model = dbmanager.getTableModel(root.tableName)
            }
        }
    }

    // Функция форматирования даты
    function formatDate(dateString) {
        if (!dateString) return "Не указана"
        var date = new Date(dateString)
        return date.toLocaleDateString(Qt.locale(), "dd.MM.yyyy HH:mm")
    }

    // Остальной код диалогов остается без изменений...
    // Диалог для добавления нового пользователя
    Dialog {
        id: customerAddDialog
        modal: true
        title: "👤 Добавить нового покупателя"

        width: 500
        height: 520
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
                text: "📝 Заполните информацию о покупателе"
                font.bold: true
                font.pixelSize: 16
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            // Центрируем форму по горизонтали
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
                Layout.maximumWidth: 400
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "👤 ФИО:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignHCenter
                    }
                    TextField {
                        id: addNameField
                        Layout.fillWidth: true
                        placeholderText: "Введите полное имя"
                        font.pixelSize: 14
                        padding: 10
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: addNameField.activeFocus ? "#3498db" : "#dce0e3"
                        }
                        onTextChanged: customerAddDialog.validateForm()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "📞 Телефон:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignHCenter
                    }
                    TextField {
                        id: addPhoneField
                        Layout.fillWidth: true
                        placeholderText: "+7-XXX-XXX-XX-XX"
                        font.pixelSize: 14
                        padding: 10
                        inputMethodHints: Qt.ImhDialableCharactersOnly
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: addPhoneField.activeFocus ? "#3498db" : "#dce0e3"
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "📧 Email:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignHCenter
                    }
                    TextField {
                        id: addEmailField
                        Layout.fillWidth: true
                        placeholderText: "example@mail.ru"
                        font.pixelSize: 14
                        padding: 10
                        inputMethodHints: Qt.ImhEmailCharactersOnly
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: addEmailField.activeFocus ? "#3498db" : "#dce0e3"
                        }
                        onTextChanged: customerAddDialog.validateForm()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "🏠 Адрес:"
                        font.bold: true
                        color: "#34495e"
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignHCenter
                    }
                    TextField {
                        id: addAddressField
                        Layout.fillWidth: true
                        placeholderText: "Введите полный адрес"
                        font.pixelSize: 14
                        padding: 10
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 6
                            border.color: addAddressField.activeFocus ? "#3498db" : "#dce0e3"
                        }
                        onTextChanged: customerAddDialog.validateForm()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#e0e0e0"
                    Layout.topMargin: 5
                    Layout.bottomMargin: 5
                }

                Label {
                    id: validationError
                    Layout.fillWidth: true
                    Layout.preferredHeight: validationError.visible ? implicitHeight : 0
                    color: "#e74c3c"
                    visible: false
                    wrapMode: Text.WordWrap
                    font.pixelSize: 12
                    padding: 8
                    background: Rectangle {
                        color: "#fdf2f2"
                        radius: 6
                        border.color: "#e74c3c"
                        border.width: 1
                    }
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Кастомные кнопки для диалога
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
                onClicked: customerAddDialog.reject()
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
                    if (customerAddDialog.validateForm()) {
                        dbmanager.addCustomer(
                            addNameField.text.trim(),
                            addPhoneField.text.trim(),
                            addEmailField.text.trim(),
                            addAddressField.text.trim()
                        )
                        tableview.model = dbmanager.getTableModel(root.tableName)
                        customerAddDialog.close()
                    }
                }
            }
        }

        function validateForm() {
            const errors = []
            const name = addNameField.text.trim()
            const phone = addPhoneField.text.trim()
            const email = addEmailField.text.trim()
            const address = addAddressField.text.trim()

            if (name.length < 2) errors.push("• ФИО должно содержать минимум 2 символа")

            const phoneRegex = /^\+7-[0-9]{3}-[0-9]{3}-[0-9]{2}-[0-9]{2}$/
            if (!phoneRegex.test(phone)) errors.push("• Введите корректный номер телефона в формате +7-XXX-XXX-XX-XX")

            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
            if (!emailRegex.test(email)) errors.push("• Введите корректный email адрес")

            if (address.length < 5) errors.push("• Адрес должен содержать минимум 5 символов")

            if (errors.length > 0) {
                validationError.text = errors.join("\n")
                validationError.visible = true
                return false
            }

            validationError.visible = false
            return true
        }

        onOpened: {
            addNameField.text = ""
            addPhoneField.text = ""
            addEmailField.text = ""
            addAddressField.text = ""
            validationError.visible = false
            addNameField.forceActiveFocus()
        }
    }

    // Остальные диалоги (customerViewDialog, customerEditDialog, deleteConfirmDialog) остаются без изменений...
    // Диалог для просмотра данных покупателя
    Dialog {
        id: customerViewDialog
        modal: true
        title: "👤 Данные покупателя"

        property int currentRow: -1
        property var currentData: ({})
        property var customerOrders: ([])

        width: 700
        height: 700
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
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: 15

                    // Центрируем содержимое
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.maximumWidth: 550
                        spacing: 15

                        // ФИО
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 500
                            spacing: 5

                            Label {
                                Layout.fillWidth: true
                                text: "👤 ФИО:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                Layout.fillWidth: true
                                text: customerViewDialog.currentData.full_name || "Не указано"
                                wrapMode: Text.WrapAnywhere
                                color: "#2c3e50"
                                font.pixelSize: 14
                                padding: 10
                                horizontalAlignment: Text.AlignHCenter
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 8
                                    border.color: "#e9ecef"
                                }
                            }
                        }

                        // Телефон
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 500
                            spacing: 5

                            Label {
                                Layout.fillWidth: true
                                text: "📞 Телефон:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                Layout.fillWidth: true
                                text: customerViewDialog.currentData.phone || "Не указано"
                                wrapMode: Text.WrapAnywhere
                                color: "#2c3e50"
                                font.pixelSize: 14
                                padding: 10
                                horizontalAlignment: Text.AlignHCenter
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 8
                                    border.color: "#e9ecef"
                                }
                            }
                        }

                        // Email
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 500
                            spacing: 5

                            Label {
                                Layout.fillWidth: true
                                text: "📧 Email:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                Layout.fillWidth: true
                                text: customerViewDialog.currentData.email || "Не указано"
                                wrapMode: Text.WrapAnywhere
                                color: "#2c3e50"
                                font.pixelSize: 14
                                padding: 10
                                horizontalAlignment: Text.AlignHCenter
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 8
                                    border.color: "#e9ecef"
                                }
                            }
                        }

                        // Адрес
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 500
                            spacing: 5

                            Label {
                                Layout.fillWidth: true
                                text: "🏠 Адрес:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Label {
                                Layout.fillWidth: true
                                text: customerViewDialog.currentData.address || "Не указано"
                                wrapMode: Text.WrapAnywhere
                                color: "#2c3e50"
                                font.pixelSize: 14
                                padding: 10
                                horizontalAlignment: Text.AlignHCenter
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 8
                                    border.color: "#e9ecef"
                                }
                            }
                        }

                        // Заказы покупателя
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            Layout.maximumWidth: 500
                            spacing: 8

                            Label {
                                Layout.fillWidth: true
                                text: "📦 Заказы:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 16
                                padding: 5
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Repeater {
                                model: customerViewDialog.customerOrders

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: orderLayout.implicitHeight + 20
                                    color: "#f8f9fa"
                                    radius: 8
                                    border.color: "#e9ecef"

                                    ColumnLayout {
                                        id: orderLayout
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 5

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Label {
                                                text: "№ заказа:"
                                                font.bold: true
                                                color: "#34495e"
                                                font.pixelSize: 12
                                                Layout.preferredWidth: 80
                                            }
                                            Label {
                                                text: modelData.order_number || "Не указан"
                                                Layout.fillWidth: true
                                                color: "#2c3e50"
                                                font.pixelSize: 12
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Label {
                                                text: "Тип:"
                                                font.bold: true
                                                color: "#34495e"
                                                font.pixelSize: 12
                                                Layout.preferredWidth: 80
                                            }
                                            Label {
                                                text: getOrderTypeText(modelData.order_type)
                                                Layout.fillWidth: true
                                                color: "#2c3e50"
                                                font.pixelSize: 12
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Label {
                                                text: "Статус:"
                                                font.bold: true
                                                color: "#34495e"
                                                font.pixelSize: 12
                                                Layout.preferredWidth: 80
                                            }
                                            Label {
                                                text: getStatusText(modelData.status)
                                                Layout.fillWidth: true
                                                color: getStatusColor(modelData.status)
                                                font.pixelSize: 12
                                                font.bold: true
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Label {
                                                text: "Сумма:"
                                                font.bold: true
                                                color: "#34495e"
                                                font.pixelSize: 12
                                                Layout.preferredWidth: 80
                                            }
                                            Label {
                                                text: modelData.total_amount ? modelData.total_amount + " ₽" : "0 ₽"
                                                Layout.fillWidth: true
                                                color: "#2c3e50"
                                                font.pixelSize: 12
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 10

                                            Label {
                                                text: "Дата создания:"
                                                font.bold: true
                                                color: "#34495e"
                                                font.pixelSize: 12
                                                Layout.preferredWidth: 80
                                            }
                                            Label {
                                                text: modelData.created_at || "Не указана"
                                                Layout.fillWidth: true
                                                color: "#2c3e50"
                                                font.pixelSize: 12
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }
                                    }
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: customerViewDialog.customerOrders.length === 0 ? "Заказов нет" : ""
                                horizontalAlignment: Text.AlignHCenter
                                color: "#7f8c8d"
                                font.pixelSize: 12
                                font.italic: true
                                padding: 10
                            }
                        }
                    }
                }
            }
        }

        // Кнопки для диалога просмотра
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
                    customerViewDialog.close()
                    customerEditDialog.openWithData(customerViewDialog.currentRow, customerViewDialog.currentData)
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
                onClicked: customerViewDialog.close()
            }
        }

        function getOrderTypeText(type) {
            switch(type) {
                case 'frame_production': return "Изготовление рамки"
                case 'kit_sale': return "Продажа набора"
                default: return type || "Не указан"
            }
        }

        function getStatusText(status) {
            switch(status) {
                case 'new': return "Новый"
                case 'in_progress': return "В работе"
                case 'ready': return "Готов"
                case 'completed': return "Завершен"
                case 'cancelled': return "Отменен"
                default: return status || "Не указан"
            }
        }

        function getStatusColor(status) {
            switch(status) {
                case 'new': return "#3498db"
                case 'in_progress': return "#f39c12"
                case 'ready': return "#27ae60"
                case 'completed': return "#2ecc71"
                case 'cancelled': return "#e74c3c"
                default: return "#7f8c8d"
            }
        }

        function openWithData(row) {
            currentRow = row
            currentData = dbmanager.getRowData(root.tableName, row)
            customerOrders = dbmanager.getCustomerOrders(currentData.id)
            open()
        }
    }

    // Диалог для редактирования данных покупателя
    Dialog {
        id: customerEditDialog
        modal: true
        title: "✏️ Редактирование данных покупателя"

        property int currentRow: -1
        property var currentData: ({})

        width: 600
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
                text: "✏️ Редактирование данных"
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
                    spacing: 15

                    // Центрируем содержимое
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        Layout.maximumWidth: 500
                        spacing: 15

                        // ФИО
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 6

                            Label {
                                Layout.fillWidth: true
                                text: "👤 ФИО:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }
                            TextField {
                                id: editNameField
                                Layout.fillWidth: true
                                placeholderText: "Введите ФИО"
                                font.pixelSize: 14
                                padding: 10
                                horizontalAlignment: Text.AlignHCenter
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 8
                                    border.color: editNameField.activeFocus ? "#3498db" : "#dce0e3"
                                    border.width: 2
                                }
                            }
                        }

                        // Телефон
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 6

                            Label {
                                Layout.fillWidth: true
                                text: "📞 Телефон:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }
                            TextField {
                                id: editPhoneField
                                Layout.fillWidth: true
                                placeholderText: "+7-XXX-XXX-XX-XX"
                                font.pixelSize: 14
                                padding: 10
                                inputMethodHints: Qt.ImhDialableCharactersOnly
                                horizontalAlignment: Text.AlignHCenter
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 8
                                    border.color: editPhoneField.activeFocus ? "#3498db" : "#dce0e3"
                                    border.width: 2
                                }
                            }
                        }

                        // Email
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 6

                            Label {
                                Layout.fillWidth: true
                                text: "📧 Email:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }
                            TextField {
                                id: editEmailField
                                Layout.fillWidth: true
                                placeholderText: "example@mail.ru"
                                font.pixelSize: 14
                                padding: 10
                                inputMethodHints: Qt.ImhEmailCharactersOnly
                                horizontalAlignment: Text.AlignHCenter
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 8
                                    border.color: editEmailField.activeFocus ? "#3498db" : "#dce0e3"
                                    border.width: 2
                                }
                            }
                        }

                        // Адрес
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 6

                            Label {
                                Layout.fillWidth: true
                                text: "🏠 Адрес:"
                                font.bold: true
                                color: "#34495e"
                                font.pixelSize: 13
                                horizontalAlignment: Text.AlignHCenter
                            }
                            TextField {
                                id: editAddressField
                                Layout.fillWidth: true
                                placeholderText: "Введите адрес"
                                font.pixelSize: 14
                                padding: 10
                                horizontalAlignment: Text.AlignHCenter
                                background: Rectangle {
                                    color: "#f8f9fa"
                                    radius: 8
                                    border.color: editAddressField.activeFocus ? "#3498db" : "#dce0e3"
                                    border.width: 2
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

        // Кнопки для диалога редактирования
        footer: DialogButtonBox {
            alignment: Qt.AlignCenter
            padding: 15
            background: Rectangle {
                color: "transparent"
            }

            Button {
                text: "💾 Сохранить"
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
                    if (customerEditDialog.validateForm()) {
                        dbmanager.updateCustomer(
                            customerEditDialog.currentRow,
                            editNameField.text.trim(),
                            editPhoneField.text.trim(),
                            editEmailField.text.trim(),
                            editAddressField.text.trim()
                        )
                        tableview.model = dbmanager.getTableModel(root.tableName)
                        customerEditDialog.close()
                    }
                }
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
                onClicked: customerEditDialog.reject()
            }
        }

        function validateForm() {
            const errors = []
            const name = editNameField.text.trim()
            const phone = editPhoneField.text.trim()
            const email = editEmailField.text.trim()
            const address = editAddressField.text.trim()

            if (name.length < 2) errors.push("• ФИО должно содержать минимум 2 символа")

            const phoneRegex = /^\+7-[0-9]{3}-[0-9]{3}-[0-9]{2}-[0-9]{2}$/
            if (!phoneRegex.test(phone)) errors.push("• Введите корректный номер телефона в формате +7-XXX-XXX-XX-XX")

            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
            if (!emailRegex.test(email)) errors.push("• Введите корректный email адрес")

            if (address.length < 5) errors.push("• Адрес должен содержать минимум 5 символов")

            if (errors.length > 0) {
                editValidationError.text = errors.join("\n")
                editValidationError.visible = true
                return false
            }

            editValidationError.visible = false
            return true
        }

        function openWithData(row, data) {
            currentRow = row
            currentData = data
            editNameField.text = data.full_name || ""
            editPhoneField.text = data.phone || ""
            editEmailField.text = data.email || ""
            editAddressField.text = data.address || ""
            editValidationError.visible = false
            open()
            editNameField.forceActiveFocus()
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
                text: "🗑️ Вы уверены, что хотите удалить этого покупателя?"
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
                    dbmanager.deleteCustomer(customerViewDialog.currentRow)
                    tableview.model = dbmanager.getTableModel(root.tableName)
                    customerViewDialog.close()
                    deleteConfirmDialog.close()
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) tableview.model = dbmanager.getTableModel(root.tableName)
    }
}
