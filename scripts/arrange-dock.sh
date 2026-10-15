#!/usr/bin/env bash
# Dock に並べるアプリを設定する（今の並びは置き換える）。
# **Xcode・Android Studio などを全部入れ終わってから最後に実行する。**
# 入っていないアプリは飛ばすので、先に実行すると Xcode などが並ばない。
#
#   bash arrange-dock.sh            # 並べ替える
#   bash arrange-dock.sh --dry-run  # 並ぶ予定のアプリを表示するだけ
#
# 並べる順（左から）を変えるときは、下の APPS を書き換える。

set -uo pipefail

DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1

# Xcode・Android Studio はパスに版が入るため、実在するものを拾う（複数あれば新しい方を1つ）
# 名前に空白があるため、パターンは引数で渡さずにここで展開する
latest() { [ $# -gt 0 ] && [ -e "$1" ] && printf '%s\n' "$@" | sort -V | tail -1; }
XCODE="$(latest /Applications/Xcode*.app)"
STUDIO="$(latest "/Applications/Android Studio"*.app)"

APPS=(
  "/Applications/Slack.app"
  "/Applications/Google Chrome.app"
  "/Applications/Figma.app"
  "/Applications/Sourcetree.app"
  "$XCODE"
  "${XCODE:+$XCODE/Contents/Developer/Applications/Simulator.app}"
  "/Applications/Visual Studio Code.app"
  "$STUDIO"
  "/System/Applications/Utilities/Terminal.app"
  "/Applications/Claude.app"
  "/System/Applications/Notes.app"
  "/System/Applications/TextEdit.app"
  "/Applications/Shottr.app"
  "/System/Applications/System Settings.app"
)

echo "▶ Dock の並び（左から）"
added=()
for app in "${APPS[@]}"; do
  [ -n "$app" ] || continue
  if [ -e "$app" ]; then
    added+=("$app")
    echo "  ・ $(basename "$app" .app)"
  else
    echo "  ・ スキップ（未インストール）: $(basename "$app" .app)"
  fi
done
[ -z "$XCODE" ]  && echo "  ・ スキップ（未インストール）: Xcode"
[ -z "$STUDIO" ] && echo "  ・ スキップ（未インストール）: Android Studio"

if [ "$DRY" = "1" ]; then
  echo "  （dry-run: Dock は変更していません）"
  exit 0
fi

# persistent-apps は plist の入れ子配列だが、-array-add で追加できる。
# _CFURLStringType は 0 を渡せば macOS 側が file:// 形式（type=15）へ正規化する。dockutil は不要（2026-10 実測）。
defaults write com.apple.dock persistent-apps -array   # いったん空にする
for app in ${added[@]+"${added[@]}"}; do
  defaults write com.apple.dock persistent-apps -array-add \
    "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
done
killall Dock 2>/dev/null || true
echo "  ✅ ${#added[@]} 個を並べました"
