#!/usr/bin/env bash
# 個人の Mac のセットアップをまとめて進める。install.sh から呼ばれる（直接実行してもよい）。
#
#   bash scripts/bootstrap.sh
#   bash scripts/bootstrap.sh --dry-run
#   bash scripts/bootstrap.sh --yes --skip charles,derived-data
#     --yes        … 質問せずに進める（Claude Code から実行するとき用。質問はすべて Y 扱い）
#     --skip <一覧> … --yes のときに「n」にするもの（カンマ区切り）。アプリは Brewfile の名前（例: charles）、
#                    手順は derived-data / ssh-key / skills、スキルはスキル名
#     Claude Code から実行する場合は、先に会話で選んでもらい、その答えを --skip で渡す。
#     パスワードやブラウザが要るもの（Homebrew の初回・gh auth login）は、ターミナルで直接打つ。
#
# やること: 前提チェック → Homebrew → アプリ（一覧から選ぶ）→ DerivedData の定期削除
#           → GitHub へのログイン・git の名前とメールアドレス・SSH 鍵 → スキル（claude-skills）
# やらないこと: macOS の設定 / 再起動 / Xcode / Flutter / Dock の並び（最後に案内する）
# 質問はすべて [Y/n] の形で、Enter だけなら大文字の既定の答え（Y）になる。

set -uo pipefail

DRY=0
YES=0
SKIP=","
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) DRY=1 ;;
    --yes)     YES=1 ;;
    --skip)    shift; SKIP=",${1:-},"; [ "$#" -gt 0 ] || break ;;
    *) echo "不明なオプション: $1"; exit 1 ;;
  esac
  shift
done

SKILLS_REPO="WaltRyusan/claude-skills"            # 個人のスキル集（非公開）
SKILLS_DIR="$HOME/Documents/personal/claude-skills"

run() {  # 実行（dry-run なら表示のみ）
  if [ "$DRY" = "1" ]; then echo "  [dry-run] $*"; else eval "$@"; fi
}
ok()   { printf "  ✅ %s\n" "$1"; }
warn() { printf "  ⚠️  %s\n" "$1"; }
ng()   { printf "  ❌ %s\n" "$1"; }
ask_yes() {  # <キー> <質問>。Enter だけなら Y。n で始まる答えのときだけ No
  # --yes のときは聞かずに Y。ただし --skip にキーがあれば No
  local key="$1" ans=""
  if [ "$YES" = "1" ]; then
    case "$SKIP" in
      *",$key,"*) printf "  %s → n（--skip）\n" "$2"; return 1 ;;
      *)          printf "  %s → Y（--yes）\n" "$2"; return 0 ;;
    esac
  fi
  printf "  %s [Y/n]（Enter で Y）: " "$2"
  read -r ans </dev/tty || ans=""
  [[ ! "$ans" =~ ^[Nn] ]]
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$REPO_ROOT/scripts"
echo "=== 個人の Mac のセットアップ ==="
echo "リポジトリ: $REPO_ROOT"
[ "$DRY" = "1" ] && echo "（dry-run: 実際の変更は行いません）"
if [ "$YES" = "1" ]; then
  echo "質問せずに進めます（--yes）。n にするもの: ${SKIP//,/ }"
else
  echo "途中の質問は Enter だけで既定の答え（[Y/n] の大文字）になります。"
fi
echo

# --- 0. 前提チェック ---
echo "▶ 前提チェック"
if id -Gn | grep -qw admin; then
  ok "管理者権限あり（admin グループに所属）"
else
  ng "管理者権限がありません。Homebrew が /opt/homebrew に入れられないため先に進めません"
  exit 1
fi
if xcode-select -p >/dev/null 2>&1; then
  ok "Command Line Tools 導入済み"
else
  ng "Command Line Tools が未導入です。xcode-select --install を実行し、終わってから再実行してください"
  exit 1
fi
echo

# --- 1. Homebrew ---
echo "▶ Homebrew"
if command -v brew >/dev/null 2>&1; then
  ok "導入済み（$(brew --version | head -1)）"
else
  echo "   この後 Password を聞かれます。Mac のログインパスワードです（画面には表示されません）。"
  run '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    run "echo 'eval \"\$(/opt/homebrew/bin/brew shellenv)\"' >> \"$HOME/.zprofile\""
    ok ".zprofile に PATH を追記"
  fi
  run 'eval "$(/opt/homebrew/bin/brew shellenv)"'
fi
echo

# --- 2. アプリ・ツール（説明つきの一覧から選ぶ）---
# Brewfile の各行の「# 」以降を説明として表示する。全部入れるか聞き、n なら1つずつ聞く。
echo "▶ アプリ・ツール（Brewfile）"
BREWFILE="$SCRIPTS/Brewfile"
entries=()
while IFS= read -r line; do entries+=("$line"); done < <(grep -E '^(brew|cask|vscode|mas) ' "$BREWFILE")
appname() { printf '%s' "$1" | sed -E 's/^[a-z]+ "([^"]+)".*/\1/'; }
label() {  # Brewfile の1行から「名前 … 説明」を作る
  local desc
  desc="$(printf '%s' "$1" | sed -nE 's/.*# *(.*)$/\1/p')"
  printf '%s … %s' "$(appname "$1")" "${desc:-（説明なし）}"
}
echo "  入れられるもの（${#entries[@]} 個）:"
for e in "${entries[@]}"; do echo "    - $(label "$e")"; done
SELECTED="$(mktemp)"
if [ "$YES" != "1" ] && ask_yes apps-all "全部入れますか？（n にすると1つずつ選べます）"; then
  printf '%s\n' "${entries[@]}" > "$SELECTED"
else
  for e in "${entries[@]}"; do
    ask_yes "$(appname "$e")" "$(label "$e")" && printf '%s\n' "$e" >> "$SELECTED"
  done
fi
n="$(grep -c . "$SELECTED" 2>/dev/null)"; n="${n:-0}"
if [ "$n" = "0" ]; then
  echo "  ・ 何も選ばれなかったのでスキップしました"
else
  echo "  ${n} 個を入れます。既に入っているものは失敗しますが、スキップして最後まで続きます。"
  grep -q '^mas ' "$SELECTED" && echo "  ※ Mac App Store のアプリ（mas）は、App Store にサインインしていないと入りません"
  run "brew bundle --file=\"$SELECTED\""
fi
rm -f "$SELECTED"
echo

# --- 3. DerivedData の定期削除 ---
echo "▶ Xcode のビルドの生成物（DerivedData）の定期削除"
echo "  毎週月曜 11:00 に、7日より古いものを自動で消します（macOS の launchd に登録。止めることもできる）。"
if ask_yes derived-data "定期削除を入れますか？"; then
  if [ "$DRY" = "1" ]; then bash "$SCRIPTS/install-derived-data-cleaner.sh" --dry-run; else bash "$SCRIPTS/install-derived-data-cleaner.sh"; fi
else
  echo "  ・ 入れませんでした（あとで: bash scripts/install-derived-data-cleaner.sh）"
fi
echo

# --- 4. GitHub・git ---
echo "▶ GitHub へのログインと git の設定"
if ! command -v gh >/dev/null 2>&1; then
  warn "gh が入っていないためスキップ（Brewfile で gh を選んでから再実行）"
elif ! gh auth status >/dev/null 2>&1; then
  warn "GitHub にログインしていません。ターミナルで次を実行してから、このスクリプトを再実行してください:"
  echo "       gh auth login     # GitHub.com → HTTPS → Y → Login with a web browser"
else
  login="$(gh api user --jq .login)"; uid="$(gh api user --jq .id)"
  ok "GitHub にログイン済み（${login}）"
  # コミットに本当のメールアドレスを出さないよう、GitHub の非公開アドレスを使う
  if [ -z "$(git config --global user.email)" ]; then
    run "git config --global user.name \"$login\""
    run "git config --global user.email \"${uid}+${login}@users.noreply.github.com\""
    ok "git の名前とメールアドレスを設定（${login} / GitHub の非公開アドレス）"
  else
    ok "git のメールアドレスは設定済み（$(git config --global user.email)）"
  fi
  KEY="$HOME/.ssh/id_ed25519"
  if [ -f "$KEY" ]; then
    ok "SSH 鍵あり（${KEY}）"
  elif ask_yes ssh-key "SSH 鍵を作って GitHub に登録しますか？（HTTPS だけで使うなら不要）"; then
    run "mkdir -p \"$HOME/.ssh\" && ssh-keygen -t ed25519 -N '' -C \"${login}@$(scutil --get ComputerName 2>/dev/null)\" -f \"$KEY\" -q"
    run "gh ssh-key add \"$KEY.pub\" --title \"$(scutil --get ComputerName 2>/dev/null)\"" \
      || warn "登録できませんでした（権限が足りない場合: gh auth refresh -s admin:public_key のあと再実行）"
  fi
fi
echo

# --- 5. スキル（claude-skills）---
# 個人のスキルは別のリポジトリ（非公開）に置き、~/.claude/skills からリンクする。
echo "▶ Claude Code のスキル（${SKILLS_REPO}）"
if ! gh auth status >/dev/null 2>&1; then
  warn "GitHub にログインしていないためスキップ（手順 4 のあとで再実行）"
elif ask_yes skills "スキル集を clone して、使うスキルをリンクしますか？"; then
  if [ -d "$SKILLS_DIR/.git" ]; then
    run "git -C \"$SKILLS_DIR\" pull -q --ff-only" && ok "最新にしました: $SKILLS_DIR"
  else
    run "mkdir -p \"$(dirname "$SKILLS_DIR")\" && gh repo clone \"$SKILLS_REPO\" \"$SKILLS_DIR\" -- -q" && ok "clone しました: $SKILLS_DIR"
  fi
  run "mkdir -p \"$HOME/.claude/skills\""
  for d in "$SKILLS_DIR"/*/; do
    [ -f "$d/SKILL.md" ] || continue
    name="$(basename "$d")"; target="$HOME/.claude/skills/$name"
    desc="$(sed -nE 's/^description: *(.*)$/\1/p' "$d/SKILL.md" | head -1 | cut -c1-60)"
    if [ -L "$target" ]; then ok "$name （リンク済み）"; continue; fi
    if [ -e "$target" ]; then warn "$name は実体が存在します。中身を確認してから手で置き換えてください"; continue; fi
    if ask_yes "$name" "${name} をリンクしますか？ … ${desc}"; then
      run "ln -s \"${d%/}\" \"$target\"" && ok "$name をリンク"
    fi
  done
fi
echo

# --- 6. 残りの案内 ---
cat <<NEXT
────────────────────────────────────────
ここまでで Homebrew・アプリ・GitHub・スキルが入りました。
残りは次の順に進めてください。
────────────────────────────────────────

1. macOS の設定（実行前にシステム設定アプリを閉じる）
     bash $SCRIPTS/apply-macos-settings.sh

2. ★ Mac を再起動
     トラックパッドとキーリピート・ファンクションキーは再起動（再ログイン）まで反映されない

3. 手作業の設定
     $SCRIPTS/manual-settings.md

4. Xcode（最新の正式版）
     brew install aria2 && xcodes install --latest --select; brew uninstall aria2
       ※ Apple ID を聞かれる。aria2 はダウンロードを速くするためだけに一時的に入れて、終わったら消す

5. Flutter（Xcode と Android Studio を入れてから）
     Claude Code で「Flutter の環境構築」と頼む（claude-skills のスキルを使う）

6. Dock を並べる（Xcode などを全部入れ終わってから）
     bash $SCRIPTS/arrange-dock.sh --dry-run   # 並ぶ予定を確認
     bash $SCRIPTS/arrange-dock.sh

7. Claude Code
     ログイン後、/mcp で再認証する。claude.ai 側のコネクタはつなぎ直し不要

8. 終わったら、このリポジトリは消してよい（スキルは claude-skills の方にある）
     rm -rf $REPO_ROOT

────────────────────────────────────────
迷ったら Claude Code に続きを任せられます。
     cd $REPO_ROOT && claude
   起動したら「mac-setup の続きをやって」と頼む。
────────────────────────────────────────
NEXT
