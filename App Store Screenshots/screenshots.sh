#! /bin/sh

# Convert png screenshots to jpg images suitable for upload to app store

set -e

for file in *.png; do
    magick -resize 70%x70% "${file}" \
        -gravity center \
        -background "rgb(210,210,210)" \
        -extent 2560x1600 \
        "${file%.png}.jpg"
done
