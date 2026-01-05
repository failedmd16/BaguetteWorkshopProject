import QtQuick
import QtQuick.Controls
import Database

ApplicationWindow {
    id: mainWindow
    visibility: Window.Maximized
    visible: true
    title: qsTr("Багетная мастерская")

    property bool sellerLogged: false
    property bool masterLogged: false
    property bool adminLogged: false

    palette {
        button: "#3498db"
        buttonText: "white"
        window: "#f8f9fa"
    }

    StackView {
        id: stack
        anchors.fill: parent

        // Новая страница въезжает справа
        pushEnter: Transition {
            ParallelAnimation {
                PropertyAnimation { property: "x"; from: stack.width; to: 0; duration: 300; easing.type: Easing.OutQuad }
                PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 300 }
            }
        }
        // Старая страница слегка сдвигается влево и затемняется
        pushExit: Transition {
            ParallelAnimation {
                PropertyAnimation { property: "x"; from: 0; to: -stack.width * 0.3; duration: 300; easing.type: Easing.OutQuad }
                PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 300 }
            }
        }
        // Возврат старой страницы
        popEnter: Transition {
            ParallelAnimation {
                PropertyAnimation { property: "x"; from: -stack.width * 0.3; to: 0; duration: 300; easing.type: Easing.OutQuad }
                PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 300 }
            }
        }
        // Уход текущей страницы вправо
        popExit: Transition {
            ParallelAnimation {
                PropertyAnimation { property: "x"; from: 0; to: stack.width; duration: 300; easing.type: Easing.OutQuad }
                PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 300 }
            }
        }
    }


    Component.onCompleted: {
        if (DatabaseManager.hasAdminAccount())
            loadLoginPage()
        else
            loadFirstRunPage()
    }

    function loadLoginPage() {
       let loginComponent = Qt.createComponent("pages/LoginPage.qml")
       if (loginComponent.status === Component.Ready) {
           stack.replace(loginComponent)
           let loginItem = stack.currentItem
           connectLoginSignals(loginItem)
       } else {
           console.error("Error loading LoginPage:", loginComponent.errorString())
       }
   }

   function loadFirstRunPage() {
       let firstRunComponent = Qt.createComponent("pages/CreateFirstAdminPage.qml")
       if (firstRunComponent.status === Component.Ready) {
           stack.replace(firstRunComponent)
           let firstRunItem = stack.currentItem

           firstRunItem.adminCreated.connect(function() {
               loadLoginPage()
           })
       } else {
            console.error("Error loading FirstRunPage:", firstRunComponent.errorString())
       }
   }

   function connectLoginSignals(loginItem) {
       loginItem.loginMasterSuccess.connect(function() {
           masterLogged = true
           stack.push("pages/MastersOrdersPage.qml")
           headerLabel.text = "Заказы мастера"
       })

       loginItem.loginSellerSuccess.connect(function() {
           sellerLogged = true
           stack.push("pages/ClientsPage.qml")
           headerLabel.text = "Покупатели"
       })

       loginItem.loginAdminSuccess.connect(function() {
           adminLogged = true
           stack.push("pages/LogsPage.qml")
           headerLabel.text = "Панель администратора"
       })
   }

    header: Rectangle {
        visible: masterLogged || sellerLogged
        height: 60
        color: "#3498db"

        Label {
            id: headerLabel
            anchors.centerIn: parent
            text: ""
            font.pixelSize: 20
            font.bold: true
            color: "white"
            padding: 10
        }
    }

    footer: Rectangle {
        visible: masterLogged || sellerLogged || adminLogged
        height: 70
        color: "#2c3e50"

        Row {
            id: tabRow
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // Кнопки для продавца
            Button {
                visible: sellerLogged
                width: (tabRow.width - (3 * tabRow.spacing)) / 3
                height: parent.height

                background: Rectangle {
                    color: parent.down ? "#3498db" : "#34495e"
                    radius: 10
                }

                contentItem: Text {
                    text: "👥 Покупатели"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    stack.push("pages/ClientsPage.qml")
                    headerLabel.text = "Покупатели"
                }
            }

            Button {
                visible: sellerLogged
                width: (tabRow.width - (3 * tabRow.spacing)) / 3
                height: parent.height

                background: Rectangle {
                    color: parent.down ? "#3498db" : "#34495e"
                    radius: 10
                }

                contentItem: Text {
                    text: "📦 Заказы"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    stack.push("pages/OrdersPage.qml")
                    headerLabel.text = "Заказы"
                }
            }

            Button {
                visible: sellerLogged
                width: (tabRow.width - (3 * tabRow.spacing)) / 3
                height: parent.height

                background: Rectangle {
                    color: parent.down ? "#3498db" : "#34495e"
                    radius: 10
                }

                contentItem: Text {
                    text: "💰 Продажа"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    stack.push("pages/SalePage.qml")
                    headerLabel.text = "Продажа"
                }
            }

            // Кнопки для мастера
            Button {
                visible: masterLogged
                width: (tabRow.width - tabRow.spacing) / 2
                height: parent.height

                background: Rectangle {
                    color: parent.down ? "#3498db" : "#34495e"
                    radius: 10
                }

                contentItem: Text {
                    text: "🔧 Заказы"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    stack.push("pages/MastersOrdersPage.qml")
                    headerLabel.text = "Заказы"
                }
            }

            Button {
                visible: masterLogged
                width: (tabRow.width - tabRow.spacing) / 2
                height: parent.height

                background: Rectangle {
                    color: parent.down ? "#3498db" : "#34495e"
                    radius: 10
                }

                contentItem: Text {
                    text: "📐 Материалы"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    stack.push("pages/MastersProductsPage.qml")
                    headerLabel.text = "Материалы"
                }
            }

            // Кнопки для администратора
            Button {
                visible: adminLogged
                width: (tabRow.width - tabRow.spacing) / 3
                height: parent.height

                background: Rectangle {
                    color: parent.down ? "#3498db" : "#34495e"
                    radius: 10
                }

                contentItem: Text {
                    text: "📔 Логирование"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    stack.push("pages/LogsPage.qml")
                    headerLabel.text = "Журнал событий"
                }
            }

            Button {
                visible: adminLogged
                width: (tabRow.width - tabRow.spacing) / 3
                height: parent.height

                background: Rectangle {
                    color: parent.down ? "#3498db" : "#34495e"
                    radius: 10
                }

                contentItem: Text {
                    text: "🔐 Управление аккаунтами"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    stack.push("pages/AccountManagementPage.qml")
                    headerLabel.text = "Управление аккаунтами"
                }
            }

            Button {
                visible: adminLogged
                width: (tabRow.width - tabRow.spacing) / 3
                height: parent.height

                background: Rectangle {
                    color: parent.down ? "#3498db" : "#34495e"
                    radius: 10
                }

                contentItem: Text {
                    text: "📊 Управление данными"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: {
                    stack.push("pages/DataManagementPage.qml")
                    headerLabel.text = "Управление данными"
                }
            }
        }
    }

    RoundButton {
        visible: masterLogged || sellerLogged || adminLogged
        text: "Выход"
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 10
        width: 120
        height: 50

        background: Rectangle {
            color: parent.down ? "#c0392b" : "#e74c3c"
            radius: 8
        }

        contentItem: Text {
            text: parent.text
            color: "white"
            font.pixelSize: 14
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        ToolTip.delay: 1000
        ToolTip.timeout: 5000
        ToolTip.visible: hovered
        ToolTip.text: qsTr("Завершить работу приложения")

        onClicked: Qt.quit()
    }
}
