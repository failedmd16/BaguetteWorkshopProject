import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.LocalStorage

Window {
    width: 1280
    height: 720
    visible: true
    title: qsTr("Багетная мастерская")
    ColumnLayout {
        width: parent.width
        Label {
            id: enterLabel
            text: "Вход в систему"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            id: loginTF
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
        }

        TextField {
            id: passwordTF
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
        }

        Button {
            id: enterBtn
            text: "Войти"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
            onClicked: {
                var db = LocalStorage.openDatabaseSync("db", "1.0", "База данных", 1000000)
                if (!db) {
                    Logger.error("Не удалось подключиться к базе данных.")
                    return
                }

                var user_name = loginTF.text.trim()
                var user_password = passwordTF.text.trim()

                db.transaction(function (tx) {
                    tx.executeSql('CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, user TEXT UNIQUE, password TEXT)')

                    var rs = tx.executeSql('SELECT * FROM users WHERE user = ?', [user_name])

                    if (user_name === "") {
                        infoLbl.text = "Юзернейм пустой"
                        return
                    }

                    if (rs.rows.length === 1) {
                        var db_user = rs.rows.item(0).user
                        var db_pass = rs.rows.item(0).password
                        if (db_pass === user_password)
                            infoLbl.text = "Вход успешен"
                        else
                            infoLbl.text = "Неудачная попытка авторизации"
                    } else {
                        infoLbl.text = "Неудачная попытка авторизации"
                    }
                })
            }

        }

        Button {
            id: testBtn
            text: "Тестовая кнопка"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
        }

        Label {
            id: infoLbl
            text: "Информационное сообщение"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
