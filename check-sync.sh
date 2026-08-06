#!/usr/bin/env bash
# 観点ライブラリの同期不変条件を機械的に検証する。
#
# 観点の追加・改名時の更新箇所はカタログ表・観点数表記・分類マトリクスに散在しており、
# 一部だけ更新された状態でも見た目には気付けない。ここで検証する不変条件は
# docs/MAINTAINER_NOTES.md「観点を追加する場合」のチェックリストに対応する。
#
# 実行: bash ./check-sync.sh （make check / CI の sync ジョブから呼ばれる）

set -euo pipefail

cd "$(dirname "$0")"

PERSPECTIVES_DIR="skills/code-review-perspectives/perspectives"
SKILL="skills/code-review-perspectives/SKILL.md"
VIEW="docs/PERSPECTIVES.md"

status=0

fail() {
	printf 'NG: %s\n' "$1" >&2
	status=1
}

keys=()
for f in "$PERSPECTIVES_DIR"/*.md; do
	keys+=("$(basename "$f" .md)")
done
count=${#keys[@]}

# 1. frontmatter の key がファイル名と一致するか
for k in "${keys[@]}"; do
	file_key=$(sed -n 's/^key: *//p' "$PERSPECTIVES_DIR/$k.md" | head -1)
	if [ "$file_key" != "$k" ]; then
		fail "$PERSPECTIVES_DIR/$k.md: frontmatter の key ($file_key) がファイル名 ($k) と一致しない"
	fi
done

# 2. SKILL.md の観点カタログ表が全観点を漏れなく・余さず載せているか
for k in "${keys[@]}"; do
	if ! grep -qF "| \`$k\` |" "$SKILL"; then
		fail "$SKILL: 観点カタログ表に $k の行がない"
	fi
done
# grep の終了コードは 0=マッチあり / 1=マッチなし / 2以上=実行失敗。
# 2以上を握り潰すと「検査できていないのに通過」になるため、明示的に分岐する。
row_status=0
rows=$(grep -cE '^\|.*\]\(perspectives/[a-z0-9-]+\.md\)' "$SKILL") || row_status=$?
if [ "$row_status" -gt 1 ]; then
	fail "$SKILL: 観点カタログ表の行数を数えられなかった (grep exit $row_status)"
elif [ "$rows" -ne "$count" ]; then
	fail "$SKILL: 観点カタログ表の行数 ($rows) が観点ファイル数 ($count) と一致しない"
fi

# 3. 二次ビューが全観点を載せているか
for k in "${keys[@]}"; do
	if ! grep -qF "perspectives/$k.md" "$VIEW"; then
		fail "$VIEW: $k への参照がない"
	fi
done

# 4. 各ドキュメントの観点数表記が実ファイル数と一致するか
#    CHANGELOG は過去バージョン時点の数を記録するため除外する
#    走査そのものの失敗（終了コード 2 以上）は握り潰さず、検査不能として報告する
scan_status=0
mentions=$(grep -rnE '[0-9]{2} ?観点' --include='*.md' .) || scan_status=$?
if [ "$scan_status" -gt 1 ]; then
	fail "観点数表記の走査を実行できなかった (grep exit $scan_status)"
else
	while IFS= read -r line; do
		[ -n "$line" ] || continue
		fail "観点数の表記が実ファイル数 ($count) と一致しない: $line"
	done < <(printf '%s\n' "$mentions" |
		grep -v '^\./CHANGELOG\.md:' |
		grep -vE "${count} ?観点" || true)
fi

# 5. 三者一致: applicable_categories_for_repo が空 <=> 分類 × 観点マトリクスに行がない
#    (docs/ARCHITECTURE.md「マトリクスの整合性」で定めた不変条件)
matrix_keys=$(awk '
	/^\| 観点 / { in_matrix = 1; next }
	/^凡例:/ { in_matrix = 0 }
	in_matrix && /^\| [a-z0-9-]+ \|/ {
		line = $0
		sub(/^\| /, "", line)
		sub(/ \|.*/, "", line)
		print line
	}
' "$SKILL" | sort)

repo_keys=$(
	for k in "${keys[@]}"; do
		categories=$(sed -n 's/^applicable_categories_for_repo: *//p' "$PERSPECTIVES_DIR/$k.md" | head -1)
		if [ "$categories" != "[]" ]; then
			printf '%s\n' "$k"
		fi
	done | sort
)

while IFS= read -r k; do
	[ -n "$k" ] || continue
	fail "$SKILL: $k はマトリクスに行があるが applicable_categories_for_repo が空"
done < <(comm -23 <(printf '%s\n' "$matrix_keys") <(printf '%s\n' "$repo_keys"))

while IFS= read -r k; do
	[ -n "$k" ] || continue
	fail "$SKILL: $k は applicable_categories_for_repo が非空だがマトリクスに行がない"
done < <(comm -13 <(printf '%s\n' "$matrix_keys") <(printf '%s\n' "$repo_keys"))

if [ "$status" -eq 0 ]; then
	printf 'OK: %d観点の同期チェックを通過\n' "$count"
fi

exit "$status"
