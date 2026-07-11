# claude-tools

個人の [Claude Code](https://docs.claude.com/claude-code) 用ツール群を一元管理するリポジトリ。Slash Command / Skill / Sub Agent / グローバル `CLAUDE.md` を `install.sh` でまとめて `~/.claude/` に配置する。

## 収録ツール

### 汎用コマンド(8個)

| コマンド | 説明 |
|---|---|
| `/commit-message` | ステージ済みの変更(`git diff --staged`)と直近の `git log` からコミットメッセージ案を複数提示する |
| `/summarize-diff` | `--base=<branch>` で指定したベースブランチとの差分を要約する |
| `/new-branch` | 現在のブランチを起点に、指定した名前(省略時は提案)で新規ブランチを作成しチェックアウトする |
| `/new-pull-request` | push 済みの変更から Draft プルリクエストを作成する(`gh pr create --draft`) |
| `/review-feedback` | レビュー指摘された部分の修正が反映されているか再レビューする |
| `/review-issue` | 指定した issue 番号の内容を評価する |
| `/review-pull-request-comment` | PR のコメントを評価する |
| `/sync-docs` | ブランチでの変更に伴い、影響を受けるドキュメントを特定して更新する |

### レビューコマンド(3個)

| コマンド | 説明 |
|---|---|
| `/review-branch` | ブランチの変更(差分)を多観点で評価する |
| `/review-repo` | リポジトリ全体を「ファイル分類 × 観点」で健康診断する |
| `/review-slice` | 起点(ファイル or `ファイル::シンボル`)から依存を辿って機能スライスを構築し評価する |

レビューコマンドは、**Skill(観点ライブラリ)+ Sub Agent(専門ワーカー)+ 軽量 Slash Command(オーケストレータ)** の組み合わせで構成する。

- **33観点 × 8分類**のマトリクスでブランチ差分／リポジトリ全体／機能スライスを評価
- 観点は1ファイル1観点で**単一情報源**。3コマンドが共有する Skill `code-review-perspectives` から参照
- 観点グループごとに **Sub Agent が並列実行**、観点別に整理された出力を返す

```
skills/code-review-perspectives/   # 観点ライブラリ(SKILL.md + perspectives/ + categories/ + templates/)
agents/                            # 観点グループ別の Sub Agent(12個)
commands/                          # 全11コマンド(汎用8 + レビュー用3、薄いオーケストレータ)
config/CLAUDE.md                   # グローバルユーザーメモリ
docs/                              # ドキュメント
install.sh / bootstrap.sh          # ~/.claude/ への配置スクリプト
```

設計の全体像は [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)、観点・分類のカタログは [docs/PERSPECTIVES.md](docs/PERSPECTIVES.md) と [docs/CATEGORIES.md](docs/CATEGORIES.md) を参照。

### config/CLAUDE.md(グローバルユーザーメモリ)

`~/.claude/CLAUDE.md` に配置され、すべてのプロジェクトで読み込まれる個人の指示・作業方針をまとめたファイル。`install.sh` は既存の `CLAUDE.md` が本ツール由来でない場合は上書き前に確認する(手書きの設定を誤って壊さないためのガード)。

## インストール

### 要件

- **Claude Code**: Slash Command / Skill / Sub Agent 機構をサポートするバージョン。`claude --version` で確認できます。
- **bash**: 3.2 以上(macOS 標準 bash で動作。bash 固有機能を使うため dash / posh では実行不可)。

```bash
./install.sh                  # ~/.claude/ に symlink で配置(リポジトリ更新が即反映)
./install.sh --copy           # コピーで配置
./install.sh --force          # 本ツール由来でない同名エントリも確認なしで上書き
CLAUDE_DIR=/path ./install.sh # 配置先を上書き(既定は ~/.claude)
```

実行には bash が必要です。`sh install.sh` ではなく、`./install.sh`(要実行権限)または `bash install.sh` で実行してください(`/bin/sh` が dash の環境では `sh install.sh` は失敗します)。

`make` 経由でも同じオプションを実行できます(引数なしの `make` は `make help` としてターゲット一覧を表示)。

```bash
make install              # ./install.sh 相当
make install-copy         # ./install.sh --copy 相当
make install-force        # ./install.sh --force 相当
make install-copy-force   # ./install.sh --copy --force 相当
```

### 既定 = symlink、ただし以下では `--copy` を推奨

| ケース | 推奨 | 理由 |
|---|---|---|
| ローカル開発(コマンドや観点をその場で編集して反映したい) | `./install.sh`(symlink) | リポジトリ更新が即反映 |
| **VSCode 拡張版 Claude Code** | `./install.sh --copy` | 拡張版がスラッシュコマンドを discovery する際、symlink を辿らずコマンド一覧に出ないことがある |
| `~/.claude` を別 Docker コンテナにバインドする運用 | `./install.sh --copy` | symlink のターゲットパスはコンテナ内に存在しないため壊れる |
| `~/.claude` を本リポジトリ以外の用途にも使っている | (通常はそのまま symlink で問題なし) | install.sh は `CLAUDE.md` / `commands/` 配下11ファイル / `agents/` 配下の `*-reviewer.md` 12個 / `skills/code-review-perspectives` 以外には触れない。同名衝突がある場合はガードが効いて確認を求める |

`--copy` で配置した場合、コマンド・観点・Agent・`CLAUDE.md` を編集した後は `./install.sh --copy` の再実行が必要です(symlink では不要)。

### clone せずに導入する(bootstrap.sh)

このリポジトリを clone せずに導入したい場合は、`bootstrap.sh` を使います。GitHub の Contents API でファイルを取得して実行し、内部で `install.sh --copy` を実行します。前提として [`gh` コマンド](https://cli.github.com/) がインストール済みかつ認証済み(`gh auth login`)である必要があります。

```bash
gh api repos/TakedaTakumi/claude-tools/contents/bootstrap.sh -H "Accept: application/vnd.github.raw" | bash
```

これ1本で `CLAUDE.md` + `commands/` + `agents/` + `skills/` を含む Claude Code 環境全体が整います。`--force` などのオプションを渡す場合は `bash -s --` に続けて指定します。

```bash
gh api repos/TakedaTakumi/claude-tools/contents/bootstrap.sh -H "Accept: application/vnd.github.raw" | bash -s -- --force
```

環境変数 `BOOTSTRAP_REPO`(既定: `TakedaTakumi/claude-tools`。フォークなど別リポジトリから取得する場合に指定)と `CLAUDE_DIR`(配置先の上書き)にも対応しています。

## 新しいコマンドの追加手順

1. [templates/command-template.md](templates/command-template.md) を `commands/<コマンド名>.md`(kebab-case)にコピーする
2. frontmatter(`description` / `argument-hint` / `allowed-tools`)を実際のコマンドに合わせて書く
3. 本文を「目的 / 引数仕様 / 実行手順 / 出力形式」の節構成で書く
4. [docs/MAINTAINER_NOTES.md](docs/MAINTAINER_NOTES.md) のチェックリストに従い、README・docs・CHANGELOG を更新する
5. `./install.sh` を再実行して配置を確認する

## ドキュメント

- [docs/USAGE.md](docs/USAGE.md) — 全11コマンドの使い方・引数・実行例
- [docs/MAINTAINER_NOTES.md](docs/MAINTAINER_NOTES.md) — コマンド・観点・Agent 追加/変更/削除時のチェックリスト
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Skill + Sub Agent + Slash Command の設計
- [docs/PERSPECTIVES.md](docs/PERSPECTIVES.md) — 33観点のカタログ
- [docs/CATEGORIES.md](docs/CATEGORIES.md) — 8分類のカタログ
- [CHANGELOG.md](CHANGELOG.md) — 変更履歴(Keep a Changelog 形式)

## 利用方針

本リポジトリは **個人ツールとして公開** しているもので、外部からの Pull Request は基本的に受け付けていません。利用・フォーク・派生は [LICENSE](LICENSE)(MIT)の範囲で自由に行ってください(保証なし)。

脆弱性を見つけた場合のみ [SECURITY.md](SECURITY.md) に沿って報告してください。
