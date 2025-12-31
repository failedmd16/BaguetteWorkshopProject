import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.LocalStorage
import Database

Page {
    signal backToLogin()

    ColumnLayout {
        anchors.centerIn: parent
        width: 300
        spacing: 15

        Label {
            text: "Регистрация аккаунта"
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1.5
            color: "black"
        }

        TextField {
            id: loginTF
            color: "black"
            placeholderText: "Логин"
            font.pixelSize: 14
            Layout.fillWidth: true
            background: Rectangle {
                border.color: loginTF.activeFocus ? "#3498db" : "#dce0e3"
                border.width: 1
                radius: 4
            }
        }

        TextField {
            id: passwordTF
            color: "black"
            placeholderText: "Пароль"
            echoMode: TextInput.Password
            font.pixelSize: 14
            Layout.fillWidth: true
            background: Rectangle {
                border.color: passwordTF.activeFocus ? "#3498db" : "#dce0e3"
                border.width: 1
                radius: 4
            }
        }

        TextField {
            id: codeTF
            color: "black"
            placeholderText: "Код"
            echoMode: TextInput.Password
            font.pixelSize: 14
            Layout.fillWidth: true
            background: Rectangle {
                border.color: codeTF.activeFocus ? "#3498db" : "#dce0e3"
                border.width: 1
                radius: 4
            }
        }

        ComboBox {
            id: rolesComboBox
            editable: false
            Layout.fillWidth: true
            model: ["Продавец", "Мастер производства"]

            contentItem: Text {
                text: rolesComboBox.displayText
                color: "#000000"
                font: rolesComboBox.font
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
                leftPadding: 12
            }

            background: Rectangle {
                color: "#f8f9fa"
                radius: 6
                border.color: rolesComboBox.activeFocus ? "#3498db" : "#dce0e3"
            }
        }

        RowLayout {
            spacing: 40
            Layout.fillWidth: true

            Button {
                id: registrationBtn
                text: "Авторизация"
                font.pixelSize: 16
                Layout.fillWidth: true

                background: Rectangle {
                    color: parent.down ? "#CECECE" : "#798081"
                    radius: 4
                }

                contentItem: Text {
                    text: parent.text
                    font: parent.font
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: backToLogin()
            }

            Button {
                id: enterBtn
                text: "Зарегистрировать"
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
                    var user_name = loginTF.text.trim()
                    var user_password = passwordTF.text.trim()
                    var admin_code = codeTF.text.trim()

                    if (user_name === "") {
                        infoLbl.text = "Логин не может быть пустым"
                        infoLbl.color = "red"
                        return
                    }

                    if (user_password === "") {
                        infoLbl.text = "Пароль не может быть пустым"
                        infoLbl.color = "red"
                        return
                    }

                    if (admin_code === "") {
                        infoLbl.text = "Код администратора не может быть пустым"
                        infoLbl.color = "red"
                        return
                    }

                    if (DatabaseManager.registrationUser(user_name, user_password, rolesComboBox.currentText, admin_code)) {
                        infoLbl.text = "Регистрация успешна"
                        infoLbl.color = "green"
                        loginTF.clear()
                        passwordTF.clear()
                        codeTF.clear()
                    } else {
                        infoLbl.text = "Ошибка при регистрации, проверьте введённый логин, пароль и код"
                        infoLbl.color = "red"
                    }
                }
            }
        }

        Label {
            id: infoLbl
            text: "Введите учетные данные"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 300
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
