#!/usr/bin/env bash
#
# bootstrap.sh — git clone せずに claude-tools を ~/.claude/ 配下に配置する。
#
# GitHub の tarball を curl で取得し、一時ディレクトリに展開した上で
# install.sh をコピーモードで実行する。一時環境（clone せずワンライナーで
# 導入したい場合）向け。展開先は EXIT 時に削除するため、常にコピーモード
# で配置する（--symlink を渡してもコピーになる。symlink 先が消えて壊れる
# ことを防ぐため、--copy を常に末尾に付けて優先させている）。
#
# Usage:
#   ./bootstrap.sh            # コピーで配置
#   ./bootstrap.sh --force    # 本ツール由来でない同名エントリも確認なしで上書き
#   CLAUDE_DIR=/path ./bootstrap.sh   # 配置先を上書き
#   BOOTSTRAP_REPO=owner/repo ./bootstrap.sh   # 取得元リポジトリを上書き
#   BOOTSTRAP_REF=branch ./bootstrap.sh        # 取得するブランチを上書き
#
# 前提: curl と tar がインストール済みであること（認証不要・公開リポジトリ前提）。
#
set -euo pipefail

REPO="${BOOTSTRAP_REPO:-TakedaTakumi/claude-tools}"
REF="${BOOTSTRAP_REF:-main}"

if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl コマンドが見つかりません。インストールしてください" >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "error: tar コマンドが見つかりません。インストールしてください" >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT

curl -fsSL "https://codeload.github.com/$REPO/tar.gz/refs/heads/$REF" | tar xzf - -C "$TMP_DIR" --strip-components=1

bash "$TMP_DIR/install.sh" "$@" --copy
