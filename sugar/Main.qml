// Modification pour support MP4 - Thème Dark Purple Cat
import QtQuick 2.11
import QtQuick.Layouts 1.11
import QtQuick.Controls 2.4
import QtGraphicalEffects 1.0
import QtMultimedia 5.11
import "Components"

Pane {
    id: root

    height: config.ScreenHeight || Screen.height
    width: config.ScreenWidth || Screen.width

    LayoutMirroring.enabled: config.ForceRightToLeft == "true" ? true : Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    padding: config.ScreenPadding
    palette.button: "transparent"
    palette.highlight: config.AccentColor
    palette.text: config.MainColor
    palette.buttonText: config.MainColor
    palette.window: config.BackgroundColor

    font.family: config.Font
    font.pointSize: config.FontSize !== "" ? config.FontSize : parseInt(height / 80)
    focus: true

    Item {
        id: sizeHelper
        anchors.fill: parent

        // --- LECTEUR VIDÉO (MP4) ---
        MediaPlayer {
            id: player
            source: config.background || config.Background
            autoPlay: true
            loops: MediaPlayer.Infinite
            muted: true // Important pour SDDM
        }

        VideoOutput {
            id: backgroundImage
            anchors.fill: parent
            source: player
            fillMode: VideoOutput.PreserveAspectCrop
            z: 0
            
            // Filtre assombrissant pour que le texte reste lisible
            Rectangle {
                id: tintLayer
                anchors.fill: parent
                color: "black"
                opacity: config.DimBackgroundImage
                z: 1
            }
        }

        // --- FORMULAIRE DE CONNEXION ---
        Rectangle {
            id: formBackground
            anchors.fill: form
            color: root.palette.window
            visible: config.HaveFormBackground == "true"
            opacity: config.PartialBlur == "true" ? 0.4 : 1 // Un peu plus opaque pour le dark theme
            radius: config.RoundCorners || 0
            z: 2
        }

        LoginForm {
            id: form
            height: virtualKeyboard.state == "visible" ? parent.height - virtualKeyboard.implicitHeight : parent.height
            width: parent.width / 2.5
            anchors.horizontalCenter: config.FormPosition == "center" ? parent.horizontalCenter : undefined
            anchors.left: config.FormPosition == "left" ? parent.left : undefined
            anchors.right: config.FormPosition == "right" ? parent.right : undefined
            virtualKeyboardActive: virtualKeyboard.state == "visible"
            z: 3
        }

        // --- CLAVIER VIRTUEL ---
        Loader {
            id: virtualKeyboard
            source: "Components/VirtualKeyboard.qml"
            state: "hidden"
            width: parent.width
            z: 4
            // ... (logique du clavier conservée)
            function switchState() { state = state == "hidden" ? "visible" : "hidden" }
            states: [
                State {
                    name: "visible"
                    PropertyChanges { target: form; systemButtonVisibility: false; clockVisibility: false }
                    PropertyChanges { target: virtualKeyboard; y: root.height - virtualKeyboard.height; opacity: 1 }
                },
                State {
                    name: "hidden"
                    PropertyChanges { target: virtualKeyboard; y: root.height - root.height/4; opacity: 0 }
                }
            ]
        }

        // --- EFFET DE FLOU (BLUR) ---
        // Note: Le flou sur de la vidéo en temps réel est gourmand. 
        // Si ça rame, passe "PartialBlur" à "false" dans ton theme.conf
        ShaderEffectSource {
            id: blurMask
            sourceItem: backgroundImage
            width: form.width
            height: parent.height
            anchors.centerIn: form
            sourceRect: Qt.rect(form.x, 0, form.width, parent.height)
            visible: config.PartialBlur == "true"
            z: 1
        }

        GaussianBlur {
            id: blur
            anchors.fill: blurMask
            source: blurMask
            radius: config.BlurRadius
            samples: config.BlurRadius * 2 + 1
            visible: config.PartialBlur == "true"
            z: 1
        }
    }
}