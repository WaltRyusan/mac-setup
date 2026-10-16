#!/usr/bin/env bash
# macOS の設定をまとめて適用する（個人の Mac 用）
#
#   bash apply-macos-settings.sh           # 対話モード（項目ごとに Y/n。Enter だけなら適用）
#   bash apply-macos-settings.sh --all     # すべて適用（--yes も同じ）
#   bash apply-macos-settings.sh --dry-run # 表示のみ
#   bash apply-macos-settings.sh --list    # 項目を番号つきで一覧表示するだけ（何も変えない）
#   bash apply-macos-settings.sh --yes --skip 3,12   # 質問せずに、3番と12番以外を適用
#   bash apply-macos-settings.sh --yes --with 15     # 既定が N の項目（[y/N]）は --with で番号を渡したときだけ適用
#     Claude Code から実行するときは、--list で一覧を見せて選んでもらい、外す番号を --skip で渡す。
#
# ※ 実行前にシステム設定アプリを閉じてください（開いたままだと上書きされます）
# ※ キーリピート等は再ログイン後に反映されます

set -uo pipefail
MODE="interactive"
SKIP=","
WITH=","
while [ $# -gt 0 ]; do
  case "$1" in
    --all|--yes) MODE="all" ;;
    --dry-run)   MODE="dry-run" ;;
    --list)      MODE="list" ;;
    --skip)      shift; SKIP=",${1:-},"; [ "$#" -gt 0 ] || break ;;
    --with)      shift; WITH=",${1:-},"; [ "$#" -gt 0 ] || break ;;
    *) echo "不明なオプション: $1"; exit 1 ;;
  esac
  shift
done

N=0   # 項目の番号（confirm を呼んだ順。--list と --skip で使う）
confirm() {  # <項目名> [N]。2つ目に N を渡すと既定の答えが N（[y/N]）になる
  local label="$1" def="${2:-Y}"
  N=$((N + 1))
  case "$MODE" in
    list)    printf "%3d. %s%s\n" "$N" "$label" "$([ "$def" = N ] && echo '（既定は N）')"; return 1 ;;
    all)
      if [ "$def" = N ]; then
        case "$WITH" in
          *",$N,"*) echo "▶ 適用（--with）: $N. $label"; return 0 ;;
          *)        echo "· 既定 N のため外す: $N. $label"; return 1 ;;
        esac
      fi
      case "$SKIP" in
        *",$N,"*) echo "· 外す（--skip）: $N. $label"; return 1 ;;
        *)        echo "▶ 適用: $N. $label"; return 0 ;;
      esac ;;
    dry-run) echo "· [dry-run] $N. $label"; return 1 ;;
    *)
      if [ "$def" = N ]; then
        read -r -p "適用しますか？ $N. $label [y/N]: " ans; [[ "$ans" =~ ^[Yy] ]]
      else
        read -r -p "適用しますか？ $N. $label [Y/n]: " ans; [[ ! "$ans" =~ ^[Nn] ]]
      fi ;;
  esac
}

echo "=== macOS 推奨設定  モード: $MODE ==="
if [ "$MODE" = "interactive" ]; then
  echo "各項目は Enter だけで既定の答え（[Y/n] / [y/N] の大文字）になります。"
  echo "ほとんどは Y（適用する）です。変えたい項目だけ y / n を入力してください。"
fi
echo

# --- スクリーンショット ---
if confirm "保存先を ~/Pictures/Screenshots に変更"; then
  mkdir -p "$HOME/Pictures/Screenshots"
  defaults write com.apple.screencapture location "$HOME/Pictures/Screenshots"
fi

# --- Mission Control ---
if confirm "操作スペースの自動並べ替えを無効化"; then
  defaults write com.apple.dock mru-spaces -bool false
fi
# 「アプリを切り替えたときに操作スペースへ移動しない」（AppleSpacesSwitchOnActivate false）は入れない。
# Cmd+Tab で別の操作スペースにあるアプリへ切り替えられなくなるため（2026-10 実機で確認）。既定（移動する）のままにする

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
# Dock に並べるアプリは、Xcode などを入れ終わってから arrange-dock.sh で設定する（ここではやらない）

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
# NAS や共有フォルダを使わないなら不要。使う場合、ほかの人（Windows など）から .DS_Store が見えるのを防ぐ
if confirm "NAS・共有フォルダを使う: ネットワークドライブに .DS_Store を作らない" N; then
  defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
fi
if confirm "Finder: ゴミ箱の項目を30日後に自動削除する"; then
  defaults write com.apple.finder FXRemoveOldTrashItems -bool true
fi
# 1=小 / 2=中 / 3=大。既定は 3（キーを消して実測・2026-10）。
# 3 段階とも実機で見比べて 2 を採用した。1 は小さすぎ、3 は既定どおり大きい。
# サイドバーだけでなく、リスト表示の行の高さにも効く
if confirm "サイドバーの文字・アイコンを中サイズにする（既定は大きい）"; then
  defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2
fi

# --- キーボード ---
# GUI のスライダーで選べる最速（KeyRepeat 2 / InitialKeyRepeat 15）。
# 1 / 10 のように GUI より速くもできるが、長押しで連打されすぎるため GUI の範囲にとどめる（2026-10）
if confirm "キーリピートを GUI で選べる最速にする（要再ログイン）"; then
  defaults write NSGlobalDomain KeyRepeat -int 2
  defaults write NSGlobalDomain InitialKeyRepeat -int 15
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
# 既定（false）は F1 で画面が暗くなる。true で F1〜F12 が単体で効き、F7/F10 の変換も fn なしで使える。
# 明るさ・音量は fn + キーになる。再起動後に F1 で明るさが変わらず F10 で半角になることを確認（2026-10）
if confirm "F1/F2 などを標準のファンクションキーにする（要再ログイン）"; then
  defaults write NSGlobalDomain com.apple.keyboard.fnState -bool true
fi
if confirm "Caps Lock で英字/かな を切り替える（大文字固定は Shift+CapsLock で使える）"; then
  defaults write NSGlobalDomain TISRomanSwitchState -bool true
  echo "    ・ 通常は再起動なしで反映されます。"
  echo "    ・ 効かない場合は、修飾キー側で Caps Lock が別の役割に割り当てられている可能性があります。"
  echo "      システム設定 → キーボード → キーボードショートカット… → 修飾キー を開き、"
  echo "      Caps Lock が「Caps Lock」になっているか確認してください（Control 等になっていたら戻す）。"
  echo "      変更した場合は再起動が必要です。"
fi

# --- 日本語入力 ---
# ライブ変換が ON のままだと「Windows風のキー操作」が機能しないため、3つはセットで適用する
if confirm "ライブ変換 OFF ＋ Windows風のキー操作 ON（Enter 1回で変換を確定）"; then
  defaults write com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey -bool false
  defaults write com.apple.inputmethod.Kotoeri JIMPrefWindowsModeKey    -bool true
  defaults write com.apple.inputmethod.Kotoeri JIMPrefAutocorrectionKey -bool false
fi
# 「／」キーで入力する文字。0 = / / 1 = ・（GUI の切替前後の差分で確認・2026-10）。
# 以前は ¥キーの設定と誤認して 0 を書いていた
if confirm "日本語入力で ／ キーを「・」（中黒）にする"; then
  defaults write com.apple.inputmethod.Kotoeri JIMPrefCharacterForSlashKey -int 1
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
# GUI のスライダーの最大は 3（2026-10 に差分で特定）。コマンドならそれより速くでき、
# 5・6 とも再起動後に効くことを実機で確認して 6 を採用した（2026-10）
if confirm "トラックパッドの軌跡の速さを GUI の最大より速くする（★要再起動）"; then
  defaults write NSGlobalDomain com.apple.trackpad.scaling -float 6
fi

# --- Spotlight ---
# 除外リストは defaults では書けないため、設定画面を開いて追加するフォルダを表示する（半自動）
if confirm "Spotlight の検索から Xcode・Gradle の生成物を外す（設定画面を開く。インデックス作成の負荷と検索のノイズを減らす）"; then
  echo "    次のフォルダを「検索のプライバシー…」の ＋ で追加してください（無いものは飛ばしてよい）:"
  for d in "$HOME/Library/Developer/Xcode/DerivedData" "$HOME/Library/Developer/CoreSimulator" "$HOME/.gradle" "$HOME/Library/Android/sdk"; do
    echo "      $d"
  done
  open "x-apple.systempreferences:com.apple.Spotlight-Settings.extension" 2>/dev/null || true
fi

# --- ターミナル ---
# 「大きさ」（187×57 のような表示）は AppleScript で既定のプロファイルに書ける。
# defaults で書くと、起動中のターミナルが設定を保存したときに消される（2026-10 実測）。
# 「作業ディレクトリまたは書類」も同じ理由で消されるうえ AppleScript に項目が無いため、GUI で外す
if confirm "ターミナル: タイトルからウインドウの大きさを消す（既定のプロファイル）"; then
  osascript -e 'tell application "Terminal" to set title displays window size of default settings to false' >/dev/null \
    || echo "    ・ 設定できませんでした（ターミナルの操作の許可を求められたら「OK」を押して再実行）"
fi

# --- zsh プロンプト（4つに分けて選べる。~/.zshrc に追記する）---
# 追記する前に ~/.zshrc を1回だけバックアップする。同じ項目は二重に追記しない（目印のコメントで判定）
ZSHRC_BACKED_UP=0
zshrc_add() {  # <目印> <追記する中身>
  if grep -qF "# mac-setup: $1" "$HOME/.zshrc" 2>/dev/null; then
    echo "    ・ 設定済みのためスキップ"
    return
  fi
  if [ "$ZSHRC_BACKED_UP" = 0 ] && [ -f "$HOME/.zshrc" ]; then
    local backup="$HOME/.zshrc.bak.$(date +%Y%m%d%H%M%S)"
    cp "$HOME/.zshrc" "$backup" && echo "    ・ バックアップ: ${backup}"
    ZSHRC_BACKED_UP=1
  fi
  printf '\n# mac-setup: %s\n%s\n' "$1" "$2" >> "$HOME/.zshrc"
  echo "    ・ ~/.zshrc に追記しました（新しいターミナルから有効）"
}
if confirm "zsh: プロンプトを今いるフォルダ名だけにする（ユーザー名@ホスト名を消す。スクショで隠さなくてよい）"; then
  zshrc_add "prompt-folder" "PROMPT='%1~ %# '"
fi
if confirm "zsh: コマンドを実行した時刻を出す（出力との区切り線も兼ねる）"; then
  zshrc_add "exec-time" 'function preexec_timestamp() { print -P "%F{244}── %D{%Y-%m-%d %H:%M:%S}%f" }
preexec_functions+=( preexec_timestamp )'
fi
if confirm "zsh: ターミナルのタイトルに今いるフォルダのフルパスを出す"; then
  zshrc_add "title-path" 'function set_terminal_title() { print -Pn "\e]0;%~\a" }
precmd_functions+=( set_terminal_title )'
fi
if confirm "zsh: コマンドの出力のあとに空行を入れる"; then
  zshrc_add "newline-after-output" 'function add_newline() {
  if [[ -z "$PS1_NEWLINE_LOGIN" ]]; then PS1_NEWLINE_LOGIN=true; else print ""; fi
}
precmd_functions+=( add_newline )'
fi

if [ "$MODE" = "list" ]; then
  echo
  echo "（--list: 一覧を表示しただけで、何も変えていません。外す番号は --yes --skip 3,12 のように渡す）"
  exit 0
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
  echo "   - Finder サイドバーの整理"
  echo "   - Spotlight の検索プライバシー（このスクリプトで画面を開いた場合は、フォルダの追加）"
  echo "   - ターミナルのタイトルの「作業ディレクトリまたは書類」を外す"
  echo "     （パスは ~/.zshrc でタイトルに出しているため二重になる。"
  echo "      設定→プロファイル→ウインドウ。「大きさ」はこのスクリプトで外し済み）"
  echo "   詳細は manual-settings.md を参照"
else
  echo
  echo "[dry-run] 実際の変更は行っていません。"
fi
