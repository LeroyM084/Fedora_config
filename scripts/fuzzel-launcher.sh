#!/usr/bin/env bash
# ~/.config/dotfiles/scripts/fuzzel-launcher.sh

PROFILE=$(find ~/.mozilla/firefox -name "places.sqlite" | head -1)
TMPDB="/tmp/places_copy.sqlite"
cp "$PROFILE" "$TMPDB"

# Apps normales
APPS=$(ls /usr/share/applications ~/.local/share/applications 2>/dev/null \
  | grep '\.desktop$' \
  | sed 's/\.desktop$//' \
  | sort -u \
  | awk '{print "  " $0}')

# Favoris Firefox
BOOKMARKS=$(sqlite3 "$TMPDB" \
  "SELECT title, url FROM moz_bookmarks
   JOIN moz_places ON moz_bookmarks.fk = moz_places.id
   WHERE moz_bookmarks.type = 1 AND moz_places.url NOT LIKE 'place:%'
   ORDER BY moz_bookmarks.dateAdded DESC;" \
  | awk -F'|' '{printf "  %-55s %s\n", $1, $2}')

CHOICE=$(printf "%s\n%s" "$APPS" "$BOOKMARKS" | fuzzel --dmenu)

[[ -z "$CHOICE" ]] && exit 0

# Si URL → Firefox
if echo "$CHOICE" | grep -qE 'https?://'; then
  URL=$(echo "$CHOICE" | awk '{print $NF}')
  firefox "$URL"
else
  APP=$(echo "$CHOICE" | xargs)
  gtk-launch "$APP"
fi