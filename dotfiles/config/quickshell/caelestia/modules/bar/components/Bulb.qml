pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

Item {
    id: root

    property bool on: false

    readonly property int cardWidth: 250
    readonly property int cardPadding: Tokens.padding.large

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    function applyStatus(out) {
        try {
            const s = JSON.parse(out);
            root.on = s.on === true;
            return s;
        } catch (e) {
            return null;
        }
    }

    function openPopup(): void {
        const win = QsWindow.window;
        if (!win)
            return;

        card.refresh();

        const scene = root.mapToItem(null, root.implicitWidth / 2, root.implicitHeight / 2);
        const gap = 8;
        const scrH = win.screen?.height ?? 1080;

        let y = scene.y - card.implicitHeight / 2;
        y = Math.max(gap, Math.min(y, scrH - card.implicitHeight - gap));

        popup.anchor.window = win;
        popup.anchor.rect.x = Math.round(win.width + gap);
        popup.anchor.rect.y = Math.round(y);
        popup.visible = true;
    }

    Process {
        id: statusProc

        command: ["/home/andrei/.local/bin/bulbctl", "status"]
        stdout: StdioCollector {
            onStreamFinished: root.applyStatus(text.trim())
        }
    }

    Process {
        id: toggleProc

        command: ["/home/andrei/.local/bin/bulbctl", "toggle"]
        stdout: StdioCollector {
            onStreamFinished: root.applyStatus(text.trim())
        }
    }

    StateLayer {
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: e => {
            if (e.button === Qt.RightButton) {
                toggleProc.running = true;
                return;
            }
            if (popup.visible)
                popup.visible = false;
            else
                root.openPopup();
        }
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: root.on ? "lightbulb" : "lightbulb_outline"
        color: root.on ? Colours.palette.m3tertiary : Colours.palette.m3outline
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
    }

    Timer {
        interval: 30000
        running: !popup.visible
        repeat: true
        onTriggered: statusProc.running = true
    }

    Component.onCompleted: statusProc.running = true

    PopupWindow {
        id: popup

        readonly property int totalHeight: card.implicitHeight + root.cardPadding * 2

        color: "transparent"
        implicitWidth: card.implicitWidth + root.cardPadding * 2
        implicitHeight: totalHeight
        visible: false

        StyledRect {
            id: card

            property bool bulbOn: root.on
            property int brightness: 50
            property int warmth: 50
            property bool reachable: true

            readonly property int contentWidth: root.cardWidth

            function run(args, done) {
                proc.command = ["/home/andrei/.local/bin/bulbctl"].concat(args);
                proc.onDone = done ?? null;
                proc.running = true;
            }

            function refresh() {
                run(["status"], out => {
                    const s = root.applyStatus(out);
                    if (!s) {
                        reachable = false;
                        return;
                    }
                    reachable = true;
                    bulbOn = s.on === true;
                    if (s.brightness !== null)
                        brightness = s.brightness;

                    if (s.warmth !== null)
                        warmth = s.warmth;
                });
            }

            anchors.fill: parent
            implicitWidth: contentWidth + root.cardPadding * 2
            implicitHeight: headerRow.implicitHeight + brightRow.implicitHeight + warmRow.implicitHeight + Tokens.spacing.medium * 2 + root.cardPadding * 2

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Component.onCompleted: refresh()

            Process {
                id: proc

                property var onDone: null

                stdout: StdioCollector {
                    onStreamFinished: {
                        if (proc.onDone)
                            proc.onDone(text.trim());
                        proc.onDone = null;
                    }
                }
            }

            Column {
                id: cardColumn

                anchors.centerIn: parent
                width: parent.implicitWidth - root.cardPadding * 2
                spacing: Tokens.spacing.medium

                // Header: icon + title + power switch
                Row {
                    id: headerRow

                    width: parent.width
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        id: headerIcon

                        anchors.verticalCenter: parent.verticalCenter

                        text: "lightbulb"
                        color: card.bulbOn ? Colours.palette.m3tertiary : Colours.palette.m3outline
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - parent.spacing * 2 - headerIcon.implicitWidth - powerSwitch.implicitWidth

                        text: card.reachable ? qsTr("Bec") : qsTr("Bec (neconectat)")
                        color: card.reachable ? Colours.palette.m3onSurface : Colours.palette.m3error
                    }

                    StyledSwitch {
                        id: powerSwitch

                        anchors.verticalCenter: parent.verticalCenter

                        checked: card.bulbOn
                        onToggled: {
                            card.bulbOn = checked;
                            card.run(["toggle"], () => {
                                card.refresh();
                                statusProc.running = true;
                            });
                        }
                    }
                }

                // Brightness
                Row {
                    id: brightRow

                    width: parent.width
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        id: brightnessIcon

                        anchors.verticalCenter: parent.verticalCenter

                        text: "brightness_6"
                        color: card.bulbOn ? Colours.palette.m3primary : Colours.palette.m3outline
                    }

                    StyledSlider {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - parent.spacing - brightnessIcon.implicitWidth

                        enabled: card.bulbOn
                        pos: card.brightness / 100
                        interactionOnMove: false
                        onInteraction: v => {
                            const val = Math.round(v * 100);
                            card.brightness = val;
                            card.run(["brightness", val], () => card.refresh());
                        }
                    }
                }

                // Warmth
                Row {
                    id: warmRow

                    width: parent.width
                    spacing: Tokens.spacing.medium

                    MaterialIcon {
                        id: warmthIcon

                        anchors.verticalCenter: parent.verticalCenter

                        text: "device_thermostat"
                        color: card.bulbOn ? Colours.palette.m3tertiary : Colours.palette.m3outline
                    }

                    StyledSlider {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - parent.spacing - warmthIcon.implicitWidth

                        enabled: card.bulbOn
                        fgColour: Colours.palette.m3tertiary
                        pos: card.warmth / 100
                        interactionOnMove: false
                        onInteraction: v => {
                            const val = Math.round(v * 100);
                            card.warmth = val;
                            card.run(["warmth", val], () => card.refresh());
                        }
                    }
                }
            }
        }
    }
}
