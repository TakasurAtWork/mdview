#!/bin/zsh
# ./build.sh          → build/MDView.app
# ./build.sh install  → also copies to ~/Applications and links `mdv` into ~/.local/bin
set -euo pipefail
cd "${0:A:h}"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/MDView"
APP=build/MDView.app

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/MDView"
strip -x "$APP/Contents/MacOS/MDView"
cp Resources/Info.plist "$APP/Contents/"
[[ -f Resources/AppIcon.icns ]] || swift tools/make-icon.swift Resources/AppIcon.icns
cp Resources/AppIcon.icns Resources/highlight.min.js "$APP/Contents/Resources/"
codesign --force --sign - "$APP"
echo "Built $APP ($(du -sh "$APP" | cut -f1))"

if [[ "${1:-}" == "install" ]]; then
  rm -rf ~/Applications/MDView.app
  mkdir -p ~/Applications ~/.local/bin
  cp -R "$APP" ~/Applications/
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f ~/Applications/MDView.app
  ln -sf "$PWD/bin/mdv" ~/.local/bin/mdv
  echo "Installed ~/Applications/MDView.app and ~/.local/bin/mdv"
fi
