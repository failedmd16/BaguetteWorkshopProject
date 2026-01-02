import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.LocalStorage
import Database

Page {
    id: root

    // Состояние загрузки
    property bool isLoading: false

    // Компонент поля ввода (без изменений)
    component CustomTextField: TextField {
        color: "black"
        font.pixelSize: 14
        Layout.fillWidth: true
        // Блокируем ввод при загрузке
        enabled: !root.isLoading
        background: Rectangle {
            color: parent.enabled ? "white" : "#f0f0f0"
            border.color: parent.activeFocus ? "#3498db" : "#dce0e3"
            border.width: 1
            radius: 4
        }
    }

    // Обработка сигналов от C++
    Connections {
        target: DatabaseManager // Убедитесь, что синглтон доступен под этим именем

        function onUserOperationResult(success, message) {
            root.isLoading = false
            infoLbl.text = message
            infoLbl.color = success ? "green" : "red"

            if (success) {
                // Очистка полей в зависимости от текущей вкладки
                if (bar.currentIndex === 0) { // Регистрация
                    regLogin.clear(); regPass.clear(); regConfirm.clear()
                } else if (bar.currentIndex === 1) { // Смена пароля
                    editLogin.clear(); editPass.clear(); editConfirm.clear()
                } else if (bar.currentIndex === 2) { // Удаление
                    delLogin.clear()
                }
            }
        }
    }

    // Индикатор загрузки поверх контента
    BusyIndicator {
        anchors.centerIn: parent
        running: root.isLoading
        z: 10
    }

    // Блокировщик кликов при загрузке
    MouseArea {
        anchors.fill: parent
        visible: root.isLoading
        hoverEnabled: true
        onClicked: {} // Поглощаем клики
        z: 9
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: 300
        spacing: 15

        // Прозрачность при загрузке для визуального эффекта
        opacity: root.isLoading ? 0.6 : 1.0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Label {
            text: {
                if (bar.currentIndex === 0) return "Регистрация"
                if (bar.currentIndex === 1) return "Смена пароля"
                return "Удаление"
            }
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        TabBar {
            id: bar
            Layout.fillWidth: true
            implicitWidth: 300
            enabled: !root.isLoading // Блокируем табы

            background: Rectangle { color: "transparent" }

            component MyTabButton: TabButton {
                id: tabBtn
                width: (bar.availableWidth / 3)
                implicitWidth: 100
                contentItem: Text {
                    text: tabBtn.text
                    font: tabBtn.font
                    color: {
                        if (tabBtn.TabBar.index === 2 && tabBtn.checked) return "#e74c3c"
                        return tabBtn.checked ? "#3498db" : "#7f8c8d"
                    }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    color: "transparent"
                    Rectangle {
                        width: parent.width
                        height: 2
                        anchors.bottom: parent.bottom
                        color: {
                            if (!tabBtn.checked) return "transparent"
                            return (tabBtn.TabBar.index === 2) ? "#e74c3c" : "#3498db"
                        }
                    }
                }
            }

            MyTabButton { text: "Создать"; font.pixelSize: 13 }
            MyTabButton { text: "Изменить"; font.pixelSize: 13 }
            MyTabButton { text: "Удалить"; font.pixelSize: 13 }

            onCurrentIndexChanged: {
                infoLbl.text = "Введите данные"
                infoLbl.color = "black"

                regLogin.text = ""; regPass.text = ""; regConfirm.text = ""
                editLogin.text = ""; editPass.text = ""; editConfirm.text = ""
                delLogin.text = ""
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#dce0e3"
            Layout.topMargin: -10
            z: -1
        }

        StackLayout {
            currentIndex: bar.currentIndex
            Layout.fillWidth: true

            // --- ВКЛАДКА 1: СОЗДАТЬ ---
            ColumnLayout {
                spacing: 15

                CustomTextField {
                    id: regLogin
                    placeholderText: "Логин нового пользователя"
                }

                CustomTextField {
                    id: regPass
                    placeholderText: "Пароль"
                    echoMode: TextInput.Password
                }

                CustomTextField {
                    id: regConfirm
                    placeholderText: "Повторите пароль"
                    echoMode: TextInput.Password
                    background: Rectangle {
                        border.color: (regConfirm.text !== regPass.text && regConfirm.text.length > 0) ? "red" : (regConfirm.activeFocus ? "#3498db" : "#dce0e3")
                        border.width: 1
                        radius: 4
                    }
                }

                ComboBox {
                    id: rolesComboBox
                    Layout.fillWidth: true
                    enabled: !root.isLoading
                    model: ["Продавец", "Мастер производства", "Администратор"]
                    font.pixelSize: 14

                    contentItem: Text {
                        text: rolesComboBox.displayText
                        color: "black"
                        font: rolesComboBox.font
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }
                    background: Rectangle {
                        border.color: rolesComboBox.activeFocus ? "#3498db" : "#dce0e3"
                        radius: 4
                        border.width: 1
                    }
                }

                Button {
                    text: "Зарегистрировать"
                    Layout.fillWidth: true
                    font.pixelSize: 16
                    enabled: !root.isLoading
                    background: Rectangle { color: parent.down ? "#2980b9" : "#3498db"; radius: 4 }
                    contentItem: Text { text: parent.text; font: parent.font; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }

                    onClicked: {
                        // Предварительная валидация на клиенте
                        if (regLogin.text.length < 3 || regPass.text.length < 6) {
                            infoLbl.text = "Логин (мин 3) или пароль (мин 6) слишком короткие"
                            infoLbl.color = "red"
                            return
                        }
                        if (regPass.text !== regConfirm.text) {
                            infoLbl.text = "Пароли не совпадают"
                            infoLbl.color = "red"
                            return
                        }

                        // Асинхронный вызов
                        root.isLoading = true
                        infoLbl.text = "Обработка..."
                        infoLbl.color = "gray"
                        DatabaseManager.registerUserAsync(regLogin.text, regPass.text, rolesComboBox.currentText)
                    }
                }
            }

            // --- ВКЛАДКА 2: ИЗМЕНИТЬ ---
            ColumnLayout {
                spacing: 15

                CustomTextField {
                    id: editLogin
                    placeholderText: "Логин пользователя"
                }

                CustomTextField {
                    id: editPass
                    placeholderText: "Новый пароль"
                    echoMode: TextInput.Password
                }

                CustomTextField {
                    id: editConfirm
                    placeholderText: "Повторите новый пароль"
                    echoMode: TextInput.Password
                    background: Rectangle {
                        border.color: (editConfirm.text !== editPass.text && editConfirm.text.length > 0) ? "red" : (editConfirm.activeFocus ? "#3498db" : "#dce0e3")
                        border.width: 1
                        radius: 4
                    }
                }

                Button {
                    text: "Сменить пароль"
                    Layout.fillWidth: true
                    font.pixelSize: 16
                    enabled: !root.isLoading
                    background: Rectangle { color: parent.down ? "#2980b9" : "#3498db"; radius: 4 }
                    contentItem: Text { text: parent.text; font: parent.font; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }

                    onClicked: {
                        if (editLogin.text === "") {
                            infoLbl.text = "Введите логин пользователя"
                            infoLbl.color = "red"
                            return
                        }
                        if (editPass.text.length < 6) {
                            infoLbl.text = "Пароль слишком короткий"
                            infoLbl.color = "red"
                            return
                        }
                        if (editPass.text !== editConfirm.text) {
                            infoLbl.text = "Пароли не совпадают"
                            infoLbl.color = "red"
                            return
                        }

                        // Асинхронный вызов
                        root.isLoading = true
                        infoLbl.text = "Обработка..."
                        infoLbl.color = "gray"
                        DatabaseManager.updateUserPasswordAsync(editLogin.text, editPass.text)
                    }
                }
            }

            // --- ВКЛАДКА 3: УДАЛИТЬ ---
            ColumnLayout {
                spacing: 15

                Label {
                    text: "Введите логин пользователя, которого хотите удалить."
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    color: "#7f8c8d"
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                }

                CustomTextField {
                    id: delLogin
                    placeholderText: "Логин для удаления"
                }

                Button {
                    text: "Удалить навсегда"
                    Layout.fillWidth: true
                    font.pixelSize: 16
                    enabled: !root.isLoading
                    background: Rectangle { color: parent.down ? "#c0392b" : "#e74c3c"; radius: 4 }
                    contentItem: Text { text: parent.text; font: parent.font; color: "white"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }

                    onClicked: {
                        if (delLogin.text === "") {
                            infoLbl.text = "Введите логин"
                            infoLbl.color = "red"
                            return
                        }

                        // Асинхронный вызов
                        root.isLoading = true
                        infoLbl.text = "Обработка..."
                        infoLbl.color = "gray"
                        DatabaseManager.deleteUserAsync(delLogin.text)
                    }
                }
            }
        }

        Label {
            id: infoLbl
            text: "Выберите действие"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 300
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 5
        }
    }
}
