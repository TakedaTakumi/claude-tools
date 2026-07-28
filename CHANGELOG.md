# Changelog

このリポジトリの注目すべき変更を [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) 形式で記録します。
バージョン番号は [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [Unreleased]

### Added

- **Sub Agent** `agents/` に5ファイル追加: coder / coder-hard / researcher / researcher-deep / tester(観点レビュアー12個とは別のユーティリティエージェント。tools は最小権限の原則に従い、コーディング系は Read/Write/Edit + Bash(git:*)、テスト実行を担う tester は Read/Write/Edit + Bash、調査系は Read/Grep/Glob(+WebSearch/WebFetch)で明示指定)
- **汎用コマンド** `commands/new-issue.md` を追加: 会話の文脈・依頼内容からタイトル・本文を作成し、ユーザーの承認を得たうえで `gh issue create` で issue を作成する(`allowed-tools`: `Bash(git rev-parse:*)`, `Bash(gh issue create:*)`, `Read`, `Grep`, `Glob`)
- **レビュー観点** `input-validation`(不正入力への防御)を追加(33観点から34観点に。`/review-branch` / `/review-slice` に適用、担当は logic-reviewer)

### Changed

- `/sync-docs`: 現在のブランチに紐づく PR のタイトル・本文も更新検討の対象に追加(承認後に `gh pr edit` で更新。PR が無い場合や `gh` が使えない場合はスキップ)
- `/new-pull-request`: `gh pr create` の前にタイトル・本文の全文をユーザーに提示して承認を得るステップを追加(無承認のまま Draft PR が作成される事故を防止)
- `config/CLAUDE.md`: 文面系成果物(コミットメッセージ案・PR/issue文面・実装計画・提案文など)の確認を求める際は、質問ツールを呼ぶ前に全文を通常のテキストとして提示することを明記。Fable モデル運用時は、サブエージェントへの委任指示に全文報告を明記すること、およびオーケストレーターが文面を要約せずそのまま提示することを追加
- `agents/coder.md` / `agents/coder-hard.md` / `agents/tester.md`: 完了報告に、コミットメッセージ案など作成した文面がある場合は全文を含めるよう明記
- `agents/researcher.md` / `agents/researcher-deep.md`: 報告に調査結果の本文・作成した文面を要約せず含めるよう明記
- `agents/tester.md`: tools に `Edit` を追加(`Read, Write, Edit, Bash`)
- `agents/coder.md` / `agents/coder-hard.md`: tools は `Read, Write, Edit, Bash(git:*)` のまま維持し、ビルド・リント・既存テストの実行検証はメインエージェント経由で tester に委ねる方針に指示文を修正
- `docs/MAINTAINER_NOTES.md`: 「Sub Agent を追加・改修する場合」のチェックリストを観点レビュアー向け(`*-reviewer.md`)とユーティリティエージェント向け(coder / coder-hard / tester / researcher / researcher-deep)に分割。ユーティリティ向けには `model:` の明示指定(`inherit` 禁止、Fable モデル運用ルールと整合)・git commit/push 禁止の明記・完了報告での文面系成果物の全文提示・README/USAGE との整合確認・CHANGELOG 記録を追加
- `docs/MAINTAINER_NOTES.md`: ユーティリティエージェント向けチェックリストの tools 例示に、テスト実行など任意のシェルコマンド実行が職務の場合は制限のない `Bash` を許容する旨を追記
- 既存4観点(`logic-correctness` / `security` / `error-handling` / `test-coverage`)の関連観点節に `input-validation` との責務境界を明記。`test-coverage` には不正入力テストの有無を確認するチェック項目を追加
- `config/CLAUDE.md` / `agents/tester.md`: 外部入力を受ける処理を実装・テストする際は、不正な入力値への振る舞いを設計・テストに含めるルールを追加
- `agents/logic-reviewer.md`: 担当観点・評価手順・責務分担に `input-validation` を追加。`/review-branch` / `/review-slice` の logic-reviewer への委任ラベルを「条件分岐・入力検証」に更新

## [0.1.0] - 2026-07-11

初回リリース。個人の Claude Code 用ツール群を一元管理するリポジトリとして公開。

### Added

- **汎用コマンド** `commands/` 8ファイル: `/commit-message` / `/summarize-diff` / `/new-branch` / `/new-pull-request` / `/review-feedback` / `/review-issue` / `/review-pull-request-comment` / `/sync-docs`(いずれも薄いオーケストレータ)
- **レビューコマンド** `commands/` 3ファイル: `/review-branch` / `/review-repo` / `/review-slice`
- **Sub Agent** `agents/` 12ファイル: security-reviewer / quality-reviewer / architecture-reviewer / ddd-reviewer / test-reviewer / logic-reviewer / performance-reviewer / ops-reviewer / dependencies-reviewer / meta-reviewer / ownership-reviewer / slice-flow-reviewer
- **Skill** `skills/code-review-perspectives/`: 33観点・8分類・6テンプレートのコードレビュー観点ライブラリ(`SKILL.md` がカタログ + マトリクス + 索引)
- **config/CLAUDE.md**: `~/.claude/CLAUDE.md` に配置するグローバルユーザーメモリ
- **install.sh**: `~/.claude/` への symlink / コピー配置スクリプト(bash 3.2+、上書きガードあり)
- **bootstrap.sh**: git clone せずに導入するためのブートストラップスクリプト(curl のみで動作、認証不要)
- **Makefile**: `make install` / `make install-copy` / `make install-force` / `make install-copy-force` / `make help`
- **.github/workflows/check.yml**: GitHub Actions CI(Unicode 不可視文字スキャン・shellcheck・gitleaks、`main` トリガーのみ、全 action commit SHA pin)
- **docs/**: USAGE / MAINTAINER_NOTES / ARCHITECTURE / PERSPECTIVES / CATEGORIES
- **templates/command-template.md**: 新規コマンド追加用テンプレート
- **LICENSE**(MIT)・**SECURITY.md**

[Unreleased]: https://github.com/TakedaTakumi/claude-tools/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/TakedaTakumi/claude-tools/releases/tag/v0.1.0
