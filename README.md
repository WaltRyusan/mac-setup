# mac-setup

個人の Mac を新しくしたときのセットアップ。**新しい Mac のターミナルに、次の1行を貼るところから始める。**

```bash
curl -fsSL https://raw.githubusercontent.com/WaltRyusan/mac-setup/main/install.sh | bash
```

**先に clone しておく必要はない。** この1行は、`install.sh` を GitHub から読み込んで（ファイルとしては保存せずに）その場で実行する。
`install.sh` がやるのは次の3つで、そのあとは clone したリポジトリの `scripts/bootstrap.sh` に引き継ぐ。

1. Command Line Tools を入れる（git が使えるようになる。出てきたウインドウで「インストール」を押す）
2. このリポジトリを `~/Documents/personal/mac-setup` に clone する（公開リポジトリなので、GitHub へのログインは要らない）
3. `scripts/bootstrap.sh` を実行する → アプリの一括インストール → GitHub へのログイン → スキルの用意

質問はすべて `[Y/n]` の形で、**Enter だけなら大文字の既定の答え**になる。最後に、残りの手順が表示される。

> **もう clone してある場合**は、`bash install.sh`（最新にしてから続ける）か `bash scripts/bootstrap.sh` でよい。
> clone 先は `MAC_SETUP_DIR` で変えられる（例: `curl … | MAC_SETUP_DIR=~/mac-setup bash`）。
> 何をするか先に見たいときは `… | bash -s -- --dry-run`。**ただし `--dry-run` が効くのは bootstrap から先だけで、
> 1・2（Command Line Tools と clone）は実際に行われる。**
> セットアップが終わったら、このリポジトリは手元から消してよい（スキルは別のリポジトリ `claude-skills` にある）。

---

## 全体の流れ

| | 手順 | どこでやるか |
|---|---|---|
| 1 | Command Line Tools・clone | `install.sh`（README の1行） |
| 2 | Homebrew・アプリ（一覧から選ぶ）・DerivedData の定期削除 | `scripts/bootstrap.sh`（1 から続けて動く） |
| 3 | GitHub へのログイン・git の名前とメールアドレス・SSH 鍵 | 同上。`gh auth login` だけはブラウザでの操作が要る（ログインしていなければ案内が出るので、ログイン後にもう一度実行） |
| 4 | スキル（`WaltRyusan/claude-skills`）の clone と、使うスキルのリンク | 同上 |
| 5 | macOS の設定 | `scripts/apply-macos-settings.sh`（36項目。実行前にシステム設定アプリを閉じる） |
| 6 | **再起動** | トラックパッド・キーリピート・ファンクションキーは再起動（再ログイン）まで反映されない |
| 7 | 手作業の設定 | `scripts/manual-settings.md`（Finder のサイドバー・Spotlight・Chrome のタブ・Clipy・ターミナルのタイトル） |
| 8 | Xcode（最新の正式版）・Flutter | `bootstrap.sh` の最後の案内に従う |
| 9 | Dock を並べる | `scripts/arrange-dock.sh`（**Xcode などを全部入れ終わってから**。入っていないアプリは飛ばす） |

## Claude Code から進めるとき

Claude Code のコマンド実行ではキーボードの入力を渡せないので、質問のあるスクリプトをそのまま動かすと、すべて既定の答えで進んでしまう。
**質問は Claude Code が会話で聞き、その答えをオプションで渡す。**

```bash
bash scripts/bootstrap.sh --yes --skip charles,derived-data   # アプリは Brewfile の名前、手順は derived-data / ssh-key / skills
bash scripts/apply-macos-settings.sh --list                    # 番号つきの一覧を見る（何も変えない）
bash scripts/apply-macos-settings.sh --yes --skip 3,12 --with 17   # 3・12 番を外し、既定が N の 17 番を入れる
```

パスワードやブラウザが要るもの（Homebrew の初回インストール・`gh auth login`・`xcodes install`）は、ターミナルで直接打つ。

## 入っているもの

| ファイル | 中身 |
|---|---|
| `install.sh` | 入口。Command Line Tools を入れ、このリポジトリを clone して `bootstrap.sh` に渡す |
| `scripts/bootstrap.sh` | Homebrew・アプリ・定期削除・GitHub・git・SSH 鍵・スキル |
| `scripts/Brewfile` | 入れるアプリの一覧。行末のコメントが、選ぶときに表示される説明 |
| `scripts/apply-macos-settings.sh` | macOS の設定（36項目。Dock・Finder・キーボード・日本語入力・トラックパッド・Spotlight・ターミナル・zsh） |
| `scripts/arrange-dock.sh` | Dock に並べるアプリの設定 |
| `scripts/install-derived-data-cleaner.sh` | Xcode の DerivedData の定期削除（launchd に登録。`--uninstall` で止める） |
| `scripts/manual-settings.md` | GUI でしかできない設定の手順 |
| `references/macos-settings.md` | 各設定の背景・`defaults` のキー・確度・実機で確かめたこと |

## 反映のタイミングが項目で違う

**ここが一番ハマる。** 設定した直後に効いていなくても失敗ではない。

| 反映 | 項目 |
|---|---|
| 即座 | Finder / Dock / スクリーンショット / Caps Lock の英字切替 / 日本語入力 |
| 再ログイン後 | キーリピート / F1・F2 |
| **再起動後** | **トラックパッド（タップでクリック・三本指ドラッグ・軌跡の速さ）** |

> **実行前にシステム設定アプリを閉じること。** 開いたままだと、アプリを閉じたときに古い値で上書きされる。

## 実機で確かめたこと（macOS 26）

ネット上のコマンドをそのまま載せず、動くかどうかを確かめた結果を載せている。詳しくは `references/macos-settings.md`。

- **トラックパッドは `defaults` で設定できるが、`killall` では反映されない。** 再起動を挟むと反映された
- **Caps Lock の英字かな切替は `NSGlobalDomain TISRomanSwitchState`**（`com.apple.HIToolbox` ではない）。GUI の切り替え前後の差分で特定した
- **日本語入力は `com.apple.inputmethod.Kotoeri` のキー**。「／」キーで入力する文字は `JIMPrefCharacterForSlashKey`（`0` = `/`、`1` = `・`）
- **キーリピートの GUI の最速は `KeyRepeat 2` / `InitialKeyRepeat 15`**。トラックパッドの軌跡の速さは GUI の最大が `3` で、コマンドなら `6` まで上げられた（再起動後に効く）
- **F1・F2 を標準のファンクションキーにするのは `com.apple.keyboard.fnState true`**（`false` が既定で、F1 で明るさが変わる）
- **Dock のアプリの並びは `defaults` だけで設定できる。** `dockutil` は要らない
- **「アプリを切り替えたときに操作スペースへ移動しない」（`AppleSpacesSwitchOnActivate false`）は入れていない。** Cmd+Tab で別の操作スペースのアプリへ切り替えられなくなるため
- **メニューバーに Bluetooth を出すのは `-currentHost com.apple.controlcenter Bluetooth 2`**（8 で外れる）。`killall ControlCenter` で反映される
- **ターミナルのタイトルの「大きさ」は AppleScript で外せる。** 「作業ディレクトリまたは書類」は、`defaults` で書いても起動中のターミナルに上書きされるため GUI で外す
