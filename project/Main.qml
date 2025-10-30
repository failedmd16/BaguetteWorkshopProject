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
            text: "Вход в систему"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignHCenter
        }

        Button {
            text: "Войти"
            font.pixelSize: 16
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
