---
description: 進捗レポートを立ち上げ・更新・公開する
argument-hint: "<init|update|publish> [--dir=<path>] [--title=<name>]"
allowed-tools: Read, Write, Edit, Glob, Skill
---

# Progress Report

進捗レポート(`state.json` + テンプレートHTML)の立ち上げ・更新・公開を行う。
手順の本体は Skill `progress-report` にあり、本コマンドは引数解釈と実行順序の
制御のみを担う薄いオーケストレータ。

## 目的

機能の進捗を「同じURLを更新し続けるWebページ」として共有するための、
立ち上げ・毎日の更新・公開を明示的に呼び出せるようにする。

## 引数仕様(`$ARGUMENTS`)

- 第1引数(必須): `init` | `update` | `publish` のいずれか。未指定・未知の値は
  エラー停止してユーザーに確認する(推測で進めない)
- `--dir=<path>`(任意): レポートのデータディレクトリ。未指定時は
  `.progress-report/<レポートID>/`
- `--title=<name>`(任意): 公開時のページ名。`publish` で未指定なら `meta.title` を使う
- フラグは `=` 区切りのみ。スペース区切り(`--dir <path>`)はエラー停止する
- 余剰引数・不明なフラグはエラー停止してユーザーに確認する(推測で進めない)

## 実行手順

1. `$ARGUMENTS` からサブコマンドとフラグを分離する。不正ならエラー停止する
2. `Skill` ツールで `progress-report` スキルを読み込む
3. サブコマンドに応じて Skill の該当手順を実行する
   - `init` → 立ち上げ手順
   - `update` → 更新手順(取得スクリプトの実行を含む。人が書く欄を提示して見直す)
   - `publish` → 公開手順
4. `state.json` を書き換える前に、変更内容と対象パスを提示してユーザーの承認を得る
5. `publish` は公開前に、ページ名と公開対象(本体HTML + 補助ファイル)を提示して承認を得る

## 出力形式

```
## Progress Report: <init|update|publish>

- 対象ディレクトリ: <path>
- 変更内容: <概要>
- 承認事項(あれば): ...
- 公開URL(publish時): <url>
```

## 動作上の注意

- `facts` を手で編集しない(取得スクリプトの出力)
- git操作(commit / push)は行わない
- `state.json` の上書き・アーティファクトの公開は無承認で実行しない
- スキーマの詳細はSkillの`SCHEMA.md`を参照する。コマンド本文に複製しない
- 取得スクリプト(`fetch-facts.sh`)の実行は事前許可(`allowed-tools`)に含めない。
  Bashツールの通常の権限プロンプトに従う
