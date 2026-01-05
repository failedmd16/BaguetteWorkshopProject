import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.LocalStorage
import Database

Page {
    id: root

    property bool isLoading: false

    component CustomTextField: TextField {
        color: "black"
        font.pixelSize: 14
        Layout.fillWidth: true
        enabled: !root.isLoading
        background: Rectangle {
            color: parent.enabled ? "white" : "#f0f0f0"
            border.color: parent.activeFocus ? "#3498db" : "#dce0e3"
            border.width: 1
            radius: 4
        }
    }

    Connections {
        target: DatabaseManager

        function onUserOperationResult(success, message) {
            root.isLoading = false
            infoLbl.text = message
            infoLbl.color = success ? "green" : "red"

            if (success) {
                if (bar.currentIndex === 0) {
                    regLogin.clear()
                    regPass.clear()
                    regConfirm.clear()
                } else if (bar.currentIndex === 1) {
                    editLogin.clear()
                    editPass.clear()
                    editConfirm.clear()
                }
            }
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        running: root.isLoading
        z: 10
    }

    MouseArea {
        anchors.fill: parent
        visible: root.isLoading
        hoverEnabled: true
        onClicked: {}
        z: 9
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: 300
        spacing: 15

        opacity: root.isLoading ? 0.6 : 1.0
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        Label {
            text: {
                if (bar.currentIndex === 0)
                    return "Регистрация"
                if (bar.currentIndex === 1)
                    return "Смена пароля"
            }
            font.pixelSize: 24
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        TabBar {
            id: bar
            Layout.fillWidth: true
            implicitWidth: 300
            enabled: !root.isLoading

            background: Rectangle {
                color: "transparent"
            }

            component MyTabButton: TabButton {
                id: tabBtn
                width: (bar.availableWidth / 2)
                implicitWidth: 100
                contentItem: Text {
                    text: tabBtn.text
                    font: tabBtn.font
                    color: {
                        return tabBtn.checked ? "#3498db" : "#7f8c8d"
                    }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
                background: Rectangle {
                    color: "transparent"
                    Rectangle {
                        width: parent.width
                        height: 2
                        anchors.bottom: parent.bottom
                        color: {
                            if (!tabBtn.checked)
                                return "transparent"

                            return "#3498db"
                        }
                    }
                }
            }

            MyTabButton {
                text: "Создать"
                font.pixelSize: 13
            }
            MyTabButton {
                text: "Изменить"
                font.pixelSize: 13
            }

            onCurrentIndexChanged: {
                infoLbl.text = "Введите данные"
                infoLbl.color = "black"

                regLogin.text = ""
                regPass.text = ""
                regConfirm.text = ""
                editLogin.text = ""
                editPass.text = ""
                editConfirm.text = ""
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#dce0e3"
            Layout.topMargin: -10
            z: -1
        }

        StackLayout {
            currentIndex: bar.currentIndex
            Layout.fillWidth: true

            // Вкладка создания аккаунта
            ColumnLayout {
                spacing: 15

                CustomTextField {
                    id: regLogin
                    placeholderText: "Логин нового пользователя"
                }

                CustomTextField {
                    id: regPass
                    placeholderText: "Пароль"
                    echoMode: TextInput.Password
                }

                CustomTextField {
                    id: regConfirm
                    placeholderText: "Повторите пароль"
                    echoMode: TextInput.Password
                    background: Rectangle {
                        border.color: (regConfirm.text !== regPass.text && regConfirm.text.length > 0) ?
                                          "red" :
                                          (regConfirm.activeFocus ? "#3498db" : "#dce0e3")
                        border.width: 1
                        radius: 4
                    }
                }

                ComboBox {
                    id: rolesComboBox
                    Layout.fillWidth: true
                    enabled: !root.isLoading
                    model: ["Продавец", "Мастер производства", "Администратор"]
                    font.pixelSize: 14

                    contentItem: Text {
                        text: rolesComboBox.displayText
                        color: "black"
                        font: rolesComboBox.font
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 10
                    }
                    background: Rectangle {
                        border.color: rolesComboBox.activeFocus ? "#3498db" : "#dce0e3"
                        radius: 4
                        border.width: 1
                    }
                }

                Button {
                    text: "Зарегистрировать"
                    Layout.fillWidth: true
                    font.pixelSize: 16
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

                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Зарегистрировать новый аккаунт сотрудника")

                    onClicked: {
                        if (regLogin.text.length < 3 || regPass.text.length < 6) {
                            infoLbl.text = "Логин (минимум 3 символа) или пароль (минимум 6 символов) слишком короткие"
                            infoLbl.color = "red"
                            return
                        }
                        if (regPass.text !== regConfirm.text) {
                            infoLbl.text = "Пароли не совпадают"
                            infoLbl.color = "red"
                            return
                        }

                        root.isLoading = true
                        infoLbl.text = "Обработка..."
                        infoLbl.color = "gray"
                        DatabaseManager.registerUserAsync(regLogin.text, regPass.text, rolesComboBox.currentText)
                    }
                }
            }

            // Вкладка изменения пароля
            ColumnLayout {
                spacing: 15

                CustomTextField {
                    id: editLogin
                    placeholderText: "Логин пользователя"
                }

                CustomTextField {
                    id: editPass
                    placeholderText: "Новый пароль"
                    echoMode: TextInput.Password
                }

                CustomTextField {
                    id: editConfirm
                    placeholderText: "Повторите новый пароль"
                    echoMode: TextInput.Password
                    background: Rectangle {
                        border.color: (editConfirm.text !== editPass.text && editConfirm.text.length > 0) ?
                                          "red" :
                                          (editConfirm.activeFocus ? "#3498db" : "#dce0e3")
                        border.width: 1
                        radius: 4
                    }
                }

                Button {
                    text: "Сменить пароль"
                    Layout.fillWidth: true
                    font.pixelSize: 16
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

                    ToolTip.delay: 1000
                    ToolTip.timeout: 5000
                    ToolTip.visible: hovered
                    ToolTip.text: qsTr("Сменить пароль для аккаунта")

                    onClicked: {
                        if (editLogin.text === "") {
                            infoLbl.text = "Введите логин пользователя"
                            infoLbl.color = "red"
                            return
                        }
                        if (editPass.text.length < 6) {
                            infoLbl.text = "Пароль слишком короткий"
                            infoLbl.color = "red"
                            return
                        }
                        if (editPass.text !== editConfirm.text) {
                            infoLbl.text = "Пароли не совпадают"
                            infoLbl.color = "red"
                            return
                        }

                        root.isLoading = true
                        infoLbl.text = "Обработка..."
                        infoLbl.color = "gray"
                        DatabaseManager.updateUserPasswordAsync(editLogin.text, editPass.text)
                    }
                }
            }
        }

        Label {
            id: infoLbl
            text: "Выберите действие"
            font.pixelSize: 16
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 300
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 5
        }
    }
}
