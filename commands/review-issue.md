---
description: 指定番号の issue を評価する
argument-hint: "<issue-number>"
allowed-tools: Bash(gh issue view:*), Read, Grep, Glob
---

# Review Issue

引数 `$ARGUMENTS` の番号を持つ issue を `gh` で取得し、内容を評価する。

## 目的

issue の内容(背景・要求・実現可能性・影響範囲など)を検討し、対応方針の判断材料を提供する。

## 引数仕様(`$ARGUMENTS`)

- issue 番号(必須): 評価対象の issue を指定する。
- 未指定または数値でない場合はエラー停止し、ユーザーに確認する(推測で進めない)。

## 実行手順

1. `gh issue view $ARGUMENTS` で issue の本文・コメント・ラベル等を取得する。
2. 必要に応じて issue が参照するファイル・コードを Read/Grep/Glob で確認し、内容の妥当性や影響範囲を把握する。
3. 内容を評価する(背景の妥当性、要求の明確さ、実現可能性、リスクや懸念点)。

## 出力形式

```
## Issue #<番号>: <タイトル>

- 概要: ...
- 評価: ...
- 懸念点・確認事項(あれば): ...
```

## 動作上の注意

- issue の内容を推測で補わない。取得した情報のみを根拠にする。
