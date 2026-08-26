---
description: ブランチの変更（差分）を多観点で評価するオーケストレータ
argument-hint: "[perspectives] [--base=<branch>] [--preset=quick|standard|full]"
allowed-tools: Bash(git:*), Bash(gh:*), Bash(rg:*), Read, Grep, Glob
---

# Branch Review (Orchestrator)

観点ライブラリ Skill `code-review-perspectives` と複数の Sub Agent を組み合わせてブランチ差分レビューを実行する薄いオーケストレータ。観点の本体は Skill 側（`perspectives/`, `templates/`）にある。

## 進捗表示

🔍 進行中 / ✅ 完了 / ⚠️ 警告 / ❌ エラー + 1行で進捗を出す。詳細は Skill の `templates/progress-log.md`。

## 引数仕様（`$ARGUMENTS`）

- `--base=<branch>`: ベースブランチ（スペース区切り `--base <branch>` は不可＝エラー停止）。未指定なら、現在ブランチの PR のベース → reflog のブランチ作成記録 → GitHub デフォルトブランチ、の順で自動判定。
- 先頭の非フラグ引数 = PERSPECTIVES（カンマ区切り、空 or `all` で全観点）。余剰引数はエラー停止。
- `--preset=quick|standard|full`（既定 `standard`）: 起動するレビュアーの範囲。スペース区切りは不可＝エラー停止。
  - `quick`: `security-reviewer` / `logic-reviewer` / `quality-reviewer` の3つのみ（日常のブランチレビュー用）。
  - `standard`: 後述の「エージェントの動的選抜」を適用する（既定）。
  - `full`: 動的選抜を無効化し、適用観点を持つレビュアーを全て起動する（マージ前の最終確認用）。選抜を無効化するエスケープハッチは本フラグに一本化し、同義の別フラグは設けない。
- PERSPECTIVES を明示指定した場合、動的選抜は適用しない（ユーザーの明示指定を上書きしない）。明示指定と `--preset=quick|full` の併用は指定同士が矛盾しうるため、開始前にユーザー確認。
- 評価可能な観点 = Skill の各観点 frontmatter で `applicable_commands` に `review-branch` を含むもの。
- 不明なフラグ・観点名は開始前にユーザー確認（推測で進めない）。

## エージェントの動的選抜（`--preset=standard`）

Phase 0 手順6で取得した `--name-status` と差分本文を入力に、レビュアーごとの**起動シグナル**を判定する。シグナルが1つも見つからないレビュアーだけをスキップし、判定できないファイル（未知の拡張子、命名規約が読めないパス）は**全シグナル該当として扱って起動側に倒す**（観点の見落としは、無駄な起動より損害が大きい）。

- **常時起動**（実行可能コードの変更が1件以上ある限りスキップしない）: `security-reviewer` / `logic-reviewer` / `quality-reviewer`。
- **非コードのみの差分**（`*.md` / `*.txt` / `*.rst` / 画像 / `LICENSE` 等のみ）: `meta-reviewer` のみ起動する。ただし差分にシークレットらしい文字列・実行手順（`curl … | bash` 等）・権限設定の記述が含まれる場合は `security-reviewer` も起動する。

| レビュアー | 起動シグナル（いずれか該当で起動 / 全て不在ならスキップ） |
|---|---|
| `test-reviewer` | テストファイル（`test` / `tests` / `spec` / `__tests__` / `e2e` / `*_test.*` / `*.test.*` / `*.spec.*` / `conftest.*` / `Test*` 等）の変更、または**テスト以外の実行可能コードの変更**（テストが伴っていないこと自体が test-coverage の指摘対象のため、コード変更があればスキップしない） |
| `architecture-reviewer` | ファイルの追加・削除・リネーム（`--name-status` の A / D / R）、トップレベル2ディレクトリ以上にまたがる変更、モジュール境界を越える import の増減、公開シンボルの追加・削除 |
| `ddd-reviewer` | パスまたは識別子のドメイン層シグナル（`domain` / `entity` / `entities` / `aggregate` / `value_object` / `repository` / `usecase` / `application` / `service` / `model` 等）、業務用語を持つ型・関数の追加、業務ルールを含む条件式（金額・数量・状態遷移・期限） |
| `performance-reviewer` | ループ・コレクション操作・クエリ（SQL / ORM）・I/O・HTTP 呼び出し・キャッシュ・並行処理の変更、DB スキーマ／マイグレーション／シリアライズ形式の変更 |
| `ops-reviewer` | CI 設定（`.github/workflows` / `.gitlab-ci.yml` / `Jenkinsfile` / `.circleci` 等）、ランタイム構成（`Dockerfile*` / `compose*.y*ml` / k8s manifest / `Procfile` / systemd unit / `*.tf`）、開発環境（`.devcontainer` / `.envrc` / mise / asdf / `pre-commit` / `Makefile` / 運用スクリプト）、環境変数・設定キー（`.env*` / `config/`）、ログ・メトリクス・トレースの識別子 |
| `dependencies-reviewer` | 依存定義・ロック（`package.json` / `*-lock.*` / `yarn.lock` / `Cargo.toml` / `go.mod` / `requirements*.txt` / `pyproject.toml` / `Gemfile*` / `pom.xml` / `build.gradle*` / `composer.json` / `*.csproj` / `mix.exs` / `pubspec.yaml` / `.tool-versions` / `vendor/`）の変更、または Dockerfile・スクリプト中のパッケージ導入行の変更 |
| `meta-reviewer` | 文書（`*.md` / `docs/` / `README` / `CHANGELOG` / ADR）の変更、公開 API・CLI フラグ・設定キーの変更（文書追随が必要になるため）、UI 文字列・日付／数値フォーマット・a11y 属性・i18n リソースの変更 |
| `ownership-reviewer` | 新規ファイルの追加、生成物・ベンダリング（`*.generated.*` / `*_pb2.*` / `dist/` / `vendor/`）、ライセンスヘッダを持つファイル、既存スタイルから乖離した大量追加 |

判定は Phase 0 のこのステップでのみ行う（Sub Agent には判定表を渡さない）。起動 N 個 / スキップ M 個とスキップ理由を進捗ログに1行で出し、Phase 3 で明示する。

## 実行手順

### Phase 0: 準備（ベースブランチ決定 & 差分取得）

1. `git rev-parse --is-inside-work-tree` で確認。
2. 現在ブランチ取得。
3. BASE_BRANCH 決定（引数 > `gh pr view --json baseRefName --jq '.baseRefName'`（現在ブランチの open PR。取得できなければ次へ） > `git reflog show <現在のブランチ>` 末尾の `branch: Created from <base>`（記録が無ければ次へ） > `gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name'` > `git symbolic-ref refs/remotes/origin/HEAD` > ローカル main/master）。決定根拠を明示。
4. remote 鮮度確認（`git fetch --dry-run origin <BASE>`）。更新があれば fetch するかユーザー確認（勝手に fetch しない）。
5. base == head ならエラー停止。
6. マージベース取得 → 差分（`--name-status` / `--stat` / 詳細 diff、大きければファイル単位）。
7. コミット履歴 `git log --oneline <merge-base>..HEAD`。
8. 影響範囲: 変更/追加/削除された公開シンボル（関数・クラス・エンドポイント・CLI フラグ・env・設定キー・DB スキーマ）を抽出し、`rg`/`git grep` で参照箇所を洗う（compatibility/architecture/test-coverage/input-validation で参照）。
9. 条件式抽出: 差分中で変更・追加された条件式（if / switch / 三項演算子 / ガード節）を `rg` で機械的に抽出し、一覧を用意する（logic-correctness で参照）。
10. 大量変更（目安 1000 行超 or 30 ファイル超、または平均 PR 比で大）ならファイル単位読みへ方針宣言。
11. 適用観点を決定（PERSPECTIVES × applicable_commands）。
12. 起動レビュアーを確定: `quick` = 常時起動の3つのみ / `standard` = 上記「エージェントの動的選抜」を適用（PERSPECTIVES 明示指定時は適用せず該当 Agent を全起動）/ `full` = 適用観点を持つレビュアーを全起動。スキップしたレビュアーと理由を記録しておく。

### Phase 1: Sub Agent への委任（並列）

Phase 0 手順12で確定したレビュアーだけを、担当観点ごとにまとめて**並列に**委任する（各 Agent に 評価モード=`branch`・下記の差分ハンドオフ・適用観点を渡す）:

- security 系 → `security-reviewer` / 品質系 → `quality-reviewer` / アーキ → `architecture-reviewer` / DDD → `ddd-reviewer` / テスト → `test-reviewer` / 条件分岐・入力検証 → `logic-reviewer` / 性能・データ → `performance-reviewer` / ops（runtime-config/devenv-quality/ci-quality/observability）→ `ops-reviewer` / 依存 → `dependencies-reviewer` / メタ（documentation/i18n-a11y）→ `meta-reviewer` / 由来（code-provenance）→ `ownership-reviewer`

**差分ハンドオフ（委任プロンプトの規約）** — diff 全文を委任プロンプトに複製しない（Agent 数だけ複製され総トークンが線形に膨らむ）。渡すのは以下だけ:

- コミット範囲 `<merge-base>..HEAD`（手順6）、`--name-status` の一覧、`--stat` のサマリー、大量変更判定（手順10）の結果。
- **手順8の公開シンボル一覧と手順9の条件式一覧は、起動する全 Agent の委任プロンプトに必ず転記する**（Phase 0 で済んだ抽出を Agent 側で再実行させないため。転記漏れは規約違反）。
- diff 本文は各 Agent が担当観点に必要な範囲だけ `git diff <merge-base>..HEAD -- <対象パス>` で取得する。security のような横断観点でパスを絞り込めない場合は全体を見てよい（無理な絞り込みによる見落としのほうが損害が大きい）。
- 同じファイルを複数 Agent が読むことは並列構成上避けられないため許容する。削減対象はメイン側のプロンプト複製と Phase 0 成果の再抽出に限る。

### Phase 2: 集約とセルフレビュー

各 Agent の結果を集約し、観点間の重複・矛盾を解消する。セルフレビューは次の5点で行う:

- **見落とし**: 起動した各観点について、差分の主要な変更が最低1つは評価されているか。
- **誤検知・過剰指摘**: 指摘が差分に実在するか（ファイル:行を再確認）。既存仕様・既存スタイルを誤って問題視していないか。
- **重大度の妥当性**: `templates/severity-criteria.md` の基準と照合し、影響と発生確率で説明できるか。
- **観点間の整合**: 同一箇所への重複指摘を統合し、観点間で相反する推奨を解消したか。
- **影響範囲**: Phase 0 手順8の参照箇所と突き合わせ、呼び出し元・互換性への波及が反映されているか。

### Phase 3: サマリー出力

総評（マージ可否 ✅/⚠️/❌）、良かった点（**指摘より先に提示・必須**。無ければ「特になし」）、必須対応（Critical/High）、推奨対応（Medium）、今後の改善提案（Low/Info）、評価サマリ表。重大度は Skill の `templates/severity-criteria.md`。

加えて**「今回スキップした観点」節を必ず出す**（スキップが無ければ「なし（適用可能な全観点を評価）」と明記）。スキップしたレビュアー・担当観点キー・理由（`standard` = 該当する変更が差分に含まれないため／どのシグナルが不在だったか、`quick` = プリセットによる限定）を表で列挙し、「全観点を評価するには `--preset=full`」を添える。

## 動作上の注意

- 推測で進めない。確認すべきケースは Sub Agent に委任せずメインで確認する。
- ファイルパスと行番号を必ず添える。既存コードのスタイル・規約を尊重する。
- `review-repo` / `review-slice` との棲み分けを尊重する。
