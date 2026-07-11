---
description: ベースブランチとの差分を要約する
argument-hint: "--base=<branch>"
allowed-tools: Bash(git rev-parse:*), Bash(git merge-base:*), Bash(git diff:*), Bash(git log:*), Read, Grep, Glob
---

# Summarize Diff

現在のブランチと指定したベースブランチとの差分を読み、変更内容を要約する。

## 目的

レビュー前やPR作成前に、ブランチ全体の変更点を俯瞰し、影響範囲を素早く把握する。

## 引数仕様(`$ARGUMENTS`)

- `--base=<branch>`: ベースブランチを指定する(例: `--base=main`)。スペース区切りの `--base <branch>` は不可(エラー停止)。
- 未指定の場合は `git rev-parse --abbrev-ref origin/HEAD` またはローカルの `main` / `master`(`git rev-parse --verify` で存在確認)を自動判定する。判定根拠を出力に明示する。
- 上記以外の引数が渡された場合はエラー停止し、ユーザーに確認する(推測で進めない)。

## 実行手順

1. `git rev-parse --is-inside-work-tree` でリポジトリ内であることを確認する。
2. BASE_BRANCH を決定する(引数 > 自動判定)。決定根拠を明示する。
3. 現在のブランチ名を取得する。BASE_BRANCH と同一ならエラー停止する。
4. マージベースを取得する: `git merge-base <BASE_BRANCH> HEAD`。
5. 変更ファイル一覧を取得する: `git diff --name-status <merge-base>..HEAD`。
6. 変更行数の概観を取得する: `git diff --stat <merge-base>..HEAD`。
7. コミット履歴を取得する: `git log --oneline <merge-base>..HEAD`。
8. 変更量が大きい場合(目安: 1000行超 または 30ファイル超)は、全差分を一度に読まずファイル単位で要点を読む方針に切り替える。
9. 必要に応じて `Read` / `Grep` / `Glob` で変更ファイルの前後関係(呼び出し元・関連設定)を確認する。
10. 変更を機能単位にグルーピングし、それぞれの目的・影響範囲を要約する。

## 出力形式

```
## 差分概要

- ベースブランチ: <branch>(判定根拠: <引数指定 / 自動判定>)
- 対象ブランチ: <branch>
- コミット数: N / 変更ファイル数: N / 変更行数: +N -N

## 変更内容(グルーピング)

### <グループ名>
- 目的: ...
- 変更ファイル: <path>, ...
- 影響範囲: ...

## 気になる点(あれば)
- ...
```

## 動作上の注意

- 破壊的な git 操作(`reset` / `checkout` によるファイル上書き等)は行わない。読み取り専用の git コマンドのみを使う。
- ファイルパスを必ず添えて要約する。
- 大量差分の場合は要約の網羅性より正確性を優先し、読み切れなかった範囲があれば明示する。
