# Changelog

このリポジトリの注目すべき変更を [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) 形式で記録します。
バージョン番号は [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [Unreleased]

### Added

- **Sub Agent** `agents/` に5ファイル追加: coder / coder-hard / researcher / researcher-deep / tester(観点レビュアー12個とは別のユーティリティエージェント。tools は最小権限の原則に従い、実行系は Read/Write/Edit + 限定的な Bash(git:*)、調査系は Read/Grep/Glob(+WebSearch/WebFetch)で明示指定)

### Changed

- `/sync-docs`: 現在のブランチに紐づく PR のタイトル・本文も更新検討の対象に追加(承認後に `gh pr edit` で更新。PR が無い場合や `gh` が使えない場合はスキップ)
- `/new-pull-request`: `gh pr create` の前にタイトル・本文の全文をユーザーに提示して承認を得るステップを追加(無承認のまま Draft PR が作成される事故を防止)
- `config/CLAUDE.md`: 文面系成果物(コミットメッセージ案・PR/issue文面・実装計画・提案文など)の確認を求める際は、質問ツールを呼ぶ前に全文を通常のテキストとして提示することを明記。Fable モデル運用時は、サブエージェントへの委任指示に全文報告を明記すること、およびオーケストレーターが文面を要約せずそのまま提示することを追加
- `agents/coder.md` / `agents/coder-hard.md` / `agents/tester.md`: 完了報告に、コミットメッセージ案など作成した文面がある場合は全文を含めるよう明記
- `agents/researcher.md` / `agents/researcher-deep.md`: 報告に調査結果の本文・作成した文面を要約せず含めるよう明記
- `agents/tester.md`: tools に `Edit` を追加(`Read, Write, Edit, Bash`)
- `agents/coder.md` / `agents/coder-hard.md`: tools は `Read, Write, Edit, Bash(git:*)` のまま維持し、ビルド・リント・既存テストの実行検証はメインエージェント経由で tester に委ねる方針に指示文を修正

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
