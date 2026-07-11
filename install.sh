#!/usr/bin/env bash
#
# install.sh — claude-tools を ~/.claude/ 配下に配置する。
# CLAUDE.md（グローバルユーザーメモリ）・commands・agents・skills を配置する。
#
# 既定は symlink 配置(リポジトリの更新が即反映される)。
# symlink が使えない環境(Windows のジャンクション制約など)では
# 自動的にコピーへフォールバックする。明示的にコピーしたい場合は --copy。
#
# bash 3.2+ で動作する。
#
# Usage:
#   ./install.sh            # symlink で配置(失敗時はコピー)
#   ./install.sh --copy     # 強制的にコピーで配置
#   ./install.sh --force    # 本ツール由来でない同名エントリも確認なしで上書き
#   CLAUDE_DIR=/path ./install.sh   # 配置先を上書き
#
# ガード: 配置先に「本ツールが張った symlink 以外」の同名エントリがある場合、
# 上書き前に確認する(無関係な CLAUDE.md/コマンド/Agent/Skill を誤って壊さないため)。
#
set -euo pipefail

# unset のときだけデフォルトを適用する(空文字 CLAUDE_DIR="" は下の検証で明示的に拒否)
if [ -z "${CLAUDE_DIR+x}" ]; then
  CLAUDE_DIR="$HOME/.claude"
fi
if [ -z "$CLAUDE_DIR" ] || [ "$CLAUDE_DIR" = "/" ] || [ "${CLAUDE_DIR#-}" != "$CLAUDE_DIR" ]; then
  echo "error: CLAUDE_DIR must be a non-empty, non-root path not starting with '-' (got: '${CLAUDE_DIR}')" >&2
  exit 1
fi
CLAUDE_DIR="${CLAUDE_DIR%/}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE="symlink"
FORCE=0
FALLBACK_OCCURRED=0

for arg in "$@"; do
  case "$arg" in
    --copy) MODE="copy" ;;
    --symlink) MODE="symlink" ;;
    --force) FORCE=1 ;;
    -h|--help)
      echo "Usage: ./install.sh [--symlink|--copy] [--force]"
      echo "  --symlink  (default) シンボリックリンクで配置"
      echo "  --copy     コピーで配置"
      echo "  --force    本ツール由来でない同名エントリも確認なしで上書き"
      echo "環境変数: CLAUDE_DIR=/path で配置先を上書き(既定: ~/.claude)"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands"

SKIPPED=""
INSTALLED=""

# dest が「本ツールが張った src への symlink」かどうか
# readlink に -- を付けない(BSD/macOS の readlink は -- を解釈しないため)。
# 先頭ハイフン経路は CLAUDE_DIR の入力検証で弾いているので readlink への
# 引数も先頭ハイフンにはならない。
is_own_link() {
  [ -L "$1" ] && [ "$(readlink "$1" 2>/dev/null)" = "$2" ]
}

# 本ツール由来でない既存 dest を上書きしてよいか判定する。0=上書き可 / 1=スキップ
allow_overwrite() {
  local dest="$1"
  if [ "$FORCE" = "1" ]; then
    echo "warn: 既存を上書き(--force): $dest" >&2
    return 0
  fi
  if [ -t 0 ] && [ -r /dev/tty ]; then
    local ans=""
    printf "既存の %s は本ツール由来ではありません。上書きしますか? [y/N]: " "$dest" >&2
    read -r ans < /dev/tty || ans=""
    case "$ans" in [yY] | [yY][eE][sS]) return 0 ;; *) return 1 ;; esac
  fi
  echo "warn: 既存と衝突のためスキップ(上書きするには --force): $dest" >&2
  return 1
}

# 1 エントリ(ファイル or ディレクトリ)を symlink、失敗時はコピーで配置する。
# 本ツール由来でない同名エントリがあれば、上書き前に確認する(ガード)。
link_or_copy() {
  local src="$1" dest="$2"
  if { [ -e "$dest" ] || [ -L "$dest" ]; } && ! is_own_link "$dest" "$src"; then
    if ! allow_overwrite "$dest"; then
      SKIPPED="${SKIPPED}
  ${dest}"
      return 0
    fi
  fi
  rm -rf -- "$dest"   # real file/dir でも安全に置き換える(-- で dash-leading パス保護)
  if [ "$MODE" = "symlink" ]; then
    if ln -sfn -- "$src" "$dest" 2>/dev/null; then
      INSTALLED="${INSTALLED}
  ${dest}"
      return 0
    fi
    echo "warn: symlink に失敗したためコピーにフォールバック: $dest" >&2
    FALLBACK_OCCURRED=1
  fi
  cp -R -- "$src" "$dest"
  INSTALLED="${INSTALLED}
  ${dest}"
}

# グローバルユーザーメモリ(CLAUDE.md)
link_or_copy "$SCRIPT_DIR/config/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"

# Skill(ディレクトリごと)
link_or_copy "$SCRIPT_DIR/skills/code-review-perspectives" "$CLAUDE_DIR/skills/code-review-perspectives"

# Sub Agent(*.md を個別配置)
for f in "$SCRIPT_DIR/agents"/*.md; do
  [ -e "$f" ] || continue
  link_or_copy "$f" "$CLAUDE_DIR/agents/$(basename "$f")"
done

# Slash Command(*.md を個別配置)
for f in "$SCRIPT_DIR/commands"/*.md; do
  [ -e "$f" ] || continue
  link_or_copy "$f" "$CLAUDE_DIR/commands/$(basename "$f")"
done

if [ -n "$SKIPPED" ]; then
  echo "" >&2
  echo "次のエントリは本ツール由来でない既存と衝突したためスキップしました(--force で上書き可):" >&2
  printf '%s\n' "$SKIPPED" >&2
fi

# サマリ表示用の実態反映(MODE 自体はユーザーが要求したモードのまま保持する)
MODE_JA="$MODE"
MODE_EN="$MODE"
if [ "$FALLBACK_OCCURRED" = "1" ]; then
  MODE_JA="$MODE (一部 copy にフォールバック)"
  MODE_EN="$MODE, some entries fell back to copy"
fi

echo ""
echo "配置先: $CLAUDE_DIR (mode: $MODE_JA)"
if [ -n "$INSTALLED" ]; then
  echo "配置したエントリ:"
  printf '%s\n' "$INSTALLED"
fi
echo "Installed to $CLAUDE_DIR (mode: $MODE_EN)"
