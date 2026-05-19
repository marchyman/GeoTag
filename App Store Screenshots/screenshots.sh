#! /bin/sh

# Convert png screenshots to jpg images suitable for upload to app store

set -e
set -x

for file in *.png; do
    magick "${file}" -resize 70%x70% \
        -gravity center \
        -background "rgb(210,210,210)" \
        -extent 2560x1600 \
        "${file%.png}.jpg"
done
