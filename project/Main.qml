import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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

        Button {
            id: enterBtn
            text: "Войти"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
        }
        Button {
            id: testBtn
            text: "Тестовая кнопка"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
