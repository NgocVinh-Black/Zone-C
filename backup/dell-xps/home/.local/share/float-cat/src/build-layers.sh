#!/bin/bash
# Splits src/cat.png (grayscale, transparent background) into the animated overlay's layers
# (all 256x255, same origin) under ../gray; tint.sh colours them per theme.
# Shapes (cloud, face) are found on cat-ref.png, the same picture in colour.
# Re-run after editing src/cat.png; coordinates are image pixels.
set -e
cd "$(dirname "$0")"
OUT=../gray
mkdir -p "$OUT"
T=${KEEP_TMP:-$(mktemp -d)}; [ -z "$KEEP_TMP" ] && trap 'rm -rf "$T"' EXIT; mkdir -p "$T"
SZ=256x255

poly() { magick -size $SZ xc:black +antialias -fill white -draw "polygon $1" "$T/$2.png"; }
rect() { magick -size $SZ xc:black +antialias -fill white -draw "rectangle $1" "$T/$2.png"; }
# mask ops: union / minus
union() { local o=$1; shift; magick "$T/$1.png" -alpha off $(for m in "${@:2}"; do echo "( $T/$m.png -alpha off ) -compose lighten -composite"; done) -alpha off "$T/$o.png"; }
minus() { magick "$T/$2.png" -alpha off \( "$T/$3.png" -alpha off -negate \) -compose multiply -composite -alpha off "$T/$1.png"; }
# layer: src pixels where mask is white
apply() { magick "$1" -write mpr:img +delete mpr:img -alpha extract \( "$T/$2.png" -alpha off \) -compose multiply -composite mpr:img +swap -compose CopyOpacity -composite "$3"; }
# fill transparent pixels of $1 inside mask $2 with blurred nearby colours (or a flat colour $4)
fill() {
  if [ -n "$4" ]; then magick -size $SZ xc:"$4" "$T/f.png"
  else magick "$1" \( +clone -channel RGBA -blur 0x24 \) \( -clone 0 -channel RGBA -blur 0x9 \) \( -clone 0 -channel RGBA -blur 0x3 \) -delete 0 -background none -flatten -alpha off "$T/f.png"; fi
  magick "$T/f.png" "$T/$2.png" -alpha off -compose CopyOpacity -composite "$1" -compose over -composite "$3"
}

magick -size $SZ xc:white "$T/all.png"

# --- cloud: big light blob (holes filled so the pig badge rides along), its right bolt, its outline
magick cat-ref.png -background black -alpha remove -colorspace gray -threshold 88% \
  -define connected-components:area-threshold=300 -define connected-components:mean-color=true -connected-components 8 \
  -fill black -draw "rectangle 0,0 255,150" -draw "rectangle 0,0 60,255" \
  -bordercolor black -border 1 -fill gray50 -draw "color 0,0 floodfill" -shave 1x1 -fill black -opaque gray50 -fill white +opaque black \
  -morphology Dilate Disk:3.5 -fill black -draw "rectangle 0,231 255,255" "$T/cloud.png"
magick "$T/cloud.png" \( cat-ref.png -background black -alpha remove -colorspace gray -threshold 88% -fill black -draw "rectangle 0,0 255,156" -draw "rectangle 61,0 255,255" -draw "rectangle 0,231 255,255" -morphology Dilate Disk:3.5 \) -compose lighten -composite "$T/cloud.png"

# --- shapes
poly "64,62 64,42 70,17 84,17 111,47 109,58 88,64" earL
poly "145,58 143,47 170,17 185,17 192,40 194,66 168,64" earR
poly "64,58 64,42 70,17 84,17 111,47 108,52 88,56" earLcut
poly "146,52 143,47 170,17 185,17 192,40 194,60 168,56" earRcut
rect "42,99 58,124" whiskL
rect "198,99 219,123" whiskR
poly "140,111 150,111 173,121 173,134 160,134 140,121" swab
poly "168,127 190,126 213,149 228,166 224,182 200,182 186,165 180,152 166,141" hand
poly "0,116 56,120 74,130 80,140 80,162 40,200 0,206" cape
poly "3,0 25,0 73,32 73,80 52,80 32,62 18,42 3,18" boltBigRaw
poly "23,56 30,45 40,50 41,71 25,71" boltS1
rect "9,76 27,101" boltS2
rect "62,231 92,255" boltB1
rect "165,231 196,255" boltB2
# head: the face fill connected to its middle, holes filled, grown to take the outline; plus the spikes
magick cat-ref.png -background black -alpha remove -alpha off -fuzz 7% -fill white -opaque '#bedce7' -fill black +opaque white \
  -fill gray50 -draw "color 128,80 floodfill" -fill black +opaque gray50 -fill white -opaque gray50 \
  -bordercolor black -border 1 -fill gray50 -draw "color 0,0 floodfill" -shave 1x1 -fill black -opaque gray50 -fill white +opaque black \
  -morphology Dilate Disk:4 \( -size $SZ xc:black +antialias -fill white -draw "polygon 100,18 156,18 156,50 100,50" \) -compose lighten -composite \
  \( cat.png -alpha extract -threshold 50% \) -compose multiply -composite -alpha off "$T/headRaw.png"
union headAll headRaw earLcut earRcut
minus boltBig boltBigRaw headAll
union bolts boltS1 boltS2 boltB1 boltB2 boltBig

# head: the head ellipse with its spikes, minus parts animated on their own
minus head0 headRaw cloud
minus head1 head0 whiskL; minus head2 head1 whiskR; minus head3 head2 swab
minus head head3 bolts
# body: everything else that is not cloud / cape / hand / bolts / ears / head
magick "$T/cloud.png" -morphology Dilate Disk:5 \( -size $SZ xc:white +antialias -fill black -draw "rectangle 65,0 200,199" \) -compose multiply -composite "$T/cloudRing.png"
union notBody headAll cloud cape hand bolts whiskL whiskR cloudRing
minus body all notBody
minus capeM cape cloud; minus hand0 hand cloud; minus handM hand0 headRaw

for p in earL earR whiskL whiskR swab cloud boltBig boltS1 boltS2; do apply cat.png $p "$OUT/l-$p.png"; done

# bottom bolts: 256x268 (taller than the rest), tips the source cut off drawn in
BH=268
fg=$(magick cat.png -format '%[pixel:p{74,252}]' info:); ol=$(magick cat.png -format '%[pixel:p{71,252}]' info:)
magick cat.png -background none -extent 256x$BH \
  -fill "$ol" -stroke none -draw "polygon 69,254 80,254 67,265" -draw "polygon 176,254 181,254 175,259" \
  -fill "$fg" -draw "polygon 72,253 77,253 70,261" "$T/catx.png"
for b in boltB1 boltB2; do
  magick "$T/$b.png" -background black -extent 256x$BH "$T/$b.png"
  magick "$T/$b.png" -fill white -draw "$( [ $b = boltB1 ] && echo 'rectangle 62,255 92,267' || echo 'rectangle 165,255 196,267')" "$T/$b.png"
  magick "$T/catx.png" -write mpr:img +delete mpr:img -alpha extract \( "$T/$b.png" -alpha off \) -compose multiply -composite mpr:img +swap -compose CopyOpacity -composite "$OUT/l-$b.png"
done
apply cat.png capeM "$OUT/l-cape.png"
apply cat.png handM "$OUT/l-hand.png"

# head: swab hole filled with face colour so the swab can move over a clean face
apply cat.png head "$T/head.png"
fill "$T/head.png" swab "$OUT/l-head.png" "$(magick cat.png -format '%[pixel:p{100,113}]' info:)"

# body: fill under the cloud, the hand and the head (drawn over it) so small relative moves show no gap
apply cat.png body "$T/body.png"
magick "$T/cloud.png" -morphology Erode Disk:7 "$T/hand.png" -compose lighten -composite \( cat.png -alpha extract -threshold 50% \) -compose multiply -composite \( "$T/headRaw.png" -morphology Erode Disk:2 \) -compose lighten -composite \( cat.png -alpha extract -threshold 50% \) -compose multiply -composite "$T/fillzone.png"
fill "$T/body.png" fillzone "$OUT/l-body.png" "$(magick cat.png -format '%[pixel:p{71,252}]' info:)"

# eye patches for blink / wink
rect "84,94 121,113" eyeL; rect "135,94 172,113" eyeR
union eyes eyeL eyeR
apply cat-blink.png eyes "$OUT/l-blink.png"
apply cat-wink.png eyeR "$OUT/l-wink.png"
echo done
