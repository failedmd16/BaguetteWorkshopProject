import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.LocalStorage
import databasemanager

Page {
    signal loginSellerSuccess()
    signal loginMasterSuccess()

    property color blackColor: "#000000"
    property color whiteColor: "#FFFFFF"
    property color grayColor: "#808080"
    property color lightGrayColor: "#D3D3D3"
    property color darkGrayColor: "#404040"

    DatabaseManager {
        id: dbmanager
    }

    background: Rectangle { color: whiteColor }

    ColumnLayout {
        anchors.centerIn: parent
        width: 300
        spacing: 15

        Label {
            text: "Вход в систему"
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
            color: blackColor
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: grayColor
        }

        TextField {
            id: loginTF
            placeholderText: "Логин"
            font.pixelSize: 14
            Layout.fillWidth: true
            background: Rectangle {
                border.color: grayColor
                border.width: 1
                radius: 4
            }
        }

        TextField {
            id: passwordTF
            placeholderText: "Пароль"
            echoMode: TextInput.Password
            font.pixelSize: 14
            Layout.fillWidth: true
            background: Rectangle {
                border.color: grayColor
                border.width: 1
                radius: 4
            }
        }

        Button {
            id: enterBtn
            text: "Войти"
            font.pixelSize: 16
            Layout.fillWidth: true

            background: Rectangle {
                color: parent.down ? darkGrayColor : (parent.hovered ? lightGrayColor : grayColor)
                radius: 4
            }
            contentItem: Text {
                text: parent.text
                font: parent.font
                color: whiteColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                var user_name = loginTF.text.trim()
                var user_password = passwordTF.text.trim()

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

                if (dbmanager.loginUser(user_name, user_password)) {
                    infoLbl.text = "Вход успешен"
                    infoLbl.color = "green"

                    if (dbmanager.getCurrentUserRole() === "Продавец")
                        loginSellerSuccess()
                        else if (dbmanager.getCurrentUserRole() === "Мастер производства")
                        loginMasterSuccess()
                } else {
                    infoLbl.text = "Неверный логин или пароль"
                    infoLbl.color = "red"
                }
            }
        }

        Label {
            id: infoLbl
            text: "Введите учетные данные"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
            color: grayColor
        }
    }
}
