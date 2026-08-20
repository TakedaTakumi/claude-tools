---
description: 新規プルリクエストの作成
argument-hint: "[title]"
allowed-tools: Bash(git rev-parse:*), Bash(git merge-base:*), Bash(git diff:*), Bash(git log:*), Bash(git reflog:*), Bash(gh pr create:*), Read, Grep, Glob
---

# New Pull Request

新しく Draft プルリクエストを作成する(`gh pr create --draft`)。

## 目的

push 済みの変更に対して、内容を正しく反映した Draft PR を素早く作成する。

## 引数仕様(`$ARGUMENTS`)

- タイトル(省略可): 省略した場合は差分から生成する。

## 実行手順

1. `git rev-parse --is-inside-work-tree` でリポジトリ内であることを確認する。push 済みであることを前提とし、push 自体は行わない。
2. `git rev-parse --abbrev-ref HEAD` で現在のブランチ名を取得する。
3. ベースブランチを判定する: 手順2で取得したブランチ名を対象に `git reflog show <手順2のブランチ名>` 末尾の `branch: Created from <base>`(ブランチ作成記録) → `git rev-parse --abbrev-ref origin/HEAD`(取得できなければローカルの `main` / `master` を `git rev-parse --verify` で存在確認する)、の順で判定する。
4. `git merge-base <base> HEAD` でマージベースを取得し、`git diff <merge-base>..HEAD` と `git log --oneline <merge-base>..HEAD` で変更内容を把握する。必要に応じて Read/Grep で変更ファイルの詳細を確認する。
5. タイトルを決定する: `$ARGUMENTS` があればそれを使い、無ければ差分から生成する。
6. 本文を差分内容の要約として作成する。
7. タイトルと本文の全文を通常のテキストとしてユーザーに提示し、承認を得る。修正指示があれば反映して再提示し、承認が得られるまで繰り返す(推測で進めず、必ずユーザーの承認を得てから次に進む)。
8. `gh pr create --draft --title "<title>" --body "<body>"` で Draft PR を作成する。

## 出力形式

```
## Pull Request 作成前の確認

### タイトル
<title>

### 本文
<body>

---

## Pull Request 作成結果

- URL: <PR URL>
- タイトル: <title>
- ベースブランチ: <base>
```

## 動作上の注意

- push は行わない(push 済みであることを前提とする)。
- 必ず Draft として作成する(通常の PR としては作成しない)。
- タイトル・本文はユーザーへ全文を提示し、承認を得てから PR を作成する(無承認のまま `gh pr create` を実行しない)。
