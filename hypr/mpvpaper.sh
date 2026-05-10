#!/bin/bash
# Attendre que hyprland réponde
while ! hyprctl monitors &>/dev/null; do
    sleep 0.5
done
# Attendre un monitor spécifique
sleep 1
mpvpaper -o "no-audio --loop --video-unscaled=no --panscan=1.0" '*' "~/.dotfiles/wallpapers/frog.mp4"
