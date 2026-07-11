# Changelog

このリポジトリの注目すべき変更を [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) 形式で記録します。
バージョン番号は [Semantic Versioning](https://semver.org/lang/ja/) に従います。

## [Unreleased]

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
