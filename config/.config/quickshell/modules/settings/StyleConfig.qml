import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Hyprland
import "root:/services/"
import "root:/modules/common/"
import "root:/modules/common/widgets/"
import "root:/modules/common/functions/color_utils.js" as ColorUtils
import "root:/modules/common/functions/file_utils.js" as FileUtils

ContentPage {
    baseWidth: lightDarkButtonGroup.implicitWidth
    forceWidth: true

    Process {
        id: konachanWallProc
        property string status: ""
        command: ["bash", "-c", FileUtils.trimFileProtocol(`${Directories.config}/quickshell/scripts/colors/random_konachan_wall.sh`)]
        stdout: SplitParser {
            onRead: data => {
                console.log(`Konachan wall proc output: ${data}`);
                konachanWallProc.status = data.trim();
            }
        }
    }

    ContentSection {
        title: "Colors & Wallpaper"

        // Light/Dark mode preference
        ButtonGroup {
            id: lightDarkButtonGroup
            Layout.fillWidth: true
            LightDarkPreferenceButton {
                dark: false
            }
            LightDarkPreferenceButton {
                dark: true
            }
        }

        // Material palette selection
        ContentSubsection {
            title: "Material palette"
            ConfigSelectionArray {
                currentValue: Config.options.appearance.palette.type
                configOptionName: "appearance.palette.type"
                onSelected: (newValue) => {
                    console.log(`Material palette selected: ${newValue}`);
                    Config.options.appearance.palette.type = newValue;
                    // Apply the new palette immediately by reprocessing current wallpaper
                    Quickshell.execDetached(["bash", "-c", `current_wallpaper=$(swww query | head -1 | sed 's/.*image: //' | tr -d '\\n\\r'); ${Directories.wallpaperSwitchScriptPath} "$current_wallpaper" --type ${newValue}`]);
                    // Force theme reload after a short delay
                    delayedReloadTimer.restart();
                }
                options: [
                    {"value": "auto", "displayName": "Auto"},
                    {"value": "scheme-content", "displayName": "Content"},
                    {"value": "scheme-expressive", "displayName": "Expressive"},
                    {"value": "scheme-fidelity", "displayName": "Fidelity"},
                    {"value": "scheme-fruit-salad", "displayName": "Fruit Salad"},
                    {"value": "scheme-monochrome", "displayName": "Monochrome"},
                    {"value": "scheme-neutral", "displayName": "Neutral"},
                    {"value": "scheme-rainbow", "displayName": "Rainbow"},
                    {"value": "scheme-tonal-spot", "displayName": "Tonal Spot"}
                ]
            }
        }


        // Wallpaper selection
        ContentSubsection {
            title: "Wallpaper"
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                RippleButtonWithIcon {
                    id: rndWallBtn
                    buttonRadius: Appearance.rounding.small
                    materialIcon: "wallpaper"
                    mainText: konachanWallProc.running ? "Be patient..." : "Random: Konachan"
                    onClicked: {
                        console.log(konachanWallProc.command.join(" "))
                        konachanWallProc.running = true;
                    }
                    StyledToolTip {
                        content: "Random SFW Anime wallpaper from Konachan\nImage is saved to ~/Pictures/Wallpapers"
                    }
                }
                RippleButtonWithIcon {
                    materialIcon: "wallpaper"
                    StyledToolTip {
                        content: "Pick wallpaper image on your system"
                    }
                    onClicked: {
                        Quickshell.execDetached(`${Directories.wallpaperSwitchScriptPath}`)
                    }
                    mainContentComponent: Component {
                        RowLayout {
                            spacing: 10
                            StyledText {
                                font.pixelSize: Appearance.font.pixelSize.small
                                text: "Choose file"
                                color: Appearance.colors.colOnSecondaryContainer
                            }
                            RowLayout {
                                spacing: 3
                                KeyboardKey {
                                    key: "Ctrl"
                                }
                                KeyboardKey {
                                    key: "󰖳"
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "+"
                                }
                                KeyboardKey {
                                    key: "T"
                                }
                            }
                        }
                    }
                }
            }
        }

        StyledText {
            Layout.topMargin: 5
            Layout.alignment: Qt.AlignHCenter
            text: "Alternatively use /dark, /light, /img in the launcher"
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }

        Timer {
            id: delayedReloadTimer
            interval: 3000 // 3 seconds delay to allow script to complete
            repeat: false
            onTriggered: {
                MaterialThemeLoader.reapplyTheme();
            }
        }
    
    }

    ContentSection {
        title: "Bar"

        ConfigSelectionArray {
            currentValue: Config.options.bar.cornerStyle
            configOptionName: "bar.cornerStyle"
            onSelected: (newValue) => {
                Config.options.bar.cornerStyle = newValue;
            }
            options: [
                { displayName: "Hug", value: 0 },
                { displayName: "Float", value: 1 },
                { displayName: "Plain rectangle", value: 2 }
            ]
        }
    }

    ContentSection {
        title: "Decorations & Effects"

        ContentSubsection {
            title: "Fake screen rounding"

            ButtonGroup {
                id: fakeScreenRoundingButtonGroup
                property int selectedPolicy: Config.options.appearance.fakeScreenRounding
                spacing: 2
                SelectionGroupButton {
                    property int value: 0
                    leftmost: true
                    buttonText: "No"
                    toggled: (fakeScreenRoundingButtonGroup.selectedPolicy === value)
                    onClicked: {
                        Config.options.appearance.fakeScreenRounding = value;
                    }
                }
                SelectionGroupButton {
                    property int value: 1
                    buttonText: "Yes"
                    toggled: (fakeScreenRoundingButtonGroup.selectedPolicy === value)
                    onClicked: {
                        Config.options.appearance.fakeScreenRounding = value;
                    }
                }
                SelectionGroupButton {
                    property int value: 2
                    rightmost: true
                    buttonText: "When not fullscreen"
                    toggled: (fakeScreenRoundingButtonGroup.selectedPolicy === value)
                    onClicked: {
                        Config.options.appearance.fakeScreenRounding = value;
                    }
                }
            }
        }

        ContentSubsection {
            title: "Shell windows"

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    text: "Title bar"
                    checked: Config.options.windows.showTitlebar
                    onCheckedChanged: {
                        Config.options.windows.showTitlebar = checked;
                    }
                }
                ConfigSwitch {
                    text: "Center title"
                    checked: Config.options.windows.centerTitle
                    onCheckedChanged: {
                        Config.options.windows.centerTitle = checked;
                    }
                }
            }
        }
    }
}