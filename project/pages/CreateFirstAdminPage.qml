import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Database // Предполагаем, что этот импорт нужен, как в примере

Page {
    id: root
    signal adminCreated()

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

        // Информационный текст перенесен сюда, чтобы соответствовать стилю заголовков
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
                // Валидация полей в стиле примера (через нижний Label)
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

                // Попытка создания в базе
                if (DatabaseManager.createFirstAdmin(loginField.text, passField.text)) {
                    infoLbl.text = "Администратор создан успешно"
                    infoLbl.color = "green"
                    root.adminCreated()
                } else {
                    infoLbl.text = "Ошибка создания записи"
                    infoLbl.color = "red"
                }
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
