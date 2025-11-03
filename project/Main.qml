import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: mainWindow
    visibility: Window.Maximized
    visible: true
    title: qsTr("Багетная мастерская")

    property bool sellerLogged: false
    property bool masterLogged: false

    StackView {
        id: stack
        anchors.fill: parent
    }

    Component.onCompleted: {
        let loginComponent = Qt.createComponent("pages/LoginPage.qml")
        stack.push(loginComponent)

        let loginItem = stack.currentItem
        loginItem.loginMasterSuccess.connect(function() {
            masterLogged = true
            stack.push("pages/MastersOrdersPage.qml")
            headerLabel.text = "Заказы мастера"
        })
        loginItem.loginSellerSuccess.connect(function() {
            sellerLogged = true
            stack.push("pages/CustomersPage.qml")
            headerLabel.text = "Покупатели"
        })
    }

    header: Label {
        id: headerLabel
        visible: masterLogged || sellerLogged
        horizontalAlignment: Qt.AlignHCenter
        text: ""
        font.pixelSize: 20
        color: "black"
        padding: 10
    }

    footer: TabBar {
        id: tabBar
        visible: masterLogged || sellerLogged
        width: parent.width

        TabButton {
            text: "Покупатели"
            onClicked: {
                stack.push("./pages/CustomersPage.qml")
                headerLabel.text = "Покупатели"
            }
            visible: sellerLogged
        }

        TabButton {
            text: "Заказы"
            onClicked: {
                stack.push("./pages/OrdersPage.qml")
                headerLabel.text = "Заказы"
            }
            visible: sellerLogged
        }

        TabButton {
            text: "Продажа"
            onClicked: {
                stack.push("./pages/SalePage.qml")
                headerLabel.text = "Продажа"
            }
            visible: sellerLogged
        }

        TabButton {
            text: "Продукция"
            onClicked: {
                stack.push("./pages/ProductsPage.qml")
                headerLabel.text = "Продукция мастерской"
            }
            visible: sellerLogged
        }

        TabButton {
            text: "Заказы"
            onClicked: {
                stack.push("./pages/MastersOrdersPage.qml")
                headerLabel.text = "Заказы"
            }
            visible: masterLogged
        }

        TabButton {
            text: "Материалы"
            onClicked: {
                stack.push("./pages/MastersProductsPage.qml")
                headerLabel.text = "Материалы"
            }
            visible: masterLogged
        }
    }

    RoundButton {
        visible: masterLogged || sellerLogged
        text: "X"
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 10
        width: 40
        height: 40
        onClicked: Qt.quit()
    }
}
