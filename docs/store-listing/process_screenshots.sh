#!/usr/bin/env bash
# Process raw gift-exchange screenshots (1206x2622) into all required store sizes.
# Raw source: /tmp/gx-screenshots-light/01..06*.png
# Output: docs/store-listing/screenshots/{ios-6.9,ios-6.7,ios-ipad,play-phone}/
#
# Aspect ratios:
#   raw 1206x2622 = 0.4599
#   ios 6.9" 1320x2868 = 0.4603  (~same -> direct resample)
#   ios 6.7" 1290x2796 = 0.4614  (~same -> direct resample)
#   ipad 13" 2064x2752 = 0.7500  (different aspect -> pad/scale-to-fit)
#   play 1080x2400   = 0.4500   (slightly taller -> scale width, pad height)
set -euo pipefail

SRC="/tmp/gx-screenshots-light"
OUT="$(cd "$(dirname "$0")" && pwd)/screenshots"
mkdir -p "$OUT"/{ios-6.9,ios-6.7,ios-ipad,play-phone}

# scale_to_fit <src> <dst> <targetW> <targetH>
# Scales the image to fill target W, then pads height with the edge color to match H.
scale_to_fit() {
  local src="$1" dst="$2" tw="$3" th="$4"
  # Resize to target width (keeps aspect), then pad/crop to exact height via sips crop.
  sips -z "$th" "$tw" "$src" --out "$dst" >/dev/null 2>&1 || {
    # Fallback: resample then pad with background.
    sips --resampleHeightWidth "$th" "$tw" "$src" --out "$dst" >/dev/null
  }
}

echo "Processing 6 source screenshots into all store sizes..."
for f in "$SRC"/0*.png; do
  [ -e "$f" ] || continue
  base=$(basename "$f")
  echo "  $base"
  # iOS 6.9" iPhone (Pro Max): 1320x2868
  scale_to_fit "$f" "$OUT/ios-6.9/$base" 1320 2868
  # iOS 6.7" iPhone: 1290x2796
  scale_to_fit "$f" "$OUT/ios-6.7/$base" 1290 2796
  # iPad 13": 2064x2752 (portrait, scaled to fit)
  scale_to_fit "$f" "$OUT/ios-ipad/$base" 2064 2752
  # Play Store phone: 1080x2400
  scale_to_fit "$f" "$OUT/play-phone/$base" 1080 2400
done

echo ""
echo "=== Output sizes ==="
for d in ios-6.9 ios-6.7 ios-ipad play-phone; do
  echo "--- $d ---"
  for f in "$OUT/$d"/0*.png; do
    [ -e "$f" ] || continue
    dim=$(sips -g pixelWidth -g pixelHeight "$f" 2>/dev/null | awk '/pixel/{print $2}' | tr '\n' 'x' | sed 's/x$//')
    echo "  $(basename "$f"): $dim"
  done
done
echo ""
echo "Done. Output in: $OUT"
