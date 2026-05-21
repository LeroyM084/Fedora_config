#!/bin/bash

MONET_DIR="$HOME/Images/wallpapers/monet"
WALLPAPERS=("$MONET_DIR"/*)

# Check if directory has images
if [ ${#WALLPAPERS[@]} -eq 0 ] || [ ! -e "${WALLPAPERS[0]}" ]; then
    echo "No images found in $MONET_DIR"
    exit 1
fi

# Pick a random image
RANDOM_IMAGE="${WALLPAPERS[$RANDOM % ${#WALLPAPERS[@]}]}"

# Create a temporary config with the random image
TEMP_CONFIG=$(mktemp)
trap "rm -f $TEMP_CONFIG" EXIT

# Copy the original config and replace the path
sed "s|path = .*\.png|path = $RANDOM_IMAGE|g" ~/.dotfiles/hypr/hyprlock.conf > "$TEMP_CONFIG"

# Enable Num Lock
if command -v numlockx &> /dev/null; then
    numlockx on
elif command -v setleds &> /dev/null; then
    setleds +num
fi

# Launch hyprlock with the temporary config
hyprlock -c "$TEMP_CONFIG"
