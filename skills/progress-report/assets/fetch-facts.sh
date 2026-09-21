#!/usr/bin/env bash
#
# state.json の facts セクションだけを GitHub (gh コマンド) から取得して書き換えるスクリプト。
#
# 使い方:
#   ./fetch-facts.sh <state.jsonへのパス>
#
# state.json の meta.targets[] (partId/repo/issue/pr) と meta.parent (repo/issue) を読み取り、
# GitHub 上の最新情報を取得して facts キーだけを差し替える。facts 以外のキー(parts/forecast/detail等)
# には一切手を加えない。
#
# 実行前提: gh (認証済み), jq (1.6以上、IN() 関数を使用するため)
#
set -euo pipefail

# ---------------------------------------------------------------------------
# 引数・前提コマンドのチェック
# ---------------------------------------------------------------------------

if [ "$#" -lt 1 ]; then
  echo "エラー: state.json のパスを引数に指定してください" >&2
  echo "使い方: $0 <state.jsonへのパス>" >&2
  exit 1
fi

STATE_FILE="$1"

if [ ! -f "$STATE_FILE" ]; then
  echo "エラー: ファイルが存在しません: ${STATE_FILE}" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "エラー: jq が見つかりません。インストールしてください。" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "エラー: gh (GitHub CLI) が見つかりません。インストールしてください。" >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "エラー: gh が GitHub に認証されていません。'gh auth login' を実行してください。" >&2
  exit 1
fi

if ! jq empty "${STATE_FILE}" >/dev/null 2>&1; then
  echo "エラー: ${STATE_FILE} は妥当なJSONではありません" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# 作業用ディレクトリ(PR/Issueの取得結果を貯めるための一時ファイル置き場)
# ---------------------------------------------------------------------------

WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

PRS_JSON="${WORKDIR}/prs.json"
ISSUES_JSON="${WORKDIR}/issues.json"
echo "[]" > "${PRS_JSON}"
echo "[]" > "${ISSUES_JSON}"
FAILED_COUNT=0

# ---------------------------------------------------------------------------
# PR一件を取得して PRS_JSON に追記する
#   引数: partId(JSONリテラル文字列。数値でも文字列でもnullでも可), repo, prNumber
#   失敗しても呼び出し元の処理は継続させたいので、内部で完結させ非ゼロで返す。
# ---------------------------------------------------------------------------
fetch_pr() {
  local partId="$1" repo="$2" prNum="$3"
  local raw

  if ! raw="$(gh pr view "${prNum}" --repo "${repo}" --json \
      number,url,title,isDraft,baseRefName,headRefName,additions,deletions,changedFiles,statusCheckRollup,reviewDecision,mergeable,state,createdAt,assignees,reviewRequests,latestReviews \
      2>/dev/null)"; then
    echo "警告: PRの取得に失敗しました (repo=${repo}, pr=${prNum})。この件をスキップします" >&2
    return 0
  fi

  local isDraft createdAt owner name readyAtLiteral

  isDraft="$(jq -r '.isDraft' <<<"${raw}")"
  createdAt="$(jq -r '.createdAt' <<<"${raw}")"
  owner="${repo%%/*}"
  name="${repo##*/}"

  if [ "${isDraft}" = "true" ]; then
    # Draft中はまだ Ready for review イベントが発生していないため null とする
    readyAtLiteral="null"
  else
    # gh pr view --json では readyForReviewAt を直接取得できないため、
    # GraphQL の timelineItems から ReadyForReviewEvent を検索して取得する。
    # - GraphQLクエリ自体が失敗した場合
    # - イベントが1件も見つからない場合(最初からDraftではなかったPRなど)
    # のいずれも、ここでは Draft ではないと分かっているため PR の createdAt にフォールバックする。
    local gqlResult readyAtValue
    # query内の $owner/$name/$number はGraphQL変数のプレースホルダーであり、シェル変数
    # ではない。ダブルクォートにするとシェルが展開してクエリが壊れるため、シングルクォート
    # のまま抑制する。
    # shellcheck disable=SC2016
    if gqlResult="$(gh api graphql -f query='
      query($owner:String!,$name:String!,$number:Int!) {
        repository(owner:$owner, name:$name) {
          pullRequest(number:$number) {
            timelineItems(itemTypes: READY_FOR_REVIEW_EVENT, first: 10) {
              nodes {
                ... on ReadyForReviewEvent { createdAt }
              }
            }
          }
        }
      }' -f owner="${owner}" -f name="${name}" -F number="${prNum}" 2>/dev/null)"; then
      readyAtValue="$(jq -r '.data.repository.pullRequest.timelineItems.nodes[0].createdAt // empty' <<<"${gqlResult}")"
    else
      readyAtValue=""
    fi

    if [ -z "${readyAtValue}" ]; then
      # フォールバック: Draftでない前提のもとPRのcreatedAtを採用する
      readyAtValue="${createdAt}"
    fi
    readyAtLiteral="$(jq -n --arg v "${readyAtValue}" '$v')"
  fi

  # ci集約: statusCheckRollupの各チェックを分類し、
  # 1件でもFAILURE相当があればFAILURE、無ければ1件でもPENDING相当があればPENDING、
  # それ以外(全部成功)ならSUCCESS。チェックが1件も無ければnull。
  local ci
  ci="$(jq -c '
    def classify:
      if (.status // "COMPLETED") != "COMPLETED" then "PENDING"
      elif (.conclusion != null) then
        (if (.conclusion | IN("SUCCESS","NEUTRAL","SKIPPED")) then "SUCCESS"
         elif (.conclusion | IN("FAILURE","CANCELLED","TIMED_OUT","ACTION_REQUIRED","STARTUP_FAILURE")) then "FAILURE"
         else "PENDING" end)
      elif (.state != null) then
        (if .state == "SUCCESS" then "SUCCESS"
         elif (.state | IN("FAILURE","ERROR")) then "FAILURE"
         else "PENDING" end)
      else "PENDING" end;
    (.statusCheckRollup // []) as $rollup
    | if ($rollup | length) == 0 then null
      else
        ($rollup | map(classify)) as $cls
        | if ($cls | index("FAILURE")) then "FAILURE"
          elif ($cls | index("PENDING")) then "PENDING"
          else "SUCCESS" end
      end
  ' <<<"${raw}")"

  # reviewers: レビュー依頼中(reviewRequests)と実施済み(latestReviews)のloginを重複無く集約
  local reviewers
  reviewers="$(jq -c '
    ((.reviewRequests // []) | map(.login // empty)) as $req
    | ((.latestReviews // []) | map(.author.login // empty)) as $rev
    | ($req + $rev | map(select(. != "")) | unique)
  ' <<<"${raw}")"

  local prEntry
  prEntry="$(jq -c \
    --argjson partId "${partId}" \
    --arg repo "${repo}" \
    --argjson ci "${ci}" \
    --argjson reviewers "${reviewers}" \
    --argjson readyForReviewAt "${readyAtLiteral}" \
    '{
      partId: $partId,
      repo: $repo,
      number: .number,
      url: .url,
      title: .title,
      isDraft: .isDraft,
      base: .baseRefName,
      head: .headRefName,
      additions: .additions,
      deletions: .deletions,
      changedFiles: .changedFiles,
      ci: $ci,
      reviewDecision: .reviewDecision,
      mergeable: .mergeable,
      state: .state,
      createdAt: .createdAt,
      readyForReviewAt: $readyForReviewAt,
      assignees: [(.assignees // [])[].login],
      reviewers: $reviewers
    }' <<<"${raw}")"

  jq --argjson entry "${prEntry}" '. + [$entry]' "${PRS_JSON}" > "${PRS_JSON}.tmp" && mv "${PRS_JSON}.tmp" "${PRS_JSON}"
}

# ---------------------------------------------------------------------------
# Issue一件を取得して ISSUES_JSON に追記する
# ---------------------------------------------------------------------------
fetch_issue() {
  local partId="$1" repo="$2" issueNum="$3"
  local raw

  if ! raw="$(gh issue view "${issueNum}" --repo "${repo}" --json number,url,state,createdAt,assignees 2>/dev/null)"; then
    echo "警告: issueの取得に失敗しました (repo=${repo}, issue=${issueNum})。この件をスキップします" >&2
    return 0
  fi

  local issueEntry
  issueEntry="$(jq -c \
    --argjson partId "${partId}" \
    --arg repo "${repo}" \
    '{
      partId: $partId,
      repo: $repo,
      number: .number,
      url: .url,
      state: .state,
      createdAt: .createdAt,
      assignees: [(.assignees // [])[].login]
    }' <<<"${raw}")"

  jq --argjson entry "${issueEntry}" '. + [$entry]' "${ISSUES_JSON}" > "${ISSUES_JSON}.tmp" && mv "${ISSUES_JSON}.tmp" "${ISSUES_JSON}"
}

# ---------------------------------------------------------------------------
# meta.targets[] を走査してPR/Issueを取得する
#   meta.targets が無い/空配列の場合は facts.prs / facts.issues は空配列のままになる。
# ---------------------------------------------------------------------------

TARGETS_JSON="$(jq -c '.meta.targets // []' "${STATE_FILE}")"
TARGET_COUNT="$(jq 'length' <<<"${TARGETS_JSON}")"

if [ "${TARGET_COUNT}" -eq 0 ]; then
  echo "情報: meta.targets が空のため、PR/Issueの取得はスキップします" >&2
fi

while IFS= read -r target; do
  [ -z "${target}" ] && continue

  partId="$(jq -c '.partId // null' <<<"${target}")"
  repo="$(jq -r '.repo // empty' <<<"${target}")"
  issueNum="$(jq -r '.issue // empty' <<<"${target}")"
  prNum="$(jq -r '.pr // empty' <<<"${target}")"

  if [ -z "${repo}" ]; then
    echo "警告: repo が指定されていないtargetをスキップします (partId=${partId})" >&2
    continue
  fi

  if [ -n "${prNum}" ] && [ "${prNum}" != "null" ]; then
    fetch_pr "${partId}" "${repo}" "${prNum}" || FAILED_COUNT=$((FAILED_COUNT + 1))
  fi

  if [ -n "${issueNum}" ] && [ "${issueNum}" != "null" ]; then
    fetch_issue "${partId}" "${repo}" "${issueNum}" || FAILED_COUNT=$((FAILED_COUNT + 1))
  fi
done < <(jq -c '.[]' <<<"${TARGETS_JSON}")

# ---------------------------------------------------------------------------
# meta.parent の sub-issue 進捗を取得する(取れない場合はnullのまま処理を継続)
# ---------------------------------------------------------------------------

PARENT_REPO="$(jq -r '.meta.parent.repo // empty' "${STATE_FILE}")"
PARENT_ISSUE="$(jq -r '.meta.parent.issue // empty' "${STATE_FILE}")"

SUB_ISSUE_PROGRESS="null"

if [ -n "${PARENT_REPO}" ] && [ -n "${PARENT_ISSUE}" ] && [ "${PARENT_ISSUE}" != "null" ]; then
  PARENT_OWNER="${PARENT_REPO%%/*}"
  PARENT_NAME="${PARENT_REPO##*/}"

  # query内の $owner/$name/$number はGraphQL変数のプレースホルダーであり、シェル変数
  # ではない。ダブルクォートにするとシェルが展開してクエリが壊れるため、シングルクォート
  # のまま抑制する。
  # shellcheck disable=SC2016
  if PARENT_GQL="$(gh api graphql -f query='
      query($owner:String!,$name:String!,$number:Int!) {
        repository(owner:$owner, name:$name) {
          issue(number:$number) {
            subIssuesSummary { total completed }
          }
        }
      }' -f owner="${PARENT_OWNER}" -f name="${PARENT_NAME}" -F number="${PARENT_ISSUE}" 2>/dev/null)"; then
    SUB_ISSUE_PROGRESS="$(jq -c '.data.repository.issue.subIssuesSummary // null' <<<"${PARENT_GQL}")"
  else
    echo "警告: 親issueのsub-issue進捗取得に失敗しました (repo=${PARENT_REPO}, issue=${PARENT_ISSUE})" >&2
    SUB_ISSUE_PROGRESS="null"
    FAILED_COUNT=$((FAILED_COUNT + 1))
  fi
else
  echo "情報: meta.parent が未設定のため、sub-issue進捗の取得はスキップします" >&2
fi

# ---------------------------------------------------------------------------
# facts を組み立てて state.json に書き戻す
#   一時ファイルに書いてからmvすることで、途中失敗時に元ファイルを壊さないようにする。
# ---------------------------------------------------------------------------

if [ "${FAILED_COUNT}" -gt 0 ]; then
  echo "エラー: ${FAILED_COUNT}件の取得に失敗したため、state.json は更新しません(既存の内容を保持します)" >&2
  exit 1
fi

GENERATED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

FACTS_JSON="$(jq -n \
  --arg generatedAt "${GENERATED_AT}" \
  --argjson prs "$(cat "${PRS_JSON}")" \
  --argjson issues "$(cat "${ISSUES_JSON}")" \
  --argjson subIssueProgress "${SUB_ISSUE_PROGRESS}" \
  '{
    generatedAt: $generatedAt,
    prs: $prs,
    issues: $issues,
    parent: { subIssueProgress: $subIssueProgress }
  }')"

TMP_STATE="$(mktemp "$(dirname "${STATE_FILE}")/.state.json.XXXXXX")"

# 万一失敗した場合に一時ファイルを残さないようにしておく
cleanup_tmp_state() {
  if [ -f "${TMP_STATE}" ]; then
    rm -f "${TMP_STATE}"
  fi
}
trap 'cleanup_tmp_state; rm -rf "${WORKDIR}"' EXIT

if ! jq --argjson facts "${FACTS_JSON}" '.facts = $facts' "${STATE_FILE}" > "${TMP_STATE}"; then
  echo "エラー: state.json への facts 反映に失敗しました。元ファイルは変更していません" >&2
  exit 1
fi

if ! jq empty "${TMP_STATE}" >/dev/null 2>&1; then
  echo "エラー: 生成結果が妥当なJSONではありません。書き戻しを中止しました(元ファイルは無傷です)" >&2
  exit 1
fi

mv "${TMP_STATE}" "${STATE_FILE}"

echo "facts を更新しました: ${STATE_FILE}"
