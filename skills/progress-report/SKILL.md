---
name: progress-report
description: 進捗レポートの作成・更新・公開の手順。state.json を単一情報源とし、テンプレート HTML と組み合わせて共有可能なレポートを生成する。/progress-report コマンドから参照される。進捗レポートを立ち上げる・最新化する・共有用に公開するときに参照する。
---

# Progress Report

機能の進捗を「同じURLを更新し続けるWebページ」として共有するための手順。
`state.json` が単一情報源であり、`facts` キーは取得スクリプトだけが書き換える。
テンプレートHTML・取得スクリプト・データの実例は本Skillに資産として同梱する。

## 資産の所在

- `~/.claude/skills/progress-report/assets/report-template.html`
- `~/.claude/skills/progress-report/assets/fetch-facts.sh`
- `~/.claude/skills/progress-report/assets/state.example.json`
- `state.json` のスキーマ定義は `SCHEMA.md`(本Skill内)を参照する

`CLAUDE_DIR` を変更している環境では、そのディレクトリ配下の `skills/progress-report/assets/` を使う。

## 手順1: 立ち上げ(init)

1. レポート用ディレクトリを作る(既定 `.progress-report/<レポートID>/`)
2. `state.example.json` を雛形として `state.json` を書く
3. `meta.targets` に対象リポジトリと課題/PR番号を設定する
4. `parts[]` を定義し、`id` を `meta.targets[].partId` と一致させる
5. `facts` は空のまま残す(手順2で埋める)

## 手順2: 更新(update)

1. `state.json` を一時ファイル(例: `state.json.new`)にコピーする
2. 配置先の `fetch-facts.sh` を一時ファイルに対して実行し、`facts` を最新化する:
   `bash <配置先>/assets/fetch-facts.sh <一時ファイルへのパス>`
   (配置先は既定 `~/.claude/skills/progress-report/assets/`。`CLAUDE_DIR` を変更している
   環境ではその配下を使う。固定パスをそのまま書かない)
3. 一時ファイルの `facts` と元の `state.json` の差分をユーザーに提示し、承認を得る
   (承認前に元の `state.json` は書き換えない)
4. 承認後、一時ファイルを `state.json` に置き換える
5. 人が書く欄を見直す: `meta.asOf` / `headline` / `forecast` / `asks` / `watchItems`
6. `forecast` を変更した場合は `forecastLog[]` に追記する
7. `facts` を手で編集しない

## 手順3: 公開(publish)

1. `Artifact` ツールで、テンプレートHTML(`report-template.html`)を本体(`file_path`)、
   `state.json` を補助ファイル(`files`)としてアーティファクトに公開する
2. テンプレートに `<title>` が無いため、公開時にページ名(`meta.title`)を渡す
3. `Artifact` ツールの publish 結果に含まれるURLを `meta.artifactUrl` に記録する
4. 2回目以降は `meta.artifactUrl` を `Artifact` ツールの `url` 引数に渡して同じ
   アーティファクトを更新する(`url` を省略すると新規作成になるため省略しない)

## 注意

- `facts` は取得スクリプトの出力。人・Claudeは編集しない
- `state.json` には画面に表示しない情報も含めて公開される。伏せたい情報(内部の識別子・関係者名など)はそもそも入れない
- スキーマの詳細は `SCHEMA.md` を参照する(本ファイルに複製しない)
- git操作(commit / push)は行わない
