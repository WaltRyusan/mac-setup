#!/usr/bin/env bash
# 新しい Mac で最初に実行する入口。README の1行から呼ばれる:
#   curl -fsSL https://raw.githubusercontent.com/WaltRyusan/mac-setup/main/install.sh | bash
#
# やること: Command Line Tools（git が使えるようになる）→ このリポジトリを clone（HTTPS・認証なし）→ bootstrap.sh へ
# clone 先は MAC_SETUP_DIR で変えられる（既定: ~/Documents/personal/mac-setup）。セットアップが終われば消してよい。
# 引数はそのまま bootstrap.sh に渡す（例: … | bash -s -- --dry-run）。

set -uo pipefail

REPO_URL="https://github.com/WaltRyusan/mac-setup.git"
DIR="${MAC_SETUP_DIR:-$HOME/Documents/personal/mac-setup}"

echo "=== mac-setup ==="

# 1. Command Line Tools（無いと git が使えない）
if ! xcode-select -p >/dev/null 2>&1; then
  echo "▶ Command Line Tools を入れます。出てきたウインドウで「インストール」を押してください。"
  xcode-select --install >/dev/null 2>&1 || true
  printf "  インストールが終わるのを待っています"
  until xcode-select -p >/dev/null 2>&1; do printf "."; sleep 10; done
  echo
fi
echo "  ✅ Command Line Tools"

# 2. このリポジトリ
if [ -d "$DIR/.git" ]; then
  git -C "$DIR" pull -q --ff-only && echo "  ✅ 最新にしました: $DIR"
else
  mkdir -p "$(dirname "$DIR")"
  git clone -q "$REPO_URL" "$DIR" && echo "  ✅ clone しました: $DIR" || { echo "  ❌ clone に失敗しました"; exit 1; }
fi

# 3. 続きは bootstrap.sh（質問は端末から読むので、curl | bash でも答えられる）
exec bash "$DIR/scripts/bootstrap.sh" "$@"
