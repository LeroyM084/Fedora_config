#!/bin/bash
# Tuer toute instance existante pour repartir sur une surface propre
pkill -x mpvpaper
# Attendre que hyprland réponde
while ! hyprctl monitors &>/dev/null; do
    sleep 0.1
done
# Attendre un monitor spécifique
sleep 0.2
mpvpaper -o "no-audio --loop --video-unscaled=no --panscan=1.0" '*' "$HOME/Images/wallpapers/frog2.mp4"
