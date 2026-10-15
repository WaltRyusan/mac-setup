#!/usr/bin/env bash
# Xcode の DerivedData（ビルドの生成物）を定期的に消す仕組みを入れる。
# macOS の launchd（決まった時刻に処理を動かす、macOS 標準の仕組み）に登録するので、
# Claude Code を開いていなくても自動で動く。
#
#   bash install-derived-data-cleaner.sh              # 入れる（毎週月曜 11:00 に、7日より古いものを消す）
#   bash install-derived-data-cleaner.sh --uninstall  # 止めて消す
#   bash install-derived-data-cleaner.sh --dry-run    # 何をするかだけ表示
#
# 入るもの:
#   ~/.local/bin/clean-derived-data.sh                  … 実際に消すスクリプト（手で実行してもよい）
#   ~/Library/LaunchAgents/local.clean-derived-data.plist … launchd の登録
#   ~/Library/Logs/clean-derived-data.log               … 実行の記録
# 時刻・日数を変えるときは、下の WEEKDAY / HOUR / DAYS を書き換えて入れ直す。
# Mac がスリープ中だった場合は、起きたときに1回動く（launchd の仕様）。

set -uo pipefail

WEEKDAY=1   # 0=日曜, 1=月曜, …
HOUR=11
DAYS=7      # これより古い（最後に変更されてから DAYS 日を過ぎた）フォルダを消す

LABEL="local.clean-derived-data"
BIN="$HOME/.local/bin/clean-derived-data.sh"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/Library/Logs/clean-derived-data.log"
DOMAIN="gui/$(id -u)"

MODE="install"
case "${1:-}" in
  --uninstall) MODE="uninstall" ;;
  --dry-run)   MODE="dry-run" ;;
esac

ok() { printf "  ✅ %s\n" "$1"; }

if [ "$MODE" = "uninstall" ]; then
  launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
  rm -f "$PLIST" "$BIN"
  ok "止めて消しました（ログ $LOG は残しています）"
  exit 0
fi

if [ "$MODE" = "dry-run" ]; then
  echo "  [dry-run] $BIN を作る（DerivedData の ${DAYS} 日より古いフォルダと、使えないシミュレータを消す）"
  echo "  [dry-run] $PLIST を作り、launchd に登録する（曜日 ${WEEKDAY}・${HOUR}:00）"
  exit 0
fi

mkdir -p "$(dirname "$BIN")" "$(dirname "$PLIST")" "$(dirname "$LOG")"

cat > "$BIN" <<EOF
#!/usr/bin/env bash
# install-derived-data-cleaner.sh が作ったファイル。DerivedData の古いものを消す。
DD="\$HOME/Library/Developer/Xcode/DerivedData"
echo "== \$(date '+%Y-%m-%d %H:%M:%S') =="
if [ -d "\$DD" ]; then
  before=\$(du -sh "\$DD" 2>/dev/null | awk '{print \$1}')
  find "\$DD" -mindepth 1 -maxdepth 1 -type d -mtime +${DAYS} -print -exec rm -rf {} +
  after=\$(du -sh "\$DD" 2>/dev/null | awk '{print \$1}')
  echo "DerivedData: \$before -> \$after"
fi
# 入っている Xcode では使えなくなったシミュレータを消す
xcrun simctl delete unavailable 2>/dev/null && echo "使えないシミュレータを削除"
EOF
chmod +x "$BIN"

cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>$BIN</string></array>
  <key>StartCalendarInterval</key>
  <dict><key>Weekday</key><integer>$WEEKDAY</integer><key>Hour</key><integer>$HOUR</integer><key>Minute</key><integer>0</integer></dict>
  <key>StandardOutPath</key><string>$LOG</string>
  <key>StandardErrorPath</key><string>$LOG</string>
</dict>
</plist>
EOF
plutil -lint "$PLIST" >/dev/null || { echo "  ❌ plist の形式が正しくありません: $PLIST"; exit 1; }

# 入れ直しのときは、古い登録を外してから登録する
launchctl bootout "$DOMAIN/$LABEL" 2>/dev/null || true
if launchctl bootstrap "$DOMAIN" "$PLIST"; then
  ok "登録しました（曜日 ${WEEKDAY}・${HOUR}:00 に、${DAYS} 日より古い DerivedData を消す）"
  echo "    今すぐ1回動かす: launchctl kickstart $DOMAIN/$LABEL"
  echo "    記録: $LOG"
  echo "    止める: bash $0 --uninstall"
else
  echo "  ❌ launchd への登録に失敗しました"
  exit 1
fi
