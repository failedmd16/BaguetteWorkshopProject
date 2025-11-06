import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import databasemanager

Page {
    id: root
    property string tableName: "customers"
    property int selectedRow: -1

    Rectangle {
        anchors.fill: parent
        color: "#f8f9fa"
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

        // Панель фильтрации по периоду
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "#ffffff"
            radius: 10
            border.color: "#e0e0e0"
            border.width: 1

            Row {
                anchors.left: parent.left
                anchors.margins: 10
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    text: "🔍 Фильтр покупателей по периоду заказов"
                    font.bold: true
                    color: "#2c3e50"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                Label {
                    text: "С:"
                    color: "#34495e"
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextField {
                    id: startDateField
                    width: 150
                    height: 40
                    placeholderText: "дд.мм.гггг"
                    verticalAlignment: TextField.AlignVCenter
                    font.pixelSize: 14
                    padding: 12
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 8
                        border.color: startDateField.activeFocus ? "#3498db" : "#dce0e3"
                        border.width: 2
                    }
                }

                Label {
                    text: "По:"
                    color: "#34495e"
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }

                TextField {
                    id: endDateField
                    width: 150
                    height: 40
                    placeholderText: "дд.мм.гггг"
                    verticalAlignment: TextField.AlignVCenter
                    font.pixelSize: 14
                    padding: 12
                    background: Rectangle {
                        color: "#f8f9fa"
                        radius: 8
                        border.color: endDateField.activeFocus ? "#3498db" : "#dce0e3"
                        border.width: 2
                    }
                }

                Button {
                    text: "📊 Применить фильтр"
                    font.bold: true
                    width: 180
                    height: 40
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
                        if (startDateField.text && endDateField.text) {
                            if (isValidDate(startDateField.text) && isValidDate(endDateField.text)) {
                                var customers = dbmanager.getCustomersWithOrdersInPeriod(
                                    convertToSqlDate(startDateField.text),
                                    convertToSqlDate(endDateField.text)
                                )
                                filterResultsDialog.openWithData(customers)
                            } else {
                                messageDialog.open()
                            }
                        } else {
                            messageDialog.open()
                        }
                    }
                }

                Button {
                    text: "❌ Сбросить"
                    font.bold: true
                    width: 120
                    height: 40
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
                        startDateField.text = ""
                        endDateField.text = ""
                        tableview.model = dbmanager.getTableModel(root.tableName)
                    }
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

        // Таблица с покупателями
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
                    model: dbmanager.getTableModel(root.tableName)

                    columnWidthProvider: function(column) {
                        return tableview.width / 5
                    }

                    delegate: Rectangle {
                        implicitHeight: 45
                        color: row % 2 === 0 ? "#ffffff" : "#f8f9fa"
                        border.color: "#e9ecef"

                        property var rowData: model ? dbmanager.getRowData(root.tableName, row) : ({})

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
                text: "➕ Добавить покупателя"
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
                text: "🔄 Обновить"
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
                onClicked: tableview.model = dbmanager.getTableModel(root.tableName)
            }
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

    // Диалог добавления покупателя
    Dialog {
        id: customerAddDialog
        modal: true
        title: "👤 Добавить нового покупателя"
        width: 400
        height: 400
        anchors.centerIn: parent
        padding: 0

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            anchors.margins: 0

            Label {
                Layout.fillWidth: true
                text: "👤 Добавить нового покупателя"
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

                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: parent.width
                    spacing: 15
                    anchors.top: parent.top
                    anchors.topMargin: 10

                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "👤 ФИО:"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            id: addNameField
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

                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📞 Телефон:"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            id: addPhoneField
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

                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📧 Email:"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            id: addEmailField
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

                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "🏠 Адрес:"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            id: addAddressField
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
                        id: validationError
                        width: parent.width
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
                        onClicked: customerAddDialog.close()
                    }

                    Button {
                        text: "✅ Добавить"
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
                        function validateAddForm() {
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
                    }
                }
            }
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

    // Диалог результатов фильтрации
    Dialog {
        id: filterResultsDialog
        modal: true
        title: "📊 Покупатели с заказами за период"
        width: 800
        height: 600
        anchors.centerIn: parent
        padding: 0

        property var filteredCustomers: []

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
                text: "📊 Покупатели с заказами за период"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 15
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: "#3498db"
                    radius: 8

                    Row {
                        anchors.fill: parent
                        spacing: 1

                        Repeater {
                            model: ["ФИО", "Телефон", "Email", "Кол-во заказов", "Общая сумма"]

                            Rectangle {
                                width: (parent.width - 4) / 5
                                height: parent.height
                                color: "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: filterResultsDialog.filteredCustomers
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        width: parent.width
                        height: 40
                        color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"

                        Row {
                            anchors.fill: parent
                            spacing: 1

                            Text {
                                width: (parent.width - 4) / 5
                                height: parent.height
                                text: modelData.full_name || ""
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                color: "#2c3e50"
                                font.pixelSize: 12
                                padding: 8
                            }

                            Text {
                                width: (parent.width - 4) / 5
                                height: parent.height
                                text: modelData.phone || ""
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                color: "#2c3e50"
                                font.pixelSize: 12
                                padding: 8
                            }

                            Text {
                                width: (parent.width - 4) / 5
                                height: parent.height
                                text: modelData.email || ""
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                color: "#2c3e50"
                                font.pixelSize: 12
                                padding: 8
                            }

                            Text {
                                width: (parent.width - 4) / 5
                                height: parent.height
                                text: modelData.order_count || "0"
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                color: "#2c3e50"
                                font.pixelSize: 12
                                font.bold: true
                                padding: 8
                            }

                            Text {
                                width: (parent.width - 4) / 5
                                height: parent.height
                                text: (modelData.total_amount || "0") + " ₽"
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                color: "#27ae60"
                                font.pixelSize: 12
                                font.bold: true
                                padding: 8
                            }
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: filterResultsDialog.filteredCustomers.length === 0 ?
                          "Покупателей с заказами за выбранный период не найдено" :
                          "Найдено покупателей: " + filterResultsDialog.filteredCustomers.length
                    horizontalAlignment: Text.AlignHCenter
                    color: filterResultsDialog.filteredCustomers.length === 0 ? "#e74c3c" : "#27ae60"
                    font.pixelSize: 14
                    padding: 10
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                color: "transparent"

                Button {
                    anchors.centerIn: parent
                    text: "❌ Закрыть"
                    width: 120
                    height: 40
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
                    onClicked: filterResultsDialog.close()
                }
            }
        }

        function openWithData(customers) {
            filteredCustomers = customers
            open()
        }
    }

    // Диалог просмотра покупателя
    Dialog {
        id: customerViewDialog
        modal: true
        title: "👤 Данные покупателя"
        width: 350
        height: 600
        anchors.centerIn: parent
        padding: 0

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
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: "👤 Данные покупателя"
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

                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "👤 ФИО:"
                            font.bold: true
                            color: "#34495e"
                        }
                        Label {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: customerViewDialog.currentData.full_name || "Не указано"
                            wrapMode: Text.Wrap
                            color: "#2c3e50"
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📞 Телефон:"
                            font.bold: true
                            color: "#34495e"
                        }
                        Label {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: customerViewDialog.currentData.phone || "Не указано"
                            wrapMode: Text.Wrap
                            color: "#2c3e50"
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📧 Email:"
                            font.bold: true
                            color: "#34495e"
                        }
                        Label {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: customerViewDialog.currentData.email || "Не указано"
                            wrapMode: Text.Wrap
                            color: "#2c3e50"
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "🏠 Адрес:"
                            font.bold: true
                            color: "#34495e"
                        }
                        Label {
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: customerViewDialog.currentData.address || "Не указано"
                            wrapMode: Text.Wrap
                            color: "#2c3e50"
                            padding: 12
                            background: Rectangle {
                                color: "#f8f9fa"
                                radius: 8
                            }
                        }
                    }

                    Label {
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "📦 Заказы покупателя:"
                        font.bold: true
                        color: "#34495e"
                    }

                    Repeater {
                        model: customerViewDialog.customerOrders

                        Column {
                            width: parent.width
                            spacing: 0

                            Rectangle {
                                width: 300
                                height: 140
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: "#f8f9fa"
                                radius: 8

                                Column {
                                    width: 280  // Фиксированная ширина для центрирования
                                    anchors.centerIn: parent
                                    spacing: 5

                                    // Центрируем каждую строку
                                    Row {
                                        width: parent.width
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 10

                                        Label {
                                            width: 100
                                            text: "№ заказа:"
                                            font.bold: true
                                            color: "#34495e"
                                        }
                                        Label {
                                            width: 170
                                            text: modelData.order_number || "Не указан"
                                            wrapMode: Text.Wrap
                                            color: "#2c3e50"
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 10

                                        Label {
                                            width: 100
                                            text: "Тип:"
                                            font.bold: true
                                            color: "#34495e"
                                        }
                                        Label {
                                            width: 170
                                            text: getOrderTypeText(modelData.order_type)
                                            wrapMode: Text.Wrap
                                            color: "#2c3e50"
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 10

                                        Label {
                                            width: 100
                                            text: "Статус:"
                                            font.bold: true
                                            color: "#34495e"
                                        }
                                        Label {
                                            width: 170
                                            text: getStatusText(modelData.status)
                                            wrapMode: Text.Wrap
                                            color: getStatusColor(modelData.status)
                                            font.bold: true
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 10

                                        Label {
                                            width: 100
                                            text: "Сумма:"
                                            font.bold: true
                                            color: "#34495e"
                                        }
                                        Label {
                                            width: 170
                                            text: modelData.total_amount ? modelData.total_amount + " ₽" : "0 ₽"
                                            wrapMode: Text.Wrap
                                            color: "#2c3e50"
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 10

                                        Label {
                                            width: 100
                                            text: "Дата создания:"
                                            font.bold: true
                                            color: "#34495e"
                                        }
                                        Label {
                                            width: 170
                                            text: modelData.created_at ? formatDate(modelData.created_at) : "Не указана"
                                            wrapMode: Text.Wrap
                                            color: "#2c3e50"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        width: 300
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: customerViewDialog.customerOrders.length === 0
                        text: "Заказов нет"
                        horizontalAlignment: Text.AlignHCenter
                        color: "#7f8c8d"
                        font.italic: true
                        padding: 20
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
                            color: parent.down ? "#f39c12" : "#f1c40f"
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
                            customerViewDialog.close()
                            customerEditDialog.openWithData(customerViewDialog.currentRow, customerViewDialog.currentData)
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
                        onClicked: customerViewDialog.close()
                    }
                }
            }
        }

        function openWithData(row) {
            currentRow = row
            currentData = dbmanager.getRowData(root.tableName, row)
            customerOrders = dbmanager.getCustomerOrders(currentData.id)
            open()
        }
    }

    // Диалог редактирования покупателя
    Dialog {
        id: customerEditDialog
        modal: true
        title: "✏️ Редактирование данных покупателя"
        width: 400
        height: 450
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
                text: "✏️ Редактирование данных покупателя"
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

                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "👤 ФИО:"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            id: editNameField
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
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

                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📞 Телефон:"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            id: editPhoneField
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
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

                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "📧 Email:"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            id: editEmailField
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
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

                    Column {
                        width: parent.width
                        spacing: 5

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "🏠 Адрес:"
                            font.bold: true
                            color: "#34495e"
                        }
                        TextField {
                            id: editAddressField
                            width: 300
                            anchors.horizontalCenter: parent.horizontalCenter
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

                        function validateEditForm() {
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
                        onClicked: customerEditDialog.close()
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

    // Диалог подтверждения удаления
    Dialog {
        id: deleteConfirmDialog
        modal: true
        title: "⚠️ Подтверждение удаления"
        width: 400
        height: 250
        anchors.centerIn: parent
        padding: 0

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
                text: "⚠️ Подтверждение удаления"
                font.bold: true
                font.pixelSize: 18
                color: "#2c3e50"
                padding: 10
                horizontalAlignment: Text.AlignHCenter
            }

            Column {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 20
                spacing: 10
                padding: 10

                Label {
                    width: parent.width
                    text: "🗑️ Вы уверены, что хотите удалить этого покупателя?"
                    wrapMode: Text.Wrap
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    color: "#2c3e50"
                }

                Label {
                    width: parent.width
                    text: "Это действие нельзя отменить."
                    wrapMode: Text.Wrap
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    color: "#7f8c8d"
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
                        text: "❌ Нет"
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
                        onClicked: deleteConfirmDialog.close()
                    }

                    Button {
                        text: "✅ Да"
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
                        onClicked: {
                            dbmanager.deleteCustomer(customerViewDialog.currentRow)
                            tableview.model = dbmanager.getTableModel(root.tableName)
                            customerViewDialog.close()
                            deleteConfirmDialog.close()
                        }
                    }
                }
            }
        }
    }

    Dialog {
        id: messageDialog
        modal: true
        title: "❌ Ошибка"
        anchors.centerIn: parent
        width: 350
        height: 220

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: "#e0e0e0"
            border.width: 1
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10
            anchors.margins: 10

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "#e74c3c"
                radius: 8

                Label {
                    anchors.fill: parent
                    anchors.margins: 15
                    font.pixelSize: 14
                    text: "Введите корректные даты для фильтрации"
                    wrapMode: Text.Wrap
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    color: "white"
                    font.bold: true
                }
            }

            Item {
                Layout.fillHeight: true
                Layout.minimumHeight: 10
            }

            Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 120
                Layout.preferredHeight: 40
                Layout.bottomMargin: 10

                text: "✅ OK"
                background: Rectangle {
                    color: parent.down ? "#27ae60" : "#2ecc71"
                    radius: 8
                    border.color: "#27ae60"
                    border.width: 1
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                }
                onClicked: messageDialog.accept()
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            tableview.model = dbmanager.getTableModel(root.tableName)
            var endDate = new Date()
            var startDate = new Date()
            startDate.setDate(startDate.getDate() - 30)

            startDateField.text = formatDate(startDate.toISOString())
            endDateField.text = formatDate(endDate.toISOString())
        }
    }
}
