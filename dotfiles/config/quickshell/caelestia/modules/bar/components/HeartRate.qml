import QtQuick
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root
    property string bpm: "--"

    readonly property bool live: root.bpm.length > 0 && root.bpm !== "--"

    implicitWidth: row.implicitWidth + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    Process {
        id: hrProc
        command: ["cat", "/home/andrei/.cache/waybar_hr"]
        stdout: StdioCollector {
            onStreamFinished: {
                const val = text.trim();
                root.bpm = val.length > 0 ? val : "--";
            }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall
        MaterialIcon {
            id: icon
            text: "favorite"
            color: Colours.palette.m3error
            fill: root.live ? 1 : 0
            fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
        }
        StyledText {
            anchors.verticalCenter: icon.verticalCenter
            animate: true
            text: root.live ? root.bpm : "--"
            color: root.live ? Colours.palette.m3onSurface : Colours.palette.m3outline
            font: Tokens.font.body.builders.small.scale(0.9).build()
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: hrProc.running = true
    }
    Component.onCompleted: hrProc.running = true
}
