---
description: 新規ブランチの作成
argument-hint: "[branch-name]"
allowed-tools: Bash(git branch:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git checkout:*), Read, Grep, Glob
---

# New Branch

`$ARGUMENTS` を名前として、現在のブランチを起点に新規ブランチを作成しチェックアウトする。

## 目的

作業内容に応じたブランチを素早く作成し、命名やベースブランチ選定の手間を減らす。

## 引数仕様(`$ARGUMENTS`)

- ブランチ名(省略可): 省略した場合は変更内容や会話の文脈から名前を提案する。
- 名前を提案する場合は、実行前に必ずユーザーに確認する(推測のまま作成しない)。

## 実行手順

1. `git branch --show-current` で現在のブランチ名を取得する(このブランチを起点とする)。
2. `$ARGUMENTS` が空の場合、`git status --short` と `git diff` でステージ済み・未ステージの変更を確認し、`git log -5` で直近のコミットも踏まえて、必要なら Read/Grep で関連ファイルを確認しつつブランチ名を提案する。
3. ブランチ名が決まったら(提案の場合はユーザー確認後)、`git checkout -b <branch-name>` で現在のブランチを起点に新規ブランチを作成し、チェックアウトする。
4. upstream は設定しない(`git push -u` 等は行わない)。

## 出力形式

```
作成したブランチ: <branch-name>
起点ブランチ: <元のブランチ名>
(名前を提案した場合)提案理由: ...
```

## 動作上の注意

- 名前を提案する場合は、実行前に必ずユーザーに確認する。
- upstream を設定しない。
