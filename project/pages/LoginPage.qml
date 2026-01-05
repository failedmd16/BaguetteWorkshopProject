import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.LocalStorage
import Database

Page {
    id: root
    signal loginSellerSuccess()
    signal loginMasterSuccess()
    signal loginAdminSuccess

    property bool isLoading: false

    MouseArea {
        anchors.fill: parent
        visible: root.isLoading
        hoverEnabled: true
        z: 99
        onClicked: { }
        BusyIndicator {
            anchors.centerIn: parent
            running: root.isLoading
        }
    }

    Connections {
        target: DatabaseManager

        function onLoginResult(success, role, message) {
            root.isLoading = false
            if (success) {
                infoLbl.text = "Вход успешен"
                infoLbl.color = "green"

                if (role === "Продавец")
                    loginSellerSuccess()
                else if (role === "Мастер производства")
                    loginMasterSuccess()
                else if (role === "Администратор")
                    loginAdminSuccess()
            } else {
                infoLbl.text = message
                infoLbl.color = "red"
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: 300
        spacing: 15

        Label {
            text: "Вход в систему"
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
            enabled: !root.isLoading
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
            enabled: !root.isLoading
            background: Rectangle {
                border.color: passwordTF.activeFocus ? "#3498db" : "#dce0e3"
                border.width: 1
                radius: 4
            }
        }

        Button {
            id: enterBtn
            text: "Войти"
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

                root.isLoading = true
                infoLbl.text = "Выполняется вход..."
                infoLbl.color = "black"

                DatabaseManager.loginUserAsync(user_name, user_password)
            }
        }

        Label {
            id: infoLbl
            text: "Введите учетные данные"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
