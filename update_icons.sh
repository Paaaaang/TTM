#!/bin/bash

SOURCE="/Users/ipang/TTM/web/icons/icon.png"
DEST="/Users/ipang/TTM/ios/Runner/Assets.xcassets/AppIcon.appiconset"

sips -z 1024 1024 "$SOURCE" --out "$DEST/Icon-App-1024x1024@1x.png"
sips -z 20 20 "$SOURCE" --out "$DEST/Icon-App-20x20@1x.png"
sips -z 40 40 "$SOURCE" --out "$DEST/Icon-App-20x20@2x.png"
sips -z 60 60 "$SOURCE" --out "$DEST/Icon-App-20x20@3x.png"
sips -z 29 29 "$SOURCE" --out "$DEST/Icon-App-29x29@1x.png"
sips -z 58 58 "$SOURCE" --out "$DEST/Icon-App-29x29@2x.png"
sips -z 87 87 "$SOURCE" --out "$DEST/Icon-App-29x29@3x.png"
sips -z 40 40 "$SOURCE" --out "$DEST/Icon-App-40x40@1x.png"
sips -z 80 80 "$SOURCE" --out "$DEST/Icon-App-40x40@2x.png"
sips -z 120 120 "$SOURCE" --out "$DEST/Icon-App-40x40@3x.png"
sips -z 120 120 "$SOURCE" --out "$DEST/Icon-App-60x60@2x.png"
sips -z 180 180 "$SOURCE" --out "$DEST/Icon-App-60x60@3x.png"
sips -z 76 76 "$SOURCE" --out "$DEST/Icon-App-76x76@1x.png"
sips -z 152 152 "$SOURCE" --out "$DEST/Icon-App-76x76@2x.png"
sips -z 167 167 "$SOURCE" --out "$DEST/Icon-App-83.5x83.5@2x.png"

echo "✅ 모든 아이콘 크기가 생성되었습니다."
