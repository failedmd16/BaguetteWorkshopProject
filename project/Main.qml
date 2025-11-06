import QtQuick
import QtQuick.Controls

ApplicationWindow {
    id: mainWindow
    visibility: Window.Maximized
    visible: true
    title: qsTr("Багетная мастерская")

    property bool sellerLogged: false
    property bool masterLogged: false

    // Стилизация приложения
    palette {
        button: "#3498db"
        buttonText: "white"
        window: "#f8f9fa"
    }

    StackView {
        id: stack
        anchors.fill: parent

        pushEnter: Transition {
            PropertyAnimation {
                property: "opacity";
                from: 0;
                to: 1;
                duration: 200
            }
        }
        pushExit: Transition {
            PropertyAnimation {
                property: "opacity";
                from: 1;
                to: 0;
                duration: 200
            }
        }
        popEnter: Transition {
            PropertyAnimation {
                property: "opacity";
                from: 0;
                to: 1;
                duration: 200
            }
        }
        popExit: Transition {
            PropertyAnimation {
                property: "opacity";
                from: 1;
                to: 0;
                duration: 200
            }
        }
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
        visible: masterLogged || sellerLogged
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
                    border.color: "#3498db"
                    border.width: parent.down ? 2 : 1
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
                    stack.push("pages/CustomersPage.qml")
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
                    border.color: "#3498db"
                    border.width: parent.down ? 2 : 1
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
                    border.color: "#3498db"
                    border.width: parent.down ? 2 : 1
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
                    border.color: "#3498db"
                    border.width: parent.down ? 2 : 1
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
                    border.color: "#3498db"
                    border.width: parent.down ? 2 : 1
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
        }
    }

    RoundButton {
        visible: masterLogged || sellerLogged
        text: "🚪 Выход"
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

        onClicked: Qt.quit()
    }
}
