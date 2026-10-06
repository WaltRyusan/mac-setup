#!/usr/bin/env bash
# macOS 推奨設定の適用（モバイルアプリ開発向け）
#
#   bash apply-macos-settings.sh           # 対話モード（項目ごとに y/N）
#   bash apply-macos-settings.sh --all     # すべて適用
#   bash apply-macos-settings.sh --dry-run # 表示のみ
#
# ※ 実行前にシステム設定アプリを閉じてください（開いたままだと上書きされます）
# ※ キーリピート等は再ログイン後に反映されます

set -uo pipefail
MODE="interactive"
case "${1:-}" in
  --all)     MODE="all" ;;
  --dry-run) MODE="dry-run" ;;
esac

confirm() {
  local label="$1"
  case "$MODE" in
    all)     echo "▶ 適用: $label"; return 0 ;;
    dry-run) echo "· [dry-run] $label"; return 1 ;;
    *) read -r -p "適用しますか？ $label [y/N]: " ans; [[ "$ans" =~ ^[Yy]$ ]] ;;
  esac
}

echo "=== macOS 推奨設定  モード: $MODE ==="
echo

# --- スクリーンショット ---
if confirm "保存先を ~/Pictures/Screenshots に変更"; then
  mkdir -p "$HOME/Pictures/Screenshots"
  defaults write com.apple.screencapture location "$HOME/Pictures/Screenshots"
fi
if confirm "スクリーンショットの影を無効化"; then
  defaults write com.apple.screencapture disable-shadow -bool true
fi
if confirm "スクリーンショットを JPG 形式にする"; then
  defaults write com.apple.screencapture type jpg
fi

# --- Mission Control ---
if confirm "操作スペースの自動並べ替えを無効化"; then
  defaults write com.apple.dock mru-spaces -bool false
fi

# --- Dock ---
if confirm "Dock を自動的に非表示にする"; then
  defaults write com.apple.dock autohide -bool true
fi
if confirm "Dock の表示遅延をゼロにする"; then
  defaults write com.apple.dock autohide-delay -float 0
  defaults write com.apple.dock autohide-time-modifier -float 0.15
fi
if confirm "Dock に最近使用したアプリを表示しない"; then
  defaults write com.apple.dock show-recents -bool false
fi
if confirm "Dock を画面下に配置する"; then
  defaults write com.apple.dock orientation -string "bottom"
fi
if confirm "Dock のアイコンサイズを 52 にする（既定48）"; then
  defaults write com.apple.dock tilesize -int 52
fi
if confirm "ウインドウをしまうエフェクトをスケールにする（既定ジニー）"; then
  defaults write com.apple.dock mineffect -string "scale"
fi
if confirm "Dock に並べるアプリを設定する（既存の並びを置き換える）"; then
  # persistent-apps は plist の入れ子配列だが、-array-add で追加できる。
  # _CFURLStringType は 0 を渡せば macOS 側が file:// 形式（type=15）へ正規化する。
  # dockutil は不要（2026-10 実測）。
  dock_add() {
    [ -e "$1" ] || { echo "    ・ スキップ（未インストール）: $1"; return; }
    defaults write com.apple.dock persistent-apps -array-add \
      "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$1</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
  }
  defaults write com.apple.dock persistent-apps -array   # いったん空にする
  dock_add "/Applications/Slack.app"
  dock_add "/Applications/Google Chrome.app"
  dock_add "/Applications/Figma.app"
  dock_add "/Applications/Sourcetree.app"
  # Xcode はパスにバージョンが入るため、実在するものを拾う（複数あれば最新を1つ）
  xc=$(ls -d /Applications/Xcode*.app 2>/dev/null | sort -V | tail -1)
  [ -n "$xc" ] && dock_add "$xc" && dock_add "$xc/Contents/Developer/Applications/Simulator.app"
  dock_add "/System/Applications/Utilities/Terminal.app"
  dock_add "/Applications/Claude.app"
  dock_add "/Applications/Apidog.app"
  dock_add "/System/Applications/Notes.app"
  dock_add "/System/Applications/TextEdit.app"
  dock_add "/Applications/Shottr.app"
  dock_add "/System/Applications/System Settings.app"
fi

# --- 外観 ---
if confirm "ダークモードにする"; then
  defaults write -g AppleInterfaceStyle -string "Dark"
fi

# --- Finder ---
if confirm "Finder: パスバーを表示"; then
  defaults write com.apple.finder ShowPathbar -bool true
fi
if confirm "Finder: ステータスバーを表示"; then
  defaults write com.apple.finder ShowStatusBar -bool true
fi
if confirm "Finder: 隠しファイルを常に表示"; then
  defaults write com.apple.finder AppleShowAllFiles -bool true
fi
if confirm "Finder: すべての拡張子を表示"; then
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
fi
if confirm "Finder: デフォルトをリスト表示にする"; then
  defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
fi
if confirm "Finder: 検索を現在のフォルダ内にする"; then
  defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
fi
if confirm "Finder: 拡張子変更の警告を無効化"; then
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
fi
if confirm "ネットワークドライブに .DS_Store を作らない"; then
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
fi

# --- キーボード ---
if confirm "キーリピートを最速化（要再ログイン）"; then
  defaults write NSGlobalDomain KeyRepeat -int 1
  defaults write NSGlobalDomain InitialKeyRepeat -int 10
fi
if confirm "キー長押しのアクセント入力を無効化"; then
  defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
fi
if confirm "スマートダッシュ／スマート引用符を無効化（-- が — に化けるのを防ぐ）"; then
  defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
fi
if confirm "スペル自動修正・自動大文字化を無効化"; then
  defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
fi
if confirm "F1/F2 を標準ファンクションキーにしない（要再ログイン）"; then
  defaults write NSGlobalDomain com.apple.keyboard.fnState -bool false
fi
if confirm "Caps Lock で英字/かな を切り替える（大文字固定は Shift+CapsLock で使える）"; then
  defaults write NSGlobalDomain TISRomanSwitchState -bool true
fi

# --- 日本語入力 ---
# ライブ変換が ON のままだと「Windows風のキー操作」が機能しないため、3つはセットで適用する
if confirm "ライブ変換 OFF ＋ Windows風のキー操作 ON（Enter 1回で変換を確定）"; then
  defaults write com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey -bool false
  defaults write com.apple.inputmethod.Kotoeri JIMPrefWindowsModeKey    -bool true
  defaults write com.apple.inputmethod.Kotoeri JIMPrefAutocorrectionKey -bool false
fi

# --- トラックパッド ---
# killall では反映されず再起動が必要（2026-10 / macOS 26.2 実測）
if confirm "タップでクリックを有効化（★要再起動）"; then
  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
  defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
fi
if confirm "三本指でのドラッグを有効化（★要再起動）"; then
  defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
fi

# --- zsh プロンプト ---
if confirm "~/.zshrc にプロンプト設定（実行時刻のログ＋タイトルバーにパス＋出力後の改行）を追記"; then
  if grep -q "PS1_NEWLINE_LOGIN" "$HOME/.zshrc" 2>/dev/null; then
    echo "  ⚠ 既に設定済みのためスキップしました"
  else
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
    cat >> "$HOME/.zshrc" <<'ZRC'

# ---- プロンプト設定 ----
# ユーザー名@ホスト名を消して、現在地のフォルダ名だけにする
# （スクショを貼るときにマスキングが不要になる。フルパスはタイトルバーに出す）
PROMPT='%1~ %# '

# ---- コマンドを実行した時刻を出す ----
# precmd（プロンプト表示時）ではなく preexec（コマンド実行の直前）に出すので、
# 席を外してから打っても「実際に実行した時刻」が残る。出力との区切り線も兼ねる
function preexec_timestamp() { print -P "%F{244}── %D{%Y-%m-%d %H:%M:%S}%f" }
preexec_functions+=( preexec_timestamp )

# ---- タイトルバーにカレントパスを表示 ----
# プロンプトからパスを消すかわりにタイトルバーへ。GUI 設定に依存しない
function set_terminal_title() { print -Pn "\e]0;%~\a" }
precmd_functions+=( set_terminal_title )

# ---- コマンド出力の後に改行を入れる ----
function add_newline() {
  if [[ -z "$PS1_NEWLINE_LOGIN" ]]; then
    PS1_NEWLINE_LOGIN=true
  else
    print ""
  fi
}
precmd_functions+=( add_newline )
ZRC
    echo "  追記しました（バックアップ: ~/.zshrc.bak.*）"
  fi
fi

if [[ "$MODE" != "dry-run" ]]; then
  echo
  echo "設定を反映しています..."
  killall Finder 2>/dev/null || true
  killall Dock 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
  echo "完了しました。"
  echo
  echo "※ キーリピート・ファンクションキーは再ログイン後に反映されます"
  echo "※ トラックパッド（タップでクリック／三本指ドラッグ）は【再起動後】に反映されます"
  echo "   設定直後に効いていなくても失敗ではありません"
  echo "※ 以下は GUI 操作が必要です："
  echo "   - Caps Lock を Control / Escape に変更する場合（英字切替はこのスクリプトで設定済み）"
  echo "   - 日本語入力の「¥キーで入力する文字」"
  echo "   - トラックパッドの「軌跡の速さ」"
  echo "   - Finder サイドバーの整理"
  echo "   - Spotlight の検索プライバシー"
  echo "   - ターミナルのタイトルバーの重複を消す場合のみ"
  echo "     （パス表示自体は ~/.zshrc で設定済み。設定→プロファイル→ウインドウで"
  echo "      「カレントディレクトリ」「作動中のプロセス名」「大きさ」のチェックを外す）"
  echo "   詳細は manual-settings.md を参照"
else
  echo
  echo "[dry-run] 実際の変更は行っていません。"
fi
