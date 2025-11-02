import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.LocalStorage

Page {
    signal loginSellerSuccess()
    signal loginMasterSuccess()

    property color blackColor: "#000000"
    property color whiteColor: "#FFFFFF"
    property color grayColor: "#808080"
    property color lightGrayColor: "#D3D3D3"
    property color darkGrayColor: "#404040"

    property string currentUser: ""
    property string currentRole: ""
    property int currentUserId: -1

    Component.onCompleted: {
        initializeDatabase();
    }

    function initializeDatabase() {
        var db = LocalStorage.openDatabaseSync("BagetWorkshopDB", "1.0", "База данных багетной мастерской", 1000000);

        db.transaction(function(tx) {
            // Таблица пользователей
            tx.executeSql(
                'CREATE TABLE IF NOT EXISTS users (' +
                'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                'login TEXT UNIQUE NOT NULL, ' +
                'password TEXT NOT NULL, ' +
                'role TEXT NOT NULL CHECK(role IN ("Продавец", "Мастер производства")), ' +
                'created_at DATETIME DEFAULT CURRENT_TIMESTAMP)'
            );

            // Таблица покупателей
            tx.executeSql(
                'CREATE TABLE IF NOT EXISTS customers (' +
                'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                'surname TEXT NOT NULL, ' +
                'name TEXT NOT NULL, ' +
                'phone TEXT, ' +
                'email TEXT, ' +
                'address TEXT, ' +
                'created_at DATETIME DEFAULT CURRENT_TIMESTAMP)'
            );

            // Таблица материалов для рамок
            tx.executeSql(
                'CREATE TABLE IF NOT EXISTS materials (' +
                'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                'name TEXT NOT NULL, ' +
                'type TEXT NOT NULL, ' +
                'price_per_unit REAL NOT NULL, ' +
                'quantity INTEGER NOT NULL, ' +
                'unit TEXT NOT NULL, ' +
                'created_at DATETIME DEFAULT CURRENT_TIMESTAMP)'
            );

            // Таблица готовых наборов вышивки
            tx.executeSql(
                'CREATE TABLE IF NOT EXISTS embroidery_kits (' +
                'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                'name TEXT NOT NULL, ' +
                'description TEXT, ' +
                'price REAL NOT NULL, ' +
                'quantity INTEGER NOT NULL, ' +
                'created_at DATETIME DEFAULT CURRENT_TIMESTAMP)'
            );

            // Таблица расходной фурнитуры
            tx.executeSql(
                'CREATE TABLE IF NOT EXISTS consumables (' +
                'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                'name TEXT NOT NULL, ' +
                'category TEXT NOT NULL, ' +
                'price REAL NOT NULL, ' +
                'quantity INTEGER NOT NULL, ' +
                'created_at DATETIME DEFAULT CURRENT_TIMESTAMP)'
            );

            // Таблица заказов на изготовление
            tx.executeSql(
                'CREATE TABLE IF NOT EXISTS production_orders (' +
                'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
                'customer_id INTEGER NOT NULL, ' +
                'description TEXT NOT NULL, ' +
                'material_id INTEGER NOT NULL, ' +
                'status TEXT NOT NULL DEFAULT "Новый" CHECK(status IN ("Новый", "В процессе", "Завершён", "Доставлен")), ' +
                'created_by INTEGER NOT NULL, ' +
                'assigned_master INTEGER, ' +
                'created_at DATETIME DEFAULT CURRENT_TIMESTAMP, ' +
                'completed_at DATETIME)'
            );

            // Тестовые пользователи для проверки
            var result = tx.executeSql('SELECT COUNT(*) as count FROM users');
            if (result.rows.item(0).count === 0) {
                tx.executeSql('INSERT INTO users (login, password, role) VALUES (?, ?, ?)', ['seller1', 'password123', 'Продавец']);
                tx.executeSql('INSERT INTO users (login, password, role) VALUES (?, ?, ?)', ['master1', 'password123', 'Мастер производства']);
            }
        });
    }

    function authenticateUser(login, password, callback) {
        var db = LocalStorage.openDatabaseSync("BagetWorkshopDB", "1.0", "База данных багетной мастерской", 1000000);
        db.transaction(function(tx) {
            var result = tx.executeSql('SELECT * FROM users WHERE login = ? AND password = ?', [login, password]);
            if (result.rows.length === 1) {
                var user = result.rows.item(0);
                callback(true, user);
            } else {
                callback(false, null);
            }
        });
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

                authenticateUser(user_name, user_password, function(success, user) {
                    if (success) {
                        infoLbl.text = "Вход успешен"
                        infoLbl.color = "green"

                        if (user.role === "Продавец") {
                            loginSellerSuccess()
                        } else if (user.role === "Мастер производства") {
                            loginMasterSuccess()
                        }
                    } else {
                        infoLbl.text = "Неверный логин или пароль"
                        infoLbl.color = "red"
                    }
                });
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
