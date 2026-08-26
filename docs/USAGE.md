# USAGE

収録している各コマンドの使い方・引数・実行例をまとめる。汎用コマンド10個と、レビュー用コマンド3個の2章構成。

## 汎用コマンド

### `/commit-message`

ステージ済みの変更(`git diff --staged`)と直近の `git log` を読み、リポジトリの規約に沿ったコミットメッセージ案を複数提示する。

#### 引数

| 引数 | 必須 | 説明 |
|---|---|---|
| `[追加の指示]` | 任意 | 文体・形式などの追加指示(例: `Conventional Commits 形式で`) |

#### 実行例

```
/commit-message
```

追加の指示を与える場合:

```
/commit-message 英語で、1行に収めて
```

#### 注意

- `git commit` 自体は実行しない。あくまでメッセージ案の提示に留まる。
- ステージ済みの変更が無い場合は、その旨を報告して終了する。

---

### `/summarize-diff`

現在のブランチと指定したベースブランチとの差分を要約する。

#### 引数

| 引数 | 必須 | 説明 |
|---|---|---|
| `--base=<branch>` | 任意 | ベースブランチを指定する(例: `--base=main`)。未指定時は自動判定 |

#### 実行例

```
/summarize-diff --base=main
```

ベースブランチを省略する場合(自動判定):

```
/summarize-diff
```

#### 注意

- スペース区切りの `--base main` は不可。`--base=main` の形式で指定する。
- 変更量が大きい場合(目安: 1000行超 または 30ファイル超)はファイル単位で要約する方針に切り替わる。

---

### `/new-branch`

現在のブランチを起点に、指定した名前で新規ブランチを作成しチェックアウトする。

#### 引数

| 引数 | 必須 | 説明 |
|---|---|---|
| `[branch-name]` | 任意 | 作成するブランチ名。省略時は変更内容や会話の文脈から名前を提案し、実行前にユーザーに確認する |

#### 実行例

```
/new-branch feature/add-login
```

名前を省略する場合(内容から提案してもらう):

```
/new-branch
```

#### 注意

- 名前を提案する場合は、実行前に必ずユーザーに確認する(推測のまま作成しない)。
- upstream は設定しない(`git push -u` 等は行わない)。

---

### `/new-pull-request`

push 済みの変更に対して、内容を正しく反映した Draft プルリクエストを作成する(`gh pr create --draft`)。

#### 引数

| 引数 | 必須 | 説明 |
|---|---|---|
| `[title]` | 任意 | PR のタイトル。省略時は差分から生成する |

#### 実行例

```
/new-pull-request
```

タイトルを指定する場合:

```
/new-pull-request ログイン機能を追加
```

#### 注意

- push は行わない(push 済みであることを前提とする)。
- 必ず Draft として作成する(通常の PR としては作成しない)。
- PR 作成前にタイトル・本文の全文を提示し、ユーザーの承認を得る(無承認のまま作成しない)。

---

### `/new-issue`

会話の文脈・依頼内容から issue のタイトル・本文を作成し、ユーザーの承認を得たうえで issue を作成する(`gh issue create`)。

#### 引数

| 引数 | 必須 | 説明 |
|---|---|---|
| `[title]` | 任意 | issue のタイトル(または題材)。省略時は会話の文脈から生成する |

#### 実行例

```
/new-issue
```

タイトル(または題材)を指定する場合:

```
/new-issue ログイン画面でエラーメッセージが表示されない
```

#### 注意

- ラベル・assignee・マイルストーンは付与しない(必要な場合はユーザーが別途 `gh issue edit` 等で設定する)。
- issue 作成前にタイトル・本文の全文を提示し、ユーザーの承認を得る(無承認のまま作成しない)。
- issue の内容を推測で補わない。会話の文脈から判断できない場合はユーザーに確認する。

---

### `/review-feedback`

レビュー指摘された部分を修正したことを前提に、指摘内容に問題ないか再レビューを行う。

#### 引数

| 引数 | 必須 | 説明 |
|---|---|---|
| `[pr-number]` | 任意 | 指摘元とする PR 番号。省略時はセッション内のレビュー結果、無ければカレントブランチに紐づく PR を指摘元とする |

#### 実行例

```
/review-feedback 123
```

PR 番号を省略する場合(セッション内のレビュー結果、またはカレントブランチの PR を使用):

```
/review-feedback
```

#### 注意

- 指摘元は `$ARGUMENTS` の PR 番号 → セッション内のレビュー結果 → カレントブランチに紐づく PR、の優先順位で決定する。

---

### `/review-issue`

指定した番号の issue を `gh` で取得し、内容を評価する。

#### 引数

| 引数 | 必須 | 説明 |
|---|---|---|
| `<issue-number>` | 必須 | 評価対象の issue 番号 |

#### 実行例

```
/review-issue 42
```

#### 注意

- issue 番号が未指定または数値でない場合はエラー停止し、ユーザーに確認する(推測で進めない)。
- issue の内容を推測で補わない。取得した情報のみを根拠にする。

---

### `/review-pull-request-comment`

指定した PR(省略時はカレントブランチに紐づく PR)のコメントを `gh` で取得し、内容を評価する。

#### 引数

| 引数 | 必須 | 説明 |
|---|---|---|
| `[pr-number]` | 任意 | 評価対象の PR 番号。省略時はカレントブランチに紐づく PR を対象とする |

#### 実行例

```
/review-pull-request-comment 123
```

PR 番号を省略する場合(カレントブランチに紐づく PR を使用):

```
/review-pull-request-comment
```

#### 注意

- コメントの内容を推測で補わない。取得した情報のみを根拠にする。

---

### `/sync-docs`

ブランチでの変更内容を分析し、影響を受けるドキュメントを特定して更新する。現在のブランチに紐づく PR のタイトル・本文も更新候補に含める(PR が無い場合や `gh` が使えない場合はスキップする)。

#### 引数

| 引数 | 必須 | 説明 |
|---|---|---|
| `--base=<branch>` | 任意 | 差分のベースブランチ(例: `--base=main`)。未指定時は自動判定 |
| `[対象パス...]` | 任意 | ドキュメント探索の範囲をこのパス配下に限定する(0個以上)。省略時はリポジトリ全体から自動探索する |

#### 実行例

```
/sync-docs --base=main
```

対象パスを指定する場合:

```
/sync-docs --base=main docs/
```

#### 注意

- ドキュメントの新規作成は提案のみ行い、承認なしに作成しない。
- 更新候補の一覧を提示した後、ユーザーの承認を得てから更新する(承認前に編集を開始しない)。
- PR の更新も同様に承認を経てから `gh pr edit` で行う。PR が存在しない、または `gh` が使えない場合はスキップする(エラーにしない)。

---

### `/visualize`

指定した資料やトピックの内容を、専門用語・根拠(ファイルパス・行番号・出典URL・原文引用)・列挙項目の件数を保ったまま、図と構造で読み解ける HTML に組み替える。

#### 引数

| 引数 | 必須 | 説明 |
|---|---|---|
| `<対象>` | 必須 | ファイルパス、章の指定、トピックなど自由記述。未指定時はエラー停止し、ユーザーに確認する |
| `--out=<path>` | 任意 | 保存先パス。未指定時はセッションのスクラッチパッドに保存する |

#### 実行例

```
/visualize docs/spec.md
```

対象範囲と保存先を指定する場合:

```
/visualize "docs/spec.md の第3章" --out=./out/spec.html
```

#### 注意

- 用語を言い換えない・根拠を落とさない・列挙項目の件数を落とさない(削るのは文章量であって内容ではない)。
- 未決・未検証・未対応・保留の項目はそうと分かる形のまま残し、断定に丸めない。
- `--out=` 未指定時はセッションのスクラッチパッドに保存されるため、セッション終了で失われる可能性がある。恒久保存したい場合は `--out=` を指定する。
- `--out=` に存在しないディレクトリを指定すると `Write` が失敗し、エラー停止してユーザーに確認する(親ディレクトリの自動作成は行わない)。
- `--out` は `=` 区切りのみ受け付ける。スペース区切りの `--out <path>` は不可。
- Artifact としての公開は行わない。ローカルの HTML ファイルを生成するのみ。

---

## レビューコマンド

3つのレビュー用コマンドの使い分け・引数・実行例。観点・分類の本体は Skill 側(`skills/code-review-perspectives/`)にあり、本コマンドは薄いオーケストレータとして Sub Agent に委任する。

### 使い分け

| 状況 | 使うコマンド |
|---|---|
| PR・ブランチ差分を多観点で評価したい | `/review-branch` |
| リポジトリ全体の健康診断(分類別の問題棚卸し、優先順位、スコア推移) | `/review-repo` |
| 起点ファイルから依存スライスを構築し、入口→出口の流れで評価したい | `/review-slice` |

### 共通の挙動

- 進捗ログ: 🔍 進行中 / ✅ 完了 / ⚠️ 警告 / ❌ エラー + 1行(ハングに見えないように主要ステップで必ず出す)
- 各観点は frontmatter の `applicable_commands` で評価モード(branch/repo/slice)を絞っている。指定された観点と当該コマンドの組合せが存在しないときは明示して停止
- 不明なフラグ・観点名・分類名は開始前にユーザー確認(推測で進めない)
- スペース区切りのフラグ(`--base develop` 等)は受け付けず、`=` 区切り(`--base=develop`)のみ

---

### `/review-branch` — ブランチ差分レビュー

#### 引数

| 引数 | 既定 | 説明 |
|---|---|---|
| 第1引数(PERSPECTIVES) | `all` | 観点をカンマ区切り。空 / `all` で適用可能な全観点 |
| `--base=<branch>` | リモートのデフォルトブランチを自動検出 | 比較先ブランチ |
| `--preset=<quick\|standard\|full>` | `standard` | 起動するレビュアーの範囲(下記) |

#### プリセット

| プリセット | 起動するレビュアー | 用途 |
|---|---|---|
| `quick` | `security-reviewer` / `logic-reviewer` / `quality-reviewer` の3つのみ | 日常のブランチレビュー(最も軽い) |
| `standard`(既定) | 差分の内容から動的に選抜(下記) | 通常のレビュー |
| `full` | 適用観点を持つレビュアーを全て起動 | マージ前の最終確認。動的選抜を無効化するエスケープハッチも兼ねる |

#### 動的選抜(`standard`)

差分のファイル一覧と内容から**起動シグナル**を判定し、シグナルが1つも無いレビュアーだけを起動対象から外してコストを下げる。

- `security-reviewer` / `logic-reviewer` / `quality-reviewer` は、実行可能コードの変更がある限り常時起動(スキップ対象外)
- 判定できないファイル(未知の拡張子・読み取れない命名規約)は起動側に倒す。見落としのほうが無駄な起動より損害が大きいため
- 非コードのみの差分(`*.md` 等)は `meta-reviewer` のみ起動(シークレット・実行手順の記述があれば `security-reviewer` も起動)
- 例: テストも実行可能コードも変わっていなければ `test-reviewer` を、依存定義・ロックファイルが変わっていなければ `dependencies-reviewer` を、CI 設定・ランタイム構成・環境変数・ログ関連が変わっていなければ `ops-reviewer` をスキップ
- スキップした観点と理由は Phase 3 の「今回スキップした観点」節に必ず出力される(黙って観点が落ちることはない)
- PERSPECTIVES を明示指定した場合、動的選抜は適用しない(明示指定を上書きしないため)。明示指定と `--preset=quick|full` の併用は矛盾しうるため開始前に確認する

判定ルールの一覧は `commands/review-branch.md` の「エージェントの動的選抜」節にある。読むのはオーケストレータのみで、Sub Agent には渡さない。

#### 例

| 入力 | 動作 |
|---|---|
| `/review-branch` | 全観点 / base=自動検出 / 動的選抜あり |
| `/review-branch security` | security のみ |
| `/review-branch security,performance` | 複数観点 |
| `/review-branch --base=develop` | base=develop / 全観点 |
| `/review-branch security --base=main` | security のみ / base=main |
| `/review-branch --preset=quick` | security / logic / quality の3レビュアーのみ |
| `/review-branch --preset=full` | 動的選抜を無効化し、適用観点を持つ全レビュアーを起動 |

#### 流れ

1. **Phase 0**: ベースブランチ決定 → 差分取得 → 公開シンボルの参照箇所収集 → 起動レビュアーの確定
2. **Phase 1**: 観点を担当 Agent 群に**並列**委任
3. **Phase 2**: セルフレビュー(見落とし / 誤検知・過剰指摘 / 重大度の妥当性 / 観点間の整合 / 影響範囲)
4. **Phase 3**: 総評(マージ可否 ✅/⚠️/❌)＋ 必須対応 / 推奨対応 / 改善提案 / 評価サマリ表 ＋ 今回スキップした観点

---

### `/review-repo` — リポジトリ健康診断

#### 引数

| 引数 | 既定 | 説明 |
|---|---|---|
| 第1引数(PERSPECTIVES) | `all` | 観点をカンマ区切り |
| `--scope=<path>` | リポジトリ全体 | 評価対象を配下に限定 |
| `--categories=<list>` | 全8分類 | 評価分類をカンマ区切り |
| `--top=<n>` | 規模依存(≤500→5 / ≤2000→10 / ≤5000→20 / 超→30) | 各観点で上位 N 件に絞る |
| `--full` | 段階的実行 | Phase 0 → 1 → 1.5 → 2 → 3 を一気通貫 |
| `--baseline=<path>` | なし | 前回スコア JSON との差分を Phase 3 で出力 |
| `--save=<path>` | なし | Phase 3 のスコアを JSON 保存(次回 `--baseline` で使える) |

#### 実行モード

**既定 = 2段階インタラクティブ**:
- **段階1**: Phase 0 完全実行後、各分類の概況サマリ＋簡略スコアカードで**停止**し、深掘り対象の指示を待つ
- **段階2**: ユーザー指示に従い、該当分類・観点の Phase 1 詳細 + Phase 1.5 セルフレビューを実行(複数回繰り返し可)

`--full` を付けると一気通貫(長くなるため事前確認推奨)。

#### 例

| 入力 | 動作 |
|---|---|
| `/review-repo` | 段階1(全分類の概況スキャン)で停止 |
| `/review-repo --full` | Phase 0〜3 を一括実行 |
| `/review-repo security` | security 観点のみ(該当する全分類で) |
| `/review-repo --categories=ci,iac` | CI と IaC 分類のみ |
| `/review-repo --scope=src/api` | src/api 配下のみ |
| `/review-repo hotspot --top=20` | hotspot 観点のみ / 上位20件 |
| `/review-repo --full --save=docs/review/2026-05.json` | フル＋スコア保存 |
| `/review-repo --full --baseline=docs/review/2026-04.json --save=docs/review/2026-05.json` | 前回比較＋保存 |
| `/review-repo --categories=meta,build` | ガバナンス＋依存の軽量月次運用 |

PERSPECTIVES と `--categories` は **AND** で絞り込み。交差セルが空欄なら何も実行されない旨を明示。

#### スコアカード

各分類×観点を 1〜5 で評価。`--baseline` で前回比較(↑/↓ + 差分指標)。`--save` で次回比較用に JSON 永続化。

---

### `/review-slice` — 機能スライスレビュー

#### 引数

| 引数 | 既定 | 説明 |
|---|---|---|
| 第1引数(起点) | **必須** | `<ファイル>` または `<ファイル>::<シンボル>`。`::` が無ければファイル全体起点。存在しない/ファイルでないならエラー停止。シンボル = 関数 / クラス / `Class.method` |
| 第2引数以降(PERSPECTIVES) | `all` | スライス適用可能な観点をカンマ区切り |
| `--depth=<n>` | 無制限(安全上限10、0で起点のみ) | 依存追跡の最大深さ |
| `--direction=<down\|up\|both>` | `down` | 追跡方向。down=依存先 / up=利用元 / both=双方向 |
| `--full` | 段階的実行 | Phase 0 → 1 → 2 → 3 を一気通貫 |

#### 例

| 入力 | 動作 |
|---|---|
| `/review-slice src/api/order_controller.py` | 段階的実行(Phase 0 後に停止し確認) |
| `/review-slice src/api/order_controller.py --full` | 一気通貫 |
| `/review-slice src/api/order_controller.py --depth=3` | 依存追跡を3段まで |
| `/review-slice src/domain/order.py --direction=up` | 上流(利用元)を辿る |
| `/review-slice src/api/order_controller.py --direction=both` | 双方向 |
| `/review-slice src/api/order_controller.py ddd-tactical,ddd-strategic` | DDD 観点のみ |
| `/review-slice src/api/order_controller.py security,data-integrity --depth=5` | 観点と深さを併用 |
| `/review-slice src/app/order_service.py::OrderService` | クラス起点(span 内参照のみ依存追跡) |
| `/review-slice src/app/order_service.py::OrderService.checkout` | メソッド起点 |
| `/review-slice src/utils/calc.py::normalize_amount` | 関数起点 |

> **シンボル起点**: 起点ファイル内を「経路上(span)」と「起点同居(span 外の同ファイルコード)」にタグ区別し、依存追跡は span 内で参照される依存だけを辿る(ファイル全体の import は辿らない)。依存先ファイルは従来どおりファイル全体。
> 解決失敗・複数一致は Phase 0 で停止し確認、span が曖昧に確定できない／ネスト関数・ラムダ・動的生成は警告してファイル全体起点に縮退する。`--direction=up` × シンボルは同名衝突で精度が落ちる。

#### シンボルの書式

`<ファイル>::<シンボル>` の `<シンボル>` 部分は次の3形式のみ:

| 種別 | 書式 | 例 |
|---|---|---|
| 関数 | 関数名のみ | `calc.py::normalize_amount` |
| クラス | クラス名のみ | `order_service.py::OrderService` |
| クラスメソッド | `クラス名.メソッド名`(`.` は **1階層のみ**) | `order_service.py::OrderService.checkout` |

- `.` で繋ぐのはメソッド指定のときだけ。`OrderService` のようにクラス名単体ならクラス全体が起点。
- **ネストは未サポート**: ネストクラス(`Outer.Inner`)・ネスト関数・ネストメソッド(`Outer.Inner.method` の2階層以上)・ラムダ・動的生成は指定できない。検出時は警告してファイル全体起点に縮退する。
- 言語差: トップレベル関数・クラスはその名前、インスタンス/クラスメソッドは `クラス名.メソッド名` で統一(Python の `self` 引数、TS のアクセス修飾子、Go のレシーバ表記などは書式に含めない)。同名シンボル・オーバーロードは Phase 0 で警告・確認する。

#### 流れ

1. **Phase 0**: 起点(シンボル起点なら `::` 分割・span 解決)→ 依存追跡(`--direction`/`--depth`、シンボル起点は span 内参照に限定)→ レイヤー・コンテキスト分類 → 境界貫通検出 → 動的解決の警告。段階的実行ではここで停止しユーザー確認
2. **Phase 1**: `slice-flow-reviewer` が入口→出口の情報フローを作成 → 各観点 Agent に並列委任(情報フローを土台にする)
3. **Phase 2**: スライス全体のセルフレビュー
4. **Phase 3**: スライスサマリ(構成サマリ／Critical・High／推奨アクション／観点別スコア 1〜5)

slice で評価しない観点(`documentation`, `dead-code`, `duplication`, `hotspot`, `architecture-drift`, `test-strategy` 等)は対象外。詳細は各観点の frontmatter `applicable_commands` を参照。

---

## トラブルシューティング

- **VSCode 拡張でコマンドが補完に出ない** → `./install.sh --copy` でコピー配置にする(README の「既定 = symlink」表を参照)
- **`sh install.sh` でエラー** → `./install.sh` または `bash install.sh` で実行(dash 非対応)
- **観点を追加したのに認識されない** → SKILL.md のカタログ表に行を追加、担当 Agent の description にも追記。`make check` で同期漏れ(カタログ表・観点数表記・分類マトリクス)を検証できる。`--copy` モードなら `./install.sh --copy` を再実行
- **新しいコマンドが `/<コマンド名>` で見つからない** → `templates/command-template.md` からコマンドを追加した場合、`./install.sh` を再実行して `~/.claude/commands/` に反映してから確認する
