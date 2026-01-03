import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Database

Page {
    id: root
    signal adminCreated()

    property bool isLoading: false

    // Индикатор загрузки (блокирует интерфейс во время создания)
    MouseArea {
        anchors.fill: parent
        visible: root.isLoading
        hoverEnabled: true
        z: 99
        onClicked: {} // Блокируем клики
        BusyIndicator {
            anchors.centerIn: parent
            running: root.isLoading
        }
    }

    // Обработка ответов от базы данных
    Connections {
        target: DatabaseManager

        function onFirstAdminCreatedResult(success, message) {
            root.isLoading = false
            if (success) {
                infoLbl.text = "Администратор создан успешно"
                infoLbl.color = "green"
                // Даем пользователю увидеть сообщение перед переходом
                timer.start()
            } else {
                infoLbl.text = message
                infoLbl.color = "red"
            }
        }
    }

    // Таймер для небольшой задержки перед переходом (для красоты UX)
    Timer {
        id: timer
        interval: 1000
        repeat: false
        onTriggered: root.adminCreated()
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: 300
        spacing: 15

        Label {
            text: "Добро пожаловать!"
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1.5
            color: "black"
        }

        Label {
            text: "В системе нет администратора.\nСоздайте первую учетную запись."
            font.pixelSize: 14
            color: "#7f8c8d"
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 5
        }

        TextField {
            id: loginField
            color: "black"
            placeholderText: "Придумайте логин"
            font.pixelSize: 14
            Layout.fillWidth: true
            enabled: !root.isLoading
            background: Rectangle {
                border.color: loginField.activeFocus ? "#3498db" : "#dce0e3"
                border.width: 1
                radius: 4
            }
        }

        TextField {
            id: passField
            color: "black"
            placeholderText: "Придумайте пароль"
            echoMode: TextInput.Password
            font.pixelSize: 14
            Layout.fillWidth: true
            enabled: !root.isLoading
            background: Rectangle {
                border.color: passField.activeFocus ? "#3498db" : "#dce0e3"
                border.width: 1
                radius: 4
            }
        }

        TextField {
            id: confirmPassField
            color: "black"
            placeholderText: "Повторите пароль"
            echoMode: TextInput.Password
            font.pixelSize: 14
            Layout.fillWidth: true
            enabled: !root.isLoading
            background: Rectangle {
                border.color: (confirmPassField.text !== passField.text && confirmPassField.text.length > 0) ? "red" : (confirmPassField.activeFocus ? "#3498db" : "#dce0e3")
                border.width: 1
                radius: 4
            }
        }

        Button {
            id: createBtn
            text: "Создать и войти"
            font.pixelSize: 16
            Layout.fillWidth: true
            enabled: !root.isLoading

            background: Rectangle {
                color: parent.down ? "#2980b9" : "#3498db"
                radius: 4
            }

            contentItem: Text {
                text: parent.text
                font: parent.font
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                // Валидация полей
                if (loginField.text.length < 3) {
                    infoLbl.text = "Логин слишком короткий (минимум 3 символа)"
                    infoLbl.color = "red"
                    return
                }

                if (passField.text.length < 6) {
                    infoLbl.text = "Пароль слишком короткий (минимум 6 символов)"
                    infoLbl.color = "red"
                    return
                }

                if (passField.text !== confirmPassField.text) {
                    infoLbl.text = "Пароли не совпадают"
                    infoLbl.color = "red"
                    return
                }

                // Запуск асинхронного процесса
                root.isLoading = true
                infoLbl.text = "Создание учетной записи..."
                infoLbl.color = "black"

                DatabaseManager.createFirstAdminAsync(loginField.text, passField.text)
            }
        }

        Label {
            id: infoLbl
            text: "Заполните все поля"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
        }
    }
}
