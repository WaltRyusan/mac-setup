# Mac 推奨設定（モバイルアプリ開発向け）

対象：macOS 26（Tahoe）以上、Xcode + Android Studio を使うモバイル開発者。

---

# ⚠ 最初に読んでください：`defaults` コマンドの信頼性について

このドキュメントには `defaults write` コマンドが多数出てきますが、**すべてを実機で検証したわけではありません。**
以下の確度で分けて記載しています。

## 確度の3段階

| 記号 | 意味 |
|---|---|
| ✅ | **定番キー**。10年以上変わっておらず、dotfiles コミュニティで広く使われている。まず問題ない |
| ⚠️ | **動くが条件付き**。再ログインが必要、または環境によって効かない報告がある |
| ❓ | **macOS 26 での挙動は未検証**。GUI での設定を推奨 |

## ⚠ 重要：トラックパッドは「書けるが、再起動するまで効かない」

**`defaults` で設定できます。ただし `killall` では反映されず、再起動が必要でした（2026-10 / macOS 26.2 実測）。**

ここを誤解すると「スクリプトを流したのに効かない」と見えるので、先に書いておきます。

| 試したこと | 結果 |
|---|---|
| 3ドメインすべてに `false` を書き込み<br>（`com.apple.AppleMultitouchTrackpad` / `com.apple.driver.AppleBluetoothMultitouch.trackpad` / `NSGlobalDomain com.apple.mouse.tapBehavior`） | 値は書き換わる（`defaults read` で `0`） |
| `killall SystemUIServer` | 挙動は変わらず |
| `killall cfprefsd`（設定キャッシュの再起動） | 挙動は変わらず |
| システム設定アプリを**閉じた状態**で書き直し | 挙動は変わらず |
| **再起動（再ログインを含む）** | **反映された。タップでクリック・三本指ドラッグとも無効になった** |

**つまり `killall` では足りず、再起動を挟めば効きます。**
再起動とログアウトのどちらが必須かは**切り分けできていません**
（再起動時に自動でログアウトされたため、両方を同時に通っています）。
実用上は「再起動を挟む」と覚えておけば足ります。

同じ `killall` 方式でも **Dock（`com.apple.dock`）は即座に反映される**ことは確認済み。
ドメインが1つで済み、`killall Dock` が効くため。トラックパッドは書き込み先が複数あり、
ドライバ層が絡むことが違いと思われる（これは推測）。

**→ トラックパッド系は `apply-macos-settings.sh` で設定できる。再起動後に反映される。**

## 共通の注意点

1. **システム設定アプリを閉じてから実行する。** 開いたままだと、アプリ終了時に古い値で上書きされます
2. **多くは再ログインまたは再起動が必要**です。`killall` で済むのは Finder / Dock / SystemUIServer 系のみ
3. macOS は設定値を `cfprefsd` がキャッシュするため、**即座に反映されないことがあります**

---

## 🔍 自分の Mac で正解を確かめる方法（これが最も確実）

コマンドが正しいか調べる決定版の方法です。**どの macOS バージョンでも通用します。**

```bash
# 1. 変更前のスナップショットを取る
defaults read > ~/Desktop/defaults-before.txt

# 2. システム設定を開いて、目的の項目を GUI で手動変更する

# 3. 変更後のスナップショットを取る
defaults read > ~/Desktop/defaults-after.txt

# 4. 差分を見る = これが正解のキー
diff ~/Desktop/defaults-before.txt ~/Desktop/defaults-after.txt
```

差分に出てきた `domain` と `key` が、そのマシンでの正解です。

**個別に値を確認する場合**

```bash
defaults read com.apple.finder ShowPathbar        # 現在値
defaults read NSGlobalDomain KeyRepeat
defaults read com.apple.dock mru-spaces
```

キーが存在しない場合は `does not exist` と返ります（＝デフォルト値のまま）。

**元に戻す場合**

```bash
defaults delete com.apple.finder ShowPathbar      # キーを削除してデフォルトに戻す
```

> **記事にする場合は、この検証方法自体を載せると価値が高い**と思います。
> 「コマンドを鵜呑みにせず、自分の環境で確かめる方法」は応用が利きます。

---

# A. スクリーンショット

## A-1. 保存先をデスクトップ以外に変更 ✅

**課題**：デフォルトはデスクトップ。散らかるのが嫌な人向け。

**GUI**
1. `⌘ + Shift + 5` でツールバーを表示
2. 「オプション」→「保存先」→「その他の場所…」
3. `~/Pictures/Screenshots` などを指定

**コマンド** ✅
```bash
mkdir -p ~/Pictures/Screenshots
defaults write com.apple.screencapture location ~/Pictures/Screenshots
killall SystemUIServer
```

## A-2. 影をなくす・JPG化 ✅

```bash
defaults write com.apple.screencapture disable-shadow -bool true   # 影（余白）をなくす
defaults write com.apple.screencapture type jpg                    # ドキュメントへの貼り付けが軽くなる
killall SystemUIServer
```

---

# B. 操作スペース（Mission Control）

## B-1. 自動並べ替えをやめる ✅

**課題**：左から Xcode / Android Studio / Slack / Chrome と位置を決めて使いたいのに、
Slack を使うと Slack のスペースが一番左に移動してしまう。
iOS/Android を並行で触ると 4枚以上になるので効きが大きい。

**GUI**
1. システム設定 →「デスクトップとDock」
2. 下にスクロールして **Mission Control** セクション
3. **「最新の使用状況に基づいて操作スペースを自動的に並べ替える」を OFF**

**コマンド** ✅
```bash
defaults write com.apple.dock mru-spaces -bool false
killall Dock
```

**関連**
- 操作スペースの移動は `Ctrl + ←/→`
- 番号直打ち（`Ctrl + 1/2/3`）は、システム設定 → キーボード → キーボードショートカット → Mission Control で有効化が必要
- マルチディスプレイの人は「ディスプレイごとに個別の操作スペース」も要確認

---

# C. キーボード・日本語入力

## C-1. Caps Lock の再割り当て（4つの選択肢）

Caps Lock はホームポジションの左隣という最高の位置にありながら、
デフォルトでは「大文字固定」というほぼ使わない機能が割り当たっています。
**何に割り当てるかは人によって違う**ので、選択肢を並べます。

### 選択肢A：英字/かな 切り替え ✅（★おすすめ）

日本語を書く量が多い人はこちら。**USキーボードだと `英数`/`かな` キーが無いので実質必須。**

**コマンド** ✅（2026-10 / macOS 26.2 実測。即座に反映される）
```bash
defaults write NSGlobalDomain TISRomanSwitchState -bool true
```

**GUI**
1. システム設定 → **キーボード** → 「入力ソース」の **「編集…」**
2. 左で **「すべての入力ソース」** を選択
3. **「Caps Lock キーで ABC 入力モードと切り替える」** を ON

- Karabiner-Elements は不要（macOS Catalina 以降の標準機能）
- **本来の Caps Lock（大文字固定）は `Shift + Caps Lock`** で使えます。機能は失われません
- ⚠ この設定は「**修飾キー**」の画面ではなく「**入力ソース**」側にあるので見つけにくい
- ⚠ ドメインは `com.apple.HIToolbox` ではなく **`NSGlobalDomain`**。GUI の ON/OFF 前後で
  `defaults read` の全ドメイン差分を取って特定した（変化したのはこのキーのみ）

### 選択肢B：Control に変更 ❓GUI推奨

ターミナル操作（`^C` `^R` `^A` `^E`）が小指ひとつで打てます。

- システム設定 → キーボード → 「キーボードショートカット…」→ **修飾キー** → Caps Lock を `⌃ Control` に

### 選択肢C：Escape に変更 ❓GUI推奨

Vim / Xcode の Vim モードを使う人向け。上記と同じ画面で `⎋ Escape` を選択。

### 選択肢D：Karabiner-Elements で「単押し＝IME切替、長押し＝Control」

両取りしたい人向け。ただしアプリ導入＋入力監視の権限許可が必要なので、
**まず標準機能（A〜C）で試すのを推奨**します。

## C-2. ライブ変換 OFF ＋ Windows風のキー操作 ON ✅

**この2つはセットで考える必要があります。**

- **Windows風のキー操作を ON** にすると **Enter 1回で変換を確定**できる
- ただし **ライブ変換が ON のままだとこれが機能しない**
- → **ライブ変換 OFF ＋ Windows風のキー操作 ON** が、Windows から来た人にしっくりくる組み合わせ

**コマンド** ✅（2026-10 / macOS 26.2 実測。再起動なしで反映される）
```bash
defaults write com.apple.inputmethod.Kotoeri JIMPrefLiveConversionKey -bool false  # ライブ変換 OFF
defaults write com.apple.inputmethod.Kotoeri JIMPrefWindowsModeKey    -bool true   # Windows風のキー操作 ON
defaults write com.apple.inputmethod.Kotoeri JIMPrefAutocorrectionKey -bool false  # タイプミスを修正 OFF
```

**GUI**
1. システム設定 → **キーボード** → 「入力ソース」の **「編集…」**
2. 左で **日本語** を選択
3. **ライブ変換** を OFF、**Windows風のキー操作** を ON
4. 「タイプミスを修正」も、意図と違う変換をされるので OFF 推奨
5. **「¥キーで入力する文字」→ `\`（バックスラッシュ）** にしておくと開発時に楽

> `¥` キーの設定は `JIMPrefCharacterForSlashKey`（実機では `1`）だが、
> どの値がどちらに対応するかは**未確認**。GUI で設定するのが確実。
> 日本語入力のプロセスは `JapaneseIM-RomajiTyping`。ただし `.appex` として動いているため
> **`killall` では名前が一致せず再起動できない**（上記の3項目は `killall` 不要で反映される）。

## C-3. スマート引用符とスマートダッシュを OFF ✅（★開発者は必須）

**`--` が `—` に、`"` が `"` に化けます。** コマンドやコードをメモ経由で貼ると壊れるので必須です。

**GUI**：システム設定 → キーボード → 入力ソースの「編集…」→ すべての入力ソース →
**「スマート引用符とスマートダッシュを使用」のチェックを外す**

**コマンド** ✅
```bash
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
```

## C-4. キーリピート最速化 ✅

**体感で一番効きます。** ターミナル・エディタでのカーソル移動が別物になります。

```bash
defaults write NSGlobalDomain KeyRepeat -int 1           # リピート速度（最速）
defaults write NSGlobalDomain InitialKeyRepeat -int 10   # リピート開始までの時間（最短）
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false   # 長押しのアクセント入力を無効化
```

⚠️ **再ログインが必要です。** また、GUI のスライダーより小さい値を設定できます。

## C-5. F1・F2 を標準ファンクションキーとして使用 → OFF ⚠️

OFF（デフォルト）にしておくと **`F10` 単体で「半角英数変換」** が使えます。
ON にすると `fn + F10` が必要になります。
画面の明るさや音量より、**日本語入力中の変換（F7 カタカナ / F10 半角英数）の方が使用頻度が高い**ため OFF 推奨。

**GUI**：システム設定 → キーボード → 「F1、F2などのキーを標準のファンクションキーとして使用」を OFF

**コマンド** ⚠️（再ログインが必要。外付けキーボードは個別設定になる場合あり）
```bash
defaults write NSGlobalDomain com.apple.keyboard.fnState -bool false
```

---

# D. トラックパッド ⚠️ 要再起動

**`defaults` で設定できますが、`killall` では反映されません。再起動が必要です。**
詳しい実測結果は冒頭の「トラックパッドは『書けるが、再起動するまで効かない』」を参照。

## D-1. タップでクリック ⚠️（要再起動）

1. システム設定 → **トラックパッド** → 「ポイントとクリック」タブ
2. **「タップでクリック」を ON**

あわせて「軌跡の速さ」を右寄りに（デフォルトは遅い）。

**コマンド** ⚠️（**再起動するまで反映されません。** `killall` では不十分）
```bash
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
```

## D-2. 三本指でのドラッグ ⚠️（要再起動）

トラックパッドを押し込まずに、三本指でなぞるだけでドラッグできます。

**コマンド** ⚠️（**要再起動**。D-1 と同じ挙動）
```bash
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
```

**GUI**
1. システム設定 → **アクセシビリティ**
2. **ポインタコントロール** → 「トラックパッドオプション…」
3. 「ドラッグにトラックパッドを使用」を ON
4. 方法を **「3本指のドラッグ」** に変更

⚠ **GUI は「トラックパッド」設定の中ではなくアクセシビリティ配下**にあるので見つけにくい。
⚠ 「調べる＆データ検出」を3本指タップにしていると競合するので、どちらかを変更する。

> **確度について。** 無効化（`false`）が再起動後に反映されることは実測で確認しました。
> 有効化（`true`）が同じく反映されるかは**未確認**です（検証時は無効方向でしか試していない）。
> 同じキーなので反映されると考えていますが、これは推測です。

---

# E. Finder

## E-1. パスバーを表示 ✅（必須）

- Finder →「表示」メニュー → **「パスバーを表示」**（`⌥ + ⌘ + P`）
- ウインドウ下部に現在の階層がパンくずで出る

**地味に強い使い方**
- パスバーのフォルダをダブルクリックでその階層にジャンプ
- **ターミナルにドラッグ&ドロップするとフルパスが入力される**（`cd ` と打ってから放り込むのが定番）
- 右クリック →「"○○"をコピー」でパスをコピー

あわせて **ステータスバー**（`⌘ + /`）も出すと、項目数と空き容量が常に見えます。

**コマンド** ✅
```bash
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
killall Finder
```

## E-2. 隠しファイルを表示 ✅（必須）

- **`⌘ + Shift + .`** でトグル（ショートカット1つ覚えるだけ。これが一番手軽）

モバイル開発では隠しファイルだらけなので実質必須です。
`.gitignore` `.git/` `.env` `.claude/` `.xcconfig` `.swiftlint.yml` `.gradle` `.idea/` `local.properties` など。

**常時表示に固定する場合** ✅
```bash
defaults write com.apple.finder AppleShowAllFiles -bool true
killall Finder
```

## E-3. デフォルトをリスト表示にする ✅

アイコン表示だと**ファイルサイズと更新日時が一目で分からない**ので、リスト表示が便利です。

```bash
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
killall Finder
```

値：`Nlsv` リスト / `icnv` アイコン / `clmv` カラム / `Flwv` ギャラリー

⚠ **GUI で設定する場合の罠**：**最上層（「自分のPC」やハードディスク）を開いた状態で設定しないと、
下層フォルダに反映されません。** 上のコマンドを使えばこの問題は起きません。

## E-4. その他 ✅

```bash
defaults write NSGlobalDomain AppleShowAllExtensions -bool true              # 拡張子を常に表示
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"          # 検索を現在のフォルダ内に
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false   # 拡張子変更の警告を無効化
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true # ネットワークドライブに .DS_Store を作らない
killall Finder
```

## E-5. サイドバーの整理 ❓GUI必須

Finder → **設定** → **サイドバー** タブ

最低限チェックしておきたいもの：
- **ユーザー名（ホームフォルダ）** ← デフォルトでは出ていない
- **ハードディスク**
- よく使う作業フォルダ（`⌘ + Ctrl + T` で任意のフォルダを追加）

⚠ **「ハードディスク」はチェックを入れても出ないことがあります。** 一度外して入れ直すと表示されます。

---

# F. Dock ✅

```bash
defaults write com.apple.dock autohide -bool true                  # 自動的に非表示
defaults write com.apple.dock autohide-delay -float 0              # 表示までの遅延ゼロ
defaults write com.apple.dock autohide-time-modifier -float 0.15   # アニメーションを速く
defaults write com.apple.dock show-recents -bool false             # 最近使ったアプリを表示しない
killall Dock
```

縦の作業領域が広がるので Xcode で効きます。

---

# G. ターミナルのプロンプト設定（zsh）

コマンドの左に出る `ユーザー名@PC名` を消して、**現在地のフォルダ名だけ**にします。
**ブログや記事にスクショを貼るときにマスキングが不要になる**のが大きいです。

あわせて**コマンドを実行した時刻**を出します。何をいつ実行したかが端末に残るので、
後から経緯を追うときのログになります。

```
変更前: <ユーザー名>@<PC名> my-project % ls

変更後: my-project % ls
        ── 2026-10-06 13:21:22      ← 実行した瞬間の時刻
        agents  docs  skills  ...
                                     ← 出力の後に空行が入り、前の結果と混ざらない
        my-project %
```

フルパスが必要なときのために、**タイトルバーには絶対パスを出す**設定にします（後述）。

## ⚠ `/etc/zshrc` は編集しない

ネット記事では `sudo vim /etc/zshrc` がよく紹介されていますが、**推奨しません。**

| | `/etc/zshrc` | **`~/.zshrc`（推奨）** |
|---|---|---|
| 影響範囲 | **そのMacの全ユーザー** | 自分だけ |
| `sudo` | 必要 | **不要** |
| OSアップデート | **上書きされる可能性** | 影響なし |
| 管理された端末 | 管理ツールの構成と衝突しうる | 安全 |
| PC入れ替え | 移行が面倒 | **ファイル1つコピーで済む** |

**`~/.zshrc` に書けば `sudo` も不要で、記事にある「書き込み権限がなくて保存できない」問題も起きません。**

## 手順

```bash
echo $SHELL            # /bin/zsh であることを確認

code ~/.zshrc          # VS Code で開く（vim が苦手ならこれが早い）
# open -e ~/.zshrc     # テキストエディット
# vim ~/.zshrc         # Vim
```

ファイル末尾に追記：

```bash
# ---- プロンプト設定 ----
# ユーザー名@ホスト名を消して現在地のフォルダ名だけにする（フルパスはタイトルバーに表示）
PROMPT='%1~ %# '

# ---- コマンドを実行した時刻を出す ----
# precmd（プロンプト表示時）ではなく preexec（コマンド実行の直前）なので、
# 席を外してから打っても「実際に実行した時刻」が残る。出力との区切り線も兼ねる
function preexec_timestamp() { print -P "%F{244}── %D{%Y-%m-%d %H:%M:%S}%f" }
preexec_functions+=( preexec_timestamp )

# ---- タイトルバーにカレントパスを表示 ----
# GUI 設定に依存せず、エスケープシーケンスでシェルから直接書く
function set_terminal_title() { print -Pn "\e]0;%~\a" }
precmd_functions+=( set_terminal_title )

# ---- コマンド出力の後に改行を入れる ----
# 長いコマンドの後に空行が入り、どこからどこまでが1まとまりか分かりやすくなる
function add_newline() {
  if [[ -z "$PS1_NEWLINE_LOGIN" ]]; then
    PS1_NEWLINE_LOGIN=true
  else
    print ""
  fi
}
precmd_functions+=( add_newline )
```

```bash
source ~/.zshrc        # 反映
```

> **`PS1` でも `PROMPT` でも動きますが、zsh では `PROMPT` が本来の名前**です。
>
> ⚠ **記事にある `function precmd()` をそのまま定義すると、git ブランチ表示などと衝突します。**
> `precmd` を2回定義すると後勝ちで片方が消えるため、上記のように**関数名を変えて
> `precmd_functions` に追加**してください。

## プロンプトの記号一覧

| 記号 | 意味 | 表示例 |
|---|---|---|
| `%n` | ユーザー名 | `<ユーザー名>` |
| `%m` | ホスト名 | `MacBook-Pro` |
| `%~` | カレントディレクトリ（フルパス） | `~/Documents/work` |
| `%1~` | カレントディレクトリ（末尾1階層） | `work` |
| `%*` | 時刻（24時間） | `23:29:38` |
| `%D{%Y-%m-%d}` | 日付 | `2026-09-30` |
| `%D{%I:%M:%S %p}` | 時刻（12時間＋AM/PM） | `11:29:38 PM` |
| `%!` | コマンド履歴番号 | `1` |
| `%#` | 一般ユーザーは `%`、root は `#` | `%` |
| `$'\n'` | 改行 | |

### よく使う組み合わせ

```bash
PROMPT='%1~ %# '                          # フォルダ名のみ（★スクリプトの既定。一番すっきり）
PROMPT='%D{%Y-%m-%d %H:%M:%S} %# '        # 日時のみ
PROMPT='%D{%H:%M:%S} %1~ %# '             # 時刻＋フォルダ名
PROMPT=$'%1~\n%# '                        # フォルダ名の後で改行して入力欄を広く
```

## git のブランチ名も出す

Claude Code に作業させていると「今どのブランチか」が重要になるので、かなり便利です。

```bash
autoload -Uz vcs_info
precmd_functions+=( vcs_info )
setopt prompt_subst
zstyle ':vcs_info:git:*' formats '%b'

PROMPT='%D{%H:%M:%S} %1~ %F{green}${vcs_info_msg_0_}%f %# '
```

## ターミナルのタイトルバー表示

**プロンプトにはフォルダ名だけ、タイトルバーにはフルパス**、という分担にすると、
コマンド行がすっきりしたまま「今どこにいるか」は正確に分かる状態になります。

### 方法1：シェルから書く ✅（推奨・GUI 不要）

`~/.zshrc` に入れてある `set_terminal_title` がこれをやっています。

```bash
function set_terminal_title() { print -Pn "\e]0;%~\a" }
precmd_functions+=( set_terminal_title )
```

`\e]0;...\a` は**ウインドウタイトルを設定するエスケープシーケンス**で、
ターミナルの GUI 設定に依存しません。iTerm2 など他のターミナルでも同じように効きます。
`apply-macos-settings.sh` に含まれているので、新 Mac でも自動で再現されます。

| 書き方 | タイトルバーの表示 |
|---|---|
| `%~` | `~/Documents/work/my-project`（ホームを `~` に短縮） |
| `%/` | `/Users/<ユーザー名>/Documents/...`（完全な絶対パス） |
| `%1~` | `my-project`（末尾1階層だけ） |

### 方法2：GUI のチェックで出す

ターミナル → **設定** → **プロファイル** → **ウインドウ** タブ。

- ☑ **パス**（作業ディレクトリの絶対パス）

> ⚠ **方法1と併用すると二重に出ます。** 既定では「カレントディレクトリ」「作動中のプロセス名」
> 「ウインドウサイズ」が表示されており、方法1の値がそこに**追記される**ため、
> `my-project — ~/Documents/work/my-project — -zsh — 192×57`
> のように冗長になります（2026-10 実機確認）。方法1を使うなら、GUI 側の
> **「カレントディレクトリまたは書類」「作動中のプロセス名」「大きさ」のチェックを外す**こと。
> この GUI 設定を `defaults` で書けるかは**未検証**（`Basic` プロファイルにタイトル関連のキーは
> 保存されておらず、既定値のままだった）。

## うまく反映されないとき

| 症状 | 原因と対処 |
|---|---|
| `unmatched '` / `unmatched "` | 引用符の閉じ忘れ、または**全角クォートが混ざっている** |
| 設定が効かない | oh-my-zsh / powerlevel10k / starship が**プロンプトを上書きしている**。その場合はフレームワーク側で設定する |
| `/etc/zshrc` を編集したのに効かない | `~/.zshrc` は `/etc/zshrc` の**後に**読まれるため `~/.zshrc` が勝つ |

## PC入れ替え時

`~/.zshrc` は個人設定なので自動では移りません。

```bash
cp ~/.zshrc ~/Desktop/zshrc-backup
```

---

# H. その他

## H-1. どこでも掴んでウインドウ移動

`⌃ + ⌘` を押しながらウインドウのどこでもドラッグ。標準機能ですが意外と知られていません。

## H-2. Spotlight からビルド生成物を除外 ❓GUI必須

インデックス作成の CPU 負荷が下がり、検索結果のノイズも減ります。
**iOS/Android 両方をビルドする Mac では効果が大きい。**

システム設定 → **Spotlight** → 「検索プライバシー…」に追加：

```
~/Library/Developer/Xcode/DerivedData
~/.gradle
~/Library/Android/sdk
```

プロジェクト配下の `build/` `Pods/` `node_modules` も必要に応じて。

## H-3. 集中モード

ビルド待ちの間に Slack 通知で集中が切れるのを防ぎます。
Claude Code に長い作業を投げている間にも有効。

システム設定 → **集中モード** → 「作業」モードを作成し、許可する人/App を絞る。

## H-4. ディスク容量の見張り

Xcode / Android SDK は放置すると容量を圧迫します。

```bash
du -sh ~/Library/Developer/Xcode/DerivedData          # Xcodeのビルド生成物
du -sh ~/Library/Developer/Xcode/iOS\ DeviceSupport   # 古いiOS版（削除可）
xcrun simctl delete unavailable                       # 使われていないシミュレータを削除
du -sh ~/.gradle/caches                               # Gradle キャッシュ
brew cleanup -s                                       # Homebrew の古いキャッシュ
```

---

# 付録：一括適用スクリプト

**正本は `scripts/apply-macos-settings.sh`。** このドキュメントには中身を複製しない
（複製すると、スクリプトを直したときに追従漏れが起きるため）。

```bash
bash skills/util-mac-migration/scripts/apply-macos-settings.sh --dry-run   # 内容の確認
bash skills/util-mac-migration/scripts/apply-macos-settings.sh             # 対話で適用
bash skills/util-mac-migration/scripts/apply-macos-settings.sh --all       # すべて適用
```

**実行前にシステム設定アプリを閉じること。** 開いたままだと終了時に古い値で上書きされる。

反映のタイミングは項目によって違う。

| 反映 | 項目 |
|---|---|
| 即座 | スクリーンショット / Dock / Finder / Caps Lock の英字切替 / 日本語入力 |
| 再ログイン後 | キーリピート / F1・F2 |
| **再起動後** | **トラックパッド（タップでクリック・三本指ドラッグ）** |

GUI 操作が残るものは `scripts/manual-settings.md` を参照。
