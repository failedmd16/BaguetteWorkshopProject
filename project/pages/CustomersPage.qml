import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Database

Page {
    id: root
    property string tableName: "customers"
    property int selectedRow: -1

    Rectangle {
        anchors.fill: parent
        color: "#f8f9fa"
    }

    onVisibleChanged: {
        if (visible)
            refreshTable()
    }

    function getOrderTypeText(type) {
        switch(type) {
            case 'Изготовление рамки': return "Изготовление рамки"
            case 'Продажа набора': return "Продажа набора"
            default: return type || "Не указан"
        }
    }

    function getStatusText(status) {
        switch(status) {
            case 'Новый': return "Новый"
            case 'В работе': return "В работе"
            case 'Готов': return "Готов"
            case 'Завершён': return "Завершен"
            case 'Отменён': return "Отменен"
            default: return status || "Не указан"
        }
    }

    function getStatusColor(status) {
        switch(status) {
            case 'Новый': return "#3498db"
            case 'В работе': return "#f39c12"
            case 'Готов': return "#27ae60"
            case 'Завершён': return "#2ecc71"
            case 'Отменён': return "#e74c3c"
            default: return "#7f8c8d"
        }
    }

    function formatDate(dateString) {
        if (!dateString) return "Не указана"
        var date = new Date(dateString)
        if (isNaN(date.getTime())) return "Неверная дата"
        return date.toLocaleDateString(Qt.locale("ru_RU"), "dd.MM.yyyy")
    }

    function isValidDate(dateString) {
        var regex = /^(\d{2})\.(\d{2})\.(\d{4})$/
        var match = dateString.match(regex)
        if (!match) return false

        var day = parseInt(match[1], 10)
        var month = parseInt(match[2], 10)
        var year = parseInt(match[3], 10)

        if (month < 1 || month > 12) return false
        if (day < 1 || day > 31) return false

        return true
    }

    function convertToSqlDate(dateString) {
        var parts = dateString.split('.')
        if (parts.length !== 3) return dateString
        return parts[2] + '-' + parts[1] + '-' + parts[0]
    }

    function refreshTable() {
        tableview.model = null
        tableview.model = DatabaseManager.getTableModel(root.tableName)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

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
            Layout.alignment: Qt.AlignLeft
            Layout.preferredHeight: 50
            color: "#ffffff"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1

            RowLayout {
                anchors.margins: 15
                spacing: 10
                anchors.centerIn: parent
                width: parent.width

                Label {
                    text: "🔍 Фильтр по периоду:"
                    font.bold: true
                    color: "#2c3e50"
                    font.pixelSize: 14
                }

                Label {
                    text: "С:"
                    color: "#34495e"
                    font.bold: true
                }

                TextField {
                    id: startDateField
                    Layout.preferredWidth: 120
                    placeholderText: "дд.мм.гггг"
                    font.pixelSize: 14
                    padding: 10
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 8
                        border.color: startDateField.activeFocus ? "#3498db" : "#dce0e3"
                        border.width: 1
                    }
                }

                Label {
                    text: "По:"
                    color: "#34495e"
                    font.bold: true
                }

                TextField {
                    id: endDateField
                    Layout.preferredWidth: 120
                    placeholderText: "дд.мм.гггг"
                    font.pixelSize: 14
                    padding: 10
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 8
                        border.color: endDateField.activeFocus ? "#3498db" : "#dce0e3"
                        border.width: 1
                    }
                }

                Button {
                    text: "Применить"
                    font.bold: true
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 140
                    font.pixelSize: 14
                    background: Rectangle {
                        color: parent.down ? "#2980b9" : "#3498db"
                        radius: 8
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font: parent.font                    }
                    onClicked: {
                        if (startDateField.text && endDateField.text && isValidDate(startDateField.text) && isValidDate(endDateField.text)) {
                            var customers = DatabaseManager.getCustomersWithOrdersInPeriod(
                                convertToSqlDate(startDateField.text),
                                convertToSqlDate(endDateField.text)
                            )
                            filterResultsDialog.openWithData(customers)
                        } else {
                            messageDialog.open()
                        }
                    }
                }

                Button {
                    text: "Сбросить"
                    font.bold: true
                    Layout.preferredHeight: 40
                    Layout.preferredWidth: 120
                    font.pixelSize: 14
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
                    onClicked: {
                        var endDate = new Date()
                        var startDate = new Date()
                        startDate.setDate(startDate.getDate() - 30)
                        startDateField.text = formatDate(startDate.toISOString())
                        endDateField.text = formatDate(endDate.toISOString())
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
                    model: DatabaseManager.getTableModel(root.tableName)

                    columnWidthProvider: function(column) {
                        return tableview.width / 5
                    }

                    delegate: Rectangle {
                        implicitHeight: 45
                        color: row % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#e9ecef"

                        property var rowData: model ? DatabaseManager.getRowData(root.tableName, row) : ({})

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
                                if (!parent.rowData) return ""

                                switch(column) {
                                    case 0: return parent.rowData.full_name || ""
                                    case 1: return parent.rowData.phone || ""
                                    case 2: return parent.rowData.email || ""
                                    case 3: return parent.rowData.address || ""
                                    case 4: return formatDate(parent.rowData.created_at)
                                    default: return ""
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
            Layout.alignment: Qt.AlignRight
            spacing: 10

            Button {
                id: newCustomerButton
                text: "Добавить покупателя"
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
                onClicked: customerAddDialog.open()
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
            }
        }
    }

    Dialog {
        id: customerAddDialog
        modal: true
        header: null
        width: 500
        height: 600
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
            spacing: 10

            Label {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                text: "Добавление нового покупателя"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                spacing: 15

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Label {
                        text: "ФИО:"
                        font.bold: true
                        color: "#34495e"
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 14
                    }
                    TextField {
                        id: addNameField
                        Layout.preferredWidth: 300
                        placeholderText: "Введите полное имя"
                        font.pixelSize: 14
                        padding: 12
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: addNameField.activeFocus ? "#3498db" : "#dce0e3"
                            border.width: 2
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Label {
                        text: "Телефон:"
                        font.bold: true
                        color: "#34495e"
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 14
                    }
                    TextField {
                        id: addPhoneField
                        Layout.preferredWidth: 300
                        placeholderText: "+7-XXX-XXX-XX-XX"
                        font.pixelSize: 14
                        padding: 12
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: addPhoneField.activeFocus ? "#3498db" : "#dce0e3"
                            border.width: 2
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Label {
                        text: "Email:"
                        font.bold: true
                        color: "#34495e"
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 14
                    }
                    TextField {
                        id: addEmailField
                        Layout.preferredWidth: 300
                        placeholderText: "example@mail.ru"
                        font.pixelSize: 14
                        padding: 12
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: addEmailField.activeFocus ? "#3498db" : "#dce0e3"
                            border.width: 2
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Label {
                        text: "Адрес:"
                        font.bold: true
                        color: "#34495e"
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 14
                    }
                    TextField {
                        id: addAddressField
                        Layout.preferredWidth: 300
                        placeholderText: "Введите полный адрес"
                        font.pixelSize: 14
                        padding: 12
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: addAddressField.activeFocus ? "#3498db" : "#dce0e3"
                            border.width: 2
                        }
                    }
                }

                Label {
                    id: addValidationError
                    visible: false
                    color: "#e74c3c"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 300
                    Layout.maximumWidth: 300
                    wrapMode: Text.WordWrap
                    font.bold: true
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

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
                    onClicked: customerAddDialog.close()
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
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }
                    onClicked: {
                        if (validateAddForm()) {
                            DatabaseManager.addCustomer(
                                addNameField.text.trim(),
                                addPhoneField.text.trim(),
                                addEmailField.text.trim(),
                                addAddressField.text.trim()
                            )
                            refreshTable()
                            customerAddDialog.close()
                        }
                    }
                    function validateAddForm() {
                        const errors = []
                        const name = addNameField.text.trim()
                        const phone = addPhoneField.text.trim()
                        const email = addEmailField.text.trim()
                        const address = addAddressField.text.trim()

                        if (name.length < 10) errors.push("• ФИО должно содержать минимум 10 символов")

                        const phoneRegex = /^\+7-[0-9]{3}-[0-9]{3}-[0-9]{2}-[0-9]{2}$/
                        if (!phoneRegex.test(phone)) errors.push("• Введите корректный номер телефона в формате +7-XXX-XXX-XX-XX")

                        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
                        if (!emailRegex.test(email)) errors.push("• Введите корректный email адрес")

                        if (address.length < 15) errors.push("• Адрес должен содержать минимум 15 символов")

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
        }

        onOpened: {
            addNameField.text = ""
            addPhoneField.text = ""
            addEmailField.text = ""
            addAddressField.text = ""
            addValidationError.visible = false
            addNameField.forceActiveFocus()
        }
    }

    Dialog {
        id: customerEditDialog
        modal: true
        header: null
        width: 500
        height: 600
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
            spacing: 10

            Label {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                text: "Редактирование данных"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 10
                spacing: 15

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Label {
                        text: "ФИО:"
                        font.bold: true
                        color: "#34495e"
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 14
                    }
                    TextField {
                        id: editNameField
                        Layout.preferredWidth: 300
                        placeholderText: "Введите ФИО"
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

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Label {
                        text: "Телефон:"
                        font.bold: true
                        color: "#34495e"
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 14
                    }
                    TextField {
                        id: editPhoneField
                        Layout.preferredWidth: 300
                        placeholderText: "+7-XXX-XXX-XX-XX"
                        font.pixelSize: 14
                        padding: 12
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: editPhoneField.activeFocus ? "#3498db" : "#dce0e3"
                            border.width: 2
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Label {
                        text: "Email:"
                        font.bold: true
                        color: "#34495e"
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 14
                    }
                    TextField {
                        id: editEmailField
                        Layout.preferredWidth: 300
                        placeholderText: "example@mail.ru"
                        font.pixelSize: 14
                        padding: 12
                        background: Rectangle {
                            color: "#f8f9fa"
                            radius: 8
                            border.color: editEmailField.activeFocus ? "#3498db" : "#dce0e3"
                            border.width: 2
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    Label {
                        text: "Адрес:"
                        font.bold: true
                        color: "#34495e"
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: 14
                    }
                    TextField {
                        id: editAddressField
                        Layout.preferredWidth: 300
                        placeholderText: "Введите адрес"
                        font.pixelSize: 14
                        padding: 12
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
                    visible: false
                    color: "#e74c3c"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 300
                    Layout.maximumWidth: 300
                    wrapMode: Text.WordWrap
                    font.bold: true
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10

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
                    onClicked: customerEditDialog.close()
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
                    }
                    onClicked: {
                        if (validateEditForm()) {
                            DatabaseManager.updateCustomer(
                                customerEditDialog.currentRow,
                                editNameField.text.trim(),
                                editPhoneField.text.trim(),
                                editEmailField.text.trim(),
                                editAddressField.text.trim()
                            )
                            refreshTable()
                            customerEditDialog.close()
                        }
                    }

                    function validateEditForm() {
                        const errors = []
                        const name = editNameField.text.trim()
                        const phone = editPhoneField.text.trim()
                        const email = editEmailField.text.trim()
                        const address = editAddressField.text.trim()

                        if (name.length < 10) errors.push("• ФИО должно содержать минимум 10 символов")

                        const phoneRegex = /^\+7-[0-9]{3}-[0-9]{3}-[0-9]{2}-[0-9]{2}$/
                        if (!phoneRegex.test(phone)) errors.push("• Введите корректный номер телефона в формате +7-XXX-XXX-XX-XX")

                        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
                        if (!emailRegex.test(email)) errors.push("• Введите корректный email адрес")

                        if (address.length < 15) errors.push("• Адрес должен содержать минимум 15 символов")

                        if (errors.length > 0) {
                            editValidationError.text = errors.join("\n")
                            editValidationError.visible = true
                            return false
                        }

                        editValidationError.visible = false
                        return true
                    }
                }
            }
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

    Dialog {
        id: customerViewDialog
        modal: true
        header: null
        width: 500
        height: 600
        anchors.centerIn: parent
        padding: 20

        property int currentRow: -1
        property var currentData: ({})
        property var customerOrders: ([])

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: "Карточка покупателя"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOn

                Item {
                    width: parent.width
                    implicitHeight: contentLayout.implicitHeight + 40

                    ColumnLayout {
                        id: contentLayout
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 10

                        spacing: 15
                        ColumnLayout {
                            spacing: 10

                            Repeater {
                                model: [
                                    { label: "ФИО:", value: customerViewDialog.currentData.full_name },
                                    { label: "Телефон:", value: customerViewDialog.currentData.phone },
                                    { label: "Email:", value: customerViewDialog.currentData.email },
                                    { label: "Адрес:", value: customerViewDialog.currentData.address }
                                ]

                                ColumnLayout {
                                    spacing: 2
                                    Layout.alignment: Qt.AlignHCenter

                                    Label {
                                        text: modelData.label
                                        font.bold: true
                                        color: "#34495e"
                                        Layout.alignment: Qt.AlignHCenter
                                        font.pixelSize: 14
                                    }
                                    Label {
                                        Layout.preferredWidth: 300
                                        text: modelData.value || "Не указано"
                                        wrapMode: Text.Wrap
                                        color: "#2c3e50"
                                        padding: 12
                                        background: Rectangle {
                                            color: "#f8f9fa"
                                            radius: 8
                                            border.color: "#e0e0e0"
                                            border.width: 1
                                        }
                                        horizontalAlignment: Text.AlignHCenter
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }

                        Label {
                            text: "История заказов"
                            font.bold: true
                            color: "#34495e"
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 15
                            Layout.bottomMargin: 5
                            font.pixelSize: 14
                        }

                        Repeater {
                            model: customerViewDialog.customerOrders

                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 300
                                height: 120
                                color: "#f8f9fa"
                                radius: 8
                                border.color: "#e0e0e0"
                                border.width: 1

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 2

                                    Label {
                                        text: "№ " + (modelData.order_number || "?")
                                        font.bold: true
                                        Layout.fillWidth: true
                                        font.pixelSize: 14
                                    }
                                    Label {
                                        text: getOrderTypeText(modelData.order_type)
                                        Layout.fillWidth: true
                                        font.pixelSize: 14
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Label {
                                            text: getStatusText(modelData.status)
                                            color: getStatusColor(modelData.status)
                                            font.bold: true
                                        }
                                        Item { Layout.fillWidth: true }
                                        Label {
                                            text: (modelData.total_amount || "0") + " ₽"
                                            color: "#27ae60"
                                            font.bold: true
                                            font.pixelSize: 16
                                        }
                                    }

                                    Item { Layout.fillHeight: true }

                                    Label {
                                        text: formatDate(modelData.created_at)
                                        font.pixelSize: 12
                                        color: "#7f8c8d"
                                        Layout.alignment: Qt.AlignRight
                                    }
                                }
                            }
                        }

                        Label {
                            visible: customerViewDialog.customerOrders.length === 0
                            text: "Заказов не найдено"
                            color: "#95a5a6"
                            Layout.alignment: Qt.AlignHCenter
                            font.italic: true
                            padding: 10
                            font.pixelSize: 14
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                Layout.bottomMargin: 5

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
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        customerViewDialog.close()
                        customerEditDialog.openWithData(customerViewDialog.currentRow, customerViewDialog.currentData)
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
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
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
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: customerViewDialog.close()
                }
            }
        }

        function openWithData(row) {
            currentRow = row
            currentData = DatabaseManager.getRowData(root.tableName, row)
            customerOrders = DatabaseManager.getCustomerOrders(currentData.id)
            open()
        }
    }

    Dialog {
        id: filterResultsDialog
        modal: true
        header: null
        width: 800
        height: 600
        anchors.centerIn: parent
        padding: 20

        property var filteredCustomers: []

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            Label {
                Layout.fillWidth: true
                text: "Результаты фильтрации"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: "#3498db"
                    radius: 8

                    Row {
                        id: headerRow
                        anchors.fill: parent

                        property var colWeights: [0.30, 0.20, 0.25, 0.10, 0.15]

                        function getColWidth(index) {
                            return width * colWeights[index]
                        }

                        Repeater {
                            model: ["ФИО", "Телефон", "Email", "Заказов", "Сумма"]
                            Rectangle {
                                width: headerRow.getColWidth(index)
                                height: parent.height
                                color: "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ListView {
                        id: filteredDataListView
                        width: parent.width
                        model: filterResultsDialog.filteredCustomers

                        delegate: Rectangle {
                            width: headerRow.width
                            height: 40
                            color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"

                            Row {
                                anchors.fill: parent

                                Item {
                                    width: headerRow.getColWidth(0)
                                    height: parent.height

                                    Text {
                                        id: txtName
                                        anchors.fill: parent
                                        text: modelData.full_name
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        font.pixelSize: 12
                                        padding: 5
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        ToolTip.visible: containsMouse && txtName.truncated
                                        ToolTip.text: txtName.text
                                        ToolTip.delay: 500
                                    }
                                }

                                Text {
                                    width: headerRow.getColWidth(1)
                                    height: parent.height
                                    text: modelData.phone
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    font.pixelSize: 12
                                    padding: 5
                                }

                                Item {
                                    width: headerRow.getColWidth(2)
                                    height: parent.height
                                    Text {
                                        id: txtEmail
                                        anchors.fill: parent
                                        text: modelData.email
                                        verticalAlignment: Text.AlignVCenter
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        font.pixelSize: 12
                                        padding: 5
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        ToolTip.visible: containsMouse && txtEmail.truncated
                                        ToolTip.text: txtEmail.text
                                        ToolTip.delay: 500
                                    }
                                }

                                Text {
                                    width: headerRow.getColWidth(3)
                                    height: parent.height
                                    text: modelData.order_count
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    font.bold: true
                                    font.pixelSize: 12
                                }

                                Text {
                                    width: headerRow.getColWidth(4)
                                    height: parent.height
                                    text: (modelData.total_amount || "0") + " ₽"
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    color: "#27ae60"
                                    font.bold: true
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }
                }
            }

            Label {
                visible: filterResultsDialog.filteredCustomers.length === 0
                text: "Нет покупателей за указанный период"
                Layout.alignment: Qt.AlignHCenter
                color: "#e74c3c"
                font.pixelSize: 16
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                text: "Закрыть"
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
                onClicked: filterResultsDialog.close()
            }
        }

        function openWithData(customers) {
            filteredCustomers = customers
            open()
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
                text: "Вы действительно хотите удалить этого покупателя? Это действие необратимо."
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
                        DatabaseManager.deleteCustomer(customerViewDialog.currentRow)
                        refreshTable()
                        customerViewDialog.close()
                        deleteConfirmDialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: messageDialog
        modal: true
        header: null
        width: 350
        height: 180
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
            spacing: 10

            Label {
                text: "Ошибка"
                font.bold: true
                font.pixelSize: 18
                color: "#e74c3c"
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "Введите корректные даты для фильтрации"
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: 14
            }

            Button {
                text: "OK"
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 100
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
                onClicked: messageDialog.accept()
            }
        }
    }
}
