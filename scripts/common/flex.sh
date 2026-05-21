#!/bin/bash

# flex.sh - Flex layout with Hyprland window commands

# Get screen dimensions
SCREEN_WIDTH=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].width' 2>/dev/null)
SCREEN_HEIGHT=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].height' 2>/dev/null)

if [ -z "$SCREEN_WIDTH" ] || [ -z "$SCREEN_HEIGHT" ]; then
    echo "Error: Could not get screen dimensions"
    exit 1
fi

echo "Screen resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"

# ============================================================================
# LAYOUT CONFIGURATION - Adjust these values for your desired layout
# ============================================================================

# Calculate thirds
THIRD_W=$((SCREEN_WIDTH / 3))
THIRD_H=$((SCREEN_HEIGHT / 3))
TWO_THIRD_W=$((SCREEN_WIDTH * 2 / 3))

# Window positions and sizes - EDIT THESE TO CHANGE LAYOUT
# Format: position (X Y) and size (W H)

# Top-Left: tty-clock
CLOCK_X=0
CLOCK_Y=0
CLOCK_W=$THIRD_W
CLOCK_H=$THIRD_H
CLOCK_CMD="tty-clock -C 7"

# Middle-Left: yazi (file manager)
YAZI_X=0
YAZI_Y=$THIRD_H
YAZI_W=$THIRD_W
YAZI_H=$THIRD_H
YAZI_CMD="yazi"

# Center: cava (audio visualization)
CAVA_X=$THIRD_W
CAVA_Y=0
CAVA_W=$THIRD_W
CAVA_H=$SCREEN_HEIGHT
CAVA_CMD="cava"

# Bottom-Left: btop (system monitor)
BTOP_X=0
BTOP_Y=$((SCREEN_HEIGHT * 2 / 3))
BTOP_W=$THIRD_W
BTOP_H=$THIRD_H
BTOP_CMD="btop"

# Right: fastfetch (system info)
FETCH_X=$TWO_THIRD_W
FETCH_Y=0
FETCH_W=$THIRD_W
FETCH_H=$SCREEN_HEIGHT
FETCH_CMD="fastfetch"

# ============================================================================
# FUNCTION: Move windows from workspace 1 to workspace 2
# ============================================================================
move_workspace_1_to_2() {
    echo "Moving windows from workspace 1 to workspace 2..."

    WINDOWS=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.workspace.id == 1) | .address' 2>/dev/null)
    COUNT=0

    for WINDOW in $WINDOWS; do
        if [ ! -z "$WINDOW" ]; then
            hyprctl dispatch movetoworkspace 2 address:$WINDOW 2>/dev/null || true
            COUNT=$((COUNT + 1))
        fi
    done

    [ $COUNT -eq 0 ] && echo "  (No windows on workspace 1)" || echo "  ✓ Moved $COUNT window(s)"
}

# ============================================================================
# FUNCTION: Open window with Hyprland commands
# ============================================================================
open_window() {
    local title=$1
    local x=$2
    local y=$3
    local w=$4
    local h=$5
    local cmd=$6

    echo "Opening $title at (${x},${y}) ${w}x${h}"

    hyprctl dispatch exec "[float; move $x $y; size $w $h; title ^$title\$] kitty --title $title sh -c '$cmd; sleep 0.1'" 2>/dev/null || true

    sleep 0.8
}

# ============================================================================
# EXECUTION
# ============================================================================

echo ""
echo "================================"
echo "  FLEX LAYOUT ACTIVATION"
echo "================================"
echo ""

# Move existing windows
move_workspace_1_to_2

sleep 0.5

echo ""
echo "Opening windows with Hyprland positioning..."q
echo ""

# Open windows with Hyprland window rules
open_window "clock" $CLOCK_X $CLOCK_Y $CLOCK_W $CLOCK_H "$CLOCK_CMD"
open_window "yazi" $YAZI_X $YAZI_Y $YAZI_W $YAZI_H "$YAZI_CMD"
open_window "cava" $CAVA_X $CAVA_Y $CAVA_W $CAVA_H "$CAVA_CMD"
open_window "btop" $BTOP_X $BTOP_Y $BTOP_W $BTOP_H "$BTOP_CMD"
open_window "fetch" $FETCH_X $FETCH_Y $FETCH_W $FETCH_H "$FETCH_CMD"

echo ""
echo "✓ Flex Layout Complete!"
echo ""
echo "Layout configuration is at the top of $0"
echo "Modify CLOCK_X, CLOCK_Y, CLOCK_W, CLOCK_H (etc.) to change positions/sizes"
echo ""
