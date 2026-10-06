# mac-setup

新しい Mac の設定を、対話式のスクリプトでまとめて適用する。

```bash
bash scripts/apply-macos-settings.sh --dry-run   # 何が適用されるか確認
bash scripts/apply-macos-settings.sh             # 項目ごとに y/N で選ぶ
bash scripts/apply-macos-settings.sh --all       # すべて適用
```

**検証環境: macOS 26.2（Tahoe）**

---

## 何をするもの

`defaults` コマンドで設定できる項目を30件、対話で選んで適用する。

| カテゴリ | 項目数 | 例 |
|---|---|---|
| Finder | 8 | パスバー・隠しファイル・拡張子・リスト表示 |
| Dock | 7 | 自動非表示・サイズ・表示遅延・最小化エフェクト |
| キーボード | 6 | キーリピート最速化・Caps Lock の英字かな切替・F1/F2 |
| スクリーンショット | 3 | 保存先・影の除去・JPG 化 |
| トラックパッド | 2 | タップでクリック・三本指ドラッグ |
| 日本語入力 | 1 | ライブ変換 OFF ＋ Windows風のキー操作 ON |
| その他 | 3 | ダークモード・操作スペースの自動並べ替え・zsh プロンプト |

GUI でしか設定できないものは `scripts/manual-settings.md` に手順がある。
全項目の背景と `defaults` の確度評価は `references/macos-settings.md`。

## 反映のタイミングが項目で違う

**ここが一番ハマる。** 設定直後に効いていなくても失敗ではない。

| 反映 | 項目 |
|---|---|
| 即座 | Finder / Dock / スクリーンショット / Caps Lock の英字切替 / 日本語入力 |
| 再ログイン後 | キーリピート / F1・F2 |
| **再起動後** | **トラックパッド（タップでクリック・三本指ドラッグ）** |

> **実行前にシステム設定アプリを閉じること。** 開いたままだと、アプリの終了時に
> 古い値で plist が上書きされる。

## 実機で確かめたこと（macOS 26.2）

ネット上のコマンドをそのまま載せず、動くかどうかを確認した結果を載せている。

- **トラックパッドは `defaults` で設定できる。ただし `killall` では反映されない。**
  3ドメインに書き込んだうえで `killall SystemUIServer` / `killall cfprefsd` /
  システム設定を閉じての書き直しを試したが、いずれも値は変わるのに挙動は変わらなかった。
  **再起動を挟むと反映された**（再起動とログアウトのどちらが必須かは切り分けていない）
- **Caps Lock の英字かな切替は `NSGlobalDomain TISRomanSwitchState`。**
  `com.apple.HIToolbox` ではない。GUI の ON/OFF 前後で `defaults read` の全ドメイン
  差分を取って特定した（42行の差分のうち、設定キーの変化はこの1件のみ）
- **日本語入力は `com.apple.inputmethod.Kotoeri` の3キー**（`JIMPrefLiveConversionKey` /
  `JIMPrefWindowsModeKey` / `JIMPrefAutocorrectionKey`）。こちらは再起動不要で反映される
- **Dock のアプリ構成は `defaults` だけで設定できる。** `dockutil` は要らない。
  `persistent-apps` は入れ子の配列だが `-array-add` で追加でき、`_CFURLStringType` に
  `0` を渡せば macOS 側が `file://` 形式へ正規化する
- **ターミナルのタイトルバーの一部は AppleScript では制御できない。**
  `title displays ...` の5プロパティをすべて反転しても、「作業ディレクトリ」と
  「動作中のプロセス名」（`ShowRepresentedURLInTitle` / `ShowActiveProcessInTitle`）は
  動かなかった。この2つは `defaults` で書くしかなく、Terminal 起動中は反映されない

## GUI にしかない設定のキーを自分で調べる方法

上記のキーはこの方法で特定した。**どの macOS バージョンでも通用する。**

```bash
defaults read > ~/Desktop/before.txt     # 1. 変更前のスナップショット
# 2. システム設定を開いて、目的の項目を GUI で変更する
defaults read > ~/Desktop/after.txt      # 3. 変更後のスナップショット
diff ~/Desktop/before.txt ~/Desktop/after.txt   # 4. 差分 = 正解のキー
```

タイムスタンプやカウンタ（`_DKThrottledActivity` / `TRIGGER_TYPE_*` など）がノイズとして
混ざるので、それを除けば残るのは1〜2件になる。

## ファイル

| | |
|---|---|
| `scripts/apply-macos-settings.sh` | 設定の適用（対話／`--all`／`--dry-run`） |
| `scripts/manual-settings.md` | GUI でしか設定できないものの手順 |
| `scripts/Brewfile` | 開発ツールの一覧（`brew bundle --file=scripts/Brewfile`） |
| `references/macos-settings.md` | 全項目の背景・GUI 手順・`defaults` の確度評価・zsh プロンプト |

## zsh プロンプト

`apply-macos-settings.sh` の最後の項目で `~/.zshrc` に追記される。

```
my-project % ls
── 2026-10-06 13:21:22        ← コマンドを実行した時刻（preexec で出す）
agents  docs  skills  ...
                               ← 出力の後に空行が入り、前の結果と混ざらない
my-project %
```

ユーザー名とホスト名を消しているので、**スクショを貼るときにマスキングが要らない**。
カレントパスのフルパスはタイトルバーに出す（GUI 設定ではなくエスケープシーケンスで
書いているため、iTerm2 など他のターミナルでも効く）。

## 注意

- `defaults write` は**すべてを実機検証したわけではない**。`references/macos-settings.md` に
  ✅（定番キー）/ ⚠️（条件付き）/ ❓（未検証・GUI 推奨）の3段階で確度を記載している
- `Brewfile` は個人の用途（iOS / Android アプリ開発）に寄っている。そのまま使わず中身を見て選ぶこと
