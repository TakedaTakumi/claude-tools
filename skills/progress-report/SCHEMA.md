# state.json スキーマ

`state.json` は進捗レポートの単一情報源。`facts` キーは `fetch-facts.sh` だけが
書き換え、それ以外のキーは人（および Claude）が書く。

トップレベルキーは9つ: `meta` / `headline` / `forecast` / `asks[]` / `parts[]` /
`watchItems[]` / `detail` / `forecastLog[]` / `facts`

## meta

| キー | 型 | 説明 |
|---|---|---|
| `title` | 文字列 | レポートのタイトル |
| `asOf` | `YYYY-MM-DD` | 基準日 |
| `oneLiner` | 文字列 | レポートの1行説明 |
| `artifactUrl` | 文字列 | 公開済みアーティファクトのURL(未公開時は空文字) |
| `targets[]` | `{ partId, repo, issue, pr }` | 対象リポジトリと課題/PR番号 |
| `parent` | `{ repo, issue }` | 親課題の参照 |

## headline

現在地を1行で表す文字列。

## forecast

| キー | 型 | 説明 |
|---|---|---|
| `earliest` | `YYYY-MM-DD` | 最短見込み |
| `latest` | `YYYY-MM-DD` | 最長見込み |
| `riskCondition` | 文字列 | `latest` 側に振れる条件 |
| `assumptions[]` | 文字列配列 | 前提 |

## asks[]

`{ what, by, who }`。`by` は `YYYY-MM-DD`。

## parts[]

| キー | 型 | 説明 |
|---|---|---|
| `id` | 数値 | パート識別子。`meta.targets[].partId` と一致させる |
| `name` | 文字列 | パート名 |
| `what` | 文字列 | 何をするパートか |
| `dependsOn[]` | 数値配列 | 依存する `parts[].id`。依存なしは空配列 |
| `next` | 文字列 | 次にやること |
| `forecast` | `{ earliest, latest }` | 見込み |
| `basis` | 文字列 | 見込みの根拠 |

## watchItems[]

`{ title, impact, action, affectsSchedule }`。`affectsSchedule` は真偽値。

## detail

| キー | 型 | 説明 |
|---|---|---|
| `featureDescription[]` | 文字列配列 | 機能説明の段落 |
| `diagramSvg` | 文字列 | 図のSVG(無い場合は省略)。トークン規約は下記 |
| `spec[]` | `{ k, v }` | 仕様のキー・バリューのペア |
| `branches[]` | `{ repo, nodes[] }` | ブランチツリー。下記参照 |
| `planDiff[]` | `{ title, body[] }` | 当初計画からの変更点 |
| `remaining[]` | 文字列配列 | 残作業の説明文 |
| `links[]` | `{ label, url }` | リンク集 |

### detail.branches[].nodes[]

`{ name, kind, depth, pr, prUrl, note }`

- `kind`: `trunk` / `release` / `work` などブランチの種別を表す文字列(テンプレート側は値を限定せず、種別ごとの見た目分岐にのみ使う)
- `depth`: ブランチツリーの段数(0が幹)。負値・小数は 0〜上限の範囲に丸められる
- `pr`: 関連するPR番号(無ければ `null`)

### detail.diagramSvg のトークン規約

図から参照してよい色・書体トークンは以下のみ:

```
--ground / --surface / --ink / --muted / --line / --accent / --ok / --wait / --risk / --idle / --wip
--display / --body / --mono
```

ここに無い名前を使うと `var()` が無効値になり `fill` / `stroke` が効かず図が表示され
なくなる。テンプレート側に `:where(.scroller svg){fill:var(--ink);stroke:var(--muted)}`
という詳細度0の既定値があるため、間違えても文字だけは読める状態で崩れる。

## forecastLog[]

`{ asOf, earliest, latest }`。見込みの推移。更新のたびに追記する。

## facts（取得スクリプトだけが書き換える）

| キー | 型 | 説明 |
|---|---|---|
| `generatedAt` | ISO 8601 UTC | 取得時刻 |
| `prs[]` | 下記 | |
| `issues[]` | `{ partId, repo, number, url, state, createdAt, assignees[] }` | |
| `parent.subIssueProgress` | `{ total, completed }` | 親issueのサブissue進捗。`percent` は持たず、表示側が都度算出する |

### facts.prs[] のキー(19キー)

`partId` / `repo` / `number` / `url` / `title` / `isDraft` / `base` / `head` /
`additions` / `deletions` / `changedFiles` / `ci` / `reviewDecision` / `mergeable` /
`state` / `createdAt` / `readyForReviewAt` / `assignees[]` / `reviewers[]`

## 状態ラベルの導出ルール

`parts[]` の各要素について、`id` が一致する `facts.prs[]` の要素を引いて判定する。
同一 `partId` に複数PRがある場合は、`MERGED` > `OPEN` > その他 > `CLOSED` の順で
最も進んだものを代表として使う。

```
該当PRが無い                                   → 未着手
state = MERGED                                 → 完了
isDraft = true                                 → 提出済（下書き）
isDraft = false かつ reviewDecision = APPROVED → マージ待ち
isDraft = false かつ それ以外                   → 承認待ち
```

上から順に評価し、最初に一致したものを採用する。

加えて、`dependsOn` に挙がった依存先パートの状態が「完了」でない場合、ラベルの後ろに
`（<依存先の name>・<依存先の name>の完了待ち）` を併記する。依存先が複数あるときは
`・` で連結する。依存先がすべて「完了」なら併記しない。

## 経過日数

`meta.asOf` を基準に2種類を出す。

| 表示 | 起点 | 未設定時 |
|---|---|---|
| 着手から | `facts.prs[].createdAt` | 「—」 |
| レビュー待ち | `facts.prs[].readyForReviewAt` | 「—」 |

- 起点・基準日いずれも **UTCの通日番号**(`Date.parse` した ms を1日のミリ秒数で
  割った商)の差を経過日数とする。タイムゾーン変換は行わない。負になる場合は 0 とする
- 起点が `null` または欠落している場合は「—」を表示する
- 「レビュー待ち」が **3日以上** の場合は警告表示にする

## 日付・時刻の形式

- `meta.asOf` / `forecast.earliest` / `forecast.latest` / `asks[].by` /
  `forecastLog[].asOf` などの日付: `YYYY-MM-DD`
- `facts` 配下のタイムスタンプ: ISO 8601・UTC（`Z` 終端）
- 不正な値は表示側で「—」または原文表示にフォールバックする(壊れない)

## テンプレートの構成上の注意

- `report-template.html` は `<title>` / `<head>` を持たないHTMLフラグメント。
  ページ名は `meta.title` からJSで `<h1>` に描画する。公開時にアーティファクトへ
  渡す名前は別途指定すること
