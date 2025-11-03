import QtQuick
import QtQuick.Controls

ApplicationWindow {
    visibility: Window.Maximized
    visible: true
    title: qsTr("Багетная мастерская")

    // Проверка, кто именно зашел для отображения нужных страниц
    property bool sellerLogged: false
    property bool masterLogged: false

    // Создание окна авторизации, переход к этому окну, далее, в зависимости от роли входа, переброс на нужную страницу
    function loadLoginPage() {
        let loginComponent = Qt.createComponent("pages/LoginPage.qml")
        stack.push(loginComponent) // Сначала загружается страница авторизации

        let loginItem = stack.currentItem
        loginItem.loginMasterSuccess.connect(function() {
            masterLogged = true
            stack.push("pages/MastersOrdersPage.qml")
        })
        loginItem.loginSellerSuccess.connect(function() {
            sellerLogged = true
            stack.push("pages/SalePage.qml")
        })
    }

    StackView {
        id: stack
        anchors.fill: parent
    }

    Component.onCompleted: loadLoginPage()

    header: Label {
        id: headerLabel
        visible: masterLogged || sellerLogged
        horizontalAlignment: Qt.AlignHCenter
        text: {
            // Реализовать так, чтобы текст первой страницы верно отображался сразу при входе
        }

        font.pixelSize: 24
        color: "black"
    }

    footer: TabBar {
        id: tabBar
        visible: masterLogged || sellerLogged
        width: parent.width

        TabButton {
            text: "Покупатели"
            font.bold: true
            onClicked: {
                stack.push("./pages/ClientsPage.qml")
                headerLabel.text = "Покупатели"
            }
            visible: sellerLogged
        }

        TabButton {
            text: "Заказы"
            font.bold: true
            onClicked: {
                stack.push("./pages/OrdersPage.qml")
                headerLabel.text = "Заказы"
            }
            visible: sellerLogged
        }

        TabButton {
            text: "Продажа"
            font.bold: true
            onClicked: {
                stack.push("./pages/SalePage.qml")
                headerLabel.text = "Продажа"
            }
            visible: sellerLogged
        }

        TabButton {
            text: "Продукция мастерской"
            font.bold: true
            onClicked: {
                stack.push("./pages/ProductsPage.qml")
                headerLabel.text = "Продукция мастерской"
            }
            visible: sellerLogged
        }

        TabButton {
            text: "Заказы"
            font.bold: true
            onClicked: {
                stack.push("./pages/MastersOrdersPage.qml")
                headerLabel.text = "Заказы"
            }
            visible: masterLogged
        }
        TabButton {
            text: "Материалы"
            font.bold: true
            onClicked: {
                stack.push("./pages/MastersProductsPage.qml")
                headerLabel.text = "Материалы"
            }
            visible: masterLogged
        }
    }

    RoundButton {
        visible: masterLogged || sellerLogged
        text: "\u2715"
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        ToolTip.delay: 250
        ToolTip.visible: hovered
        ToolTip.text: qsTr("Завершить работу")
        onClicked: {
            masterLogged = false
            sellerLogged = false
            stack.clear()
            loadLoginPage()
        }
    }
}
