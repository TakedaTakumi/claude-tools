# Maintainer Notes

このリポジトリは個人ツールで PR は受け付けていません。本ドキュメントは **メンテナー(今のところ自分)と作業を補助する Claude Code** のための同期チェックリストです。

## 汎用コマンドを追加/変更・削除する場合

### 追加する場合

- [ ] `templates/command-template.md` を `commands/<コマンド名>.md` にコピーする(命名規約: **kebab-case**、例: `commit-message.md`)
- [ ] frontmatter 必須フィールドを確認する(`description` / `argument-hint` / `allowed-tools`)
- [ ] `allowed-tools` は **最小権限の原則** に従う(無制限の `Bash` を与えず、`Bash(git diff:*)` 等サブコマンド単位で絞る)
- [ ] 本文を「目的 / 引数仕様 / 実行手順 / 出力形式」の節構成で書く
- [ ] [README.md](../README.md) の収録コマンド一覧の表に行を追加
- [ ] [docs/USAGE.md](USAGE.md) に使い方・引数・実行例を追記
- [ ] [CHANGELOG.md](../CHANGELOG.md) の `[Unreleased]` セクションに `### Added` で記録
- [ ] `./install.sh` を再実行し、`~/.claude/commands/` への反映を確認する

### 変更する場合

- [ ] frontmatter(特に `allowed-tools`)が実際に使うツールと一致しているか確認する
- [ ] [README.md](../README.md) の一覧表・[docs/USAGE.md](USAGE.md) の記述に差分が無いか確認し、必要なら更新する
- [ ] [CHANGELOG.md](../CHANGELOG.md) の `[Unreleased]` セクションに `### Changed` で記録
- [ ] `./install.sh` を再実行して反映を確認する(symlink 配置なら通常は再実行不要だが、`--copy` 配置の場合は必須)

### 削除する場合

- [ ] `commands/<コマンド名>.md` を削除する
- [ ] [README.md](../README.md) の一覧表・[docs/USAGE.md](USAGE.md) から該当記述を削除する
- [ ] [CHANGELOG.md](../CHANGELOG.md) の `[Unreleased]` セクションに `### Removed` で記録
- [ ] `./install.sh` を再実行し、`~/.claude/commands/` から古いファイル/symlink が残っていないか確認する(必要なら手動で `rm` する)

## 観点を追加する場合

このリポジトリの中核となる更新です。追加時は **以下のすべてを同期** してください(同期点の削減は中期課題)。

- [ ] `skills/code-review-perspectives/perspectives/<key>.md` を追加(frontmatter キー: `key` / `display_name` / `applicable_commands` / `applicable_categories_for_repo` / `primary_in_categories` / `auxiliary_in_categories` / `related_perspectives`)
- [ ] 本文の節構成を既存観点に合わせる(役割(人格)→ チェック項目 → 文脈別の読み替え → 関連観点。重大度の例は観点ファイルには書かず `templates/severity-criteria.md` に一元化する)
- [ ] `skills/code-review-perspectives/SKILL.md` の観点カタログ表に行を追加
- [ ] 該当する分類で評価する場合は `SKILL.md` の **分類 × 観点マトリクス**(`✅` / `⚠️`)にも反映
- [ ] `docs/PERSPECTIVES.md` の観点リストにも追記
- [ ] `skills/code-review-perspectives/templates/severity-criteria.md` の「観点別の Critical / High 例」表に行を追加
- [ ] 担当 Sub Agent の `agents/<agent>.md` の `description` に追記(auto-invocation のヒント)
- [ ] [CHANGELOG.md](../CHANGELOG.md) の `[Unreleased]` セクションに `### Added` で記録

## 分類を追加する場合(稀)

- [ ] `skills/code-review-perspectives/categories/<key>.md` を追加(`key` / `display_name` / `typical_paths` / `applicable_perspectives.primary` / `applicable_perspectives.auxiliary` を frontmatter で)
- [ ] `SKILL.md` の分類カタログ表と **分類 × 観点マトリクス** に列を追加
- [ ] 既存の全観点それぞれの `applicable_categories_for_repo` / `primary_in_categories` / `auxiliary_in_categories` を更新
- [ ] `docs/CATEGORIES.md` にも追記
- [ ] CHANGELOG に記録

## テンプレートを追加する場合

- [ ] `skills/code-review-perspectives/templates/<name>.md` を追加(frontmatter キー: `name` / `type: template` / `description`)
- [ ] `SKILL.md` のテンプレート表に行を追加
- [ ] 参照元(観点ファイルの該当節・担当 Sub Agent の評価手順)から相互参照を追記
- [ ] CHANGELOG に記録

## Sub Agent を追加・改修する場合

- [ ] `agents/<agent>.md` を作成・編集(`description` / `tools:` / 入力 / 評価手順 / 注意 の節構成)
- [ ] `tools:` は **最小権限の原則** に従う(`Bash` を無制限に与えず、`Bash(git:*)` 等で絞る)
- [ ] 対応する Slash Command(`commands/review-{branch,repo,slice}.md`)の委任先を更新
- [ ] `docs/ARCHITECTURE.md` の Sub Agent 担当表を更新
- [ ] CHANGELOG に記録

## レビュー用 Slash Command を追加・改修する場合

- [ ] `commands/<name>.md` を作成・編集
- [ ] **100 行以内** に収める(薄いオーケストレータの設計を維持)
- [ ] `allowed-tools` で必要最小限の Bash サブコマンドのみ宣言
- [ ] `docs/USAGE.md` に使い方を追記
- [ ] CHANGELOG に記録

## コミット規約

- 1行サマリは **70文字以内**、主題(何を変えたか)を明確にする。必要に応じて本文で理由("なぜ")を補足する
- 限定的なファイル変更は `<対象>: <主題>` 形式(例: `install.sh: 上書きガードを追加`)
- 汎用コマンドの追加は `<コマンド名> コマンドを追加` 形式
- 観点・分類・テンプレートの追加は `<観点キー> 観点を追加` / `<分類キー> 分類を追加` 等

## 危険コマンドの取り扱い

観点ファイル・テンプレートに **検出パターンとして危険コマンド**(`curl ... | sh` / `nc -e` / `bash -i >& /dev/tcp/` 等)を引用することがあります。引用する際は:

- 「これを検出せよ」と明確に分かる文脈で書く(「これを実行せよ」と読めないように)
- コードブロックで囲む
- 不可視文字・双方向制御文字・ホモグリフを含めない

## CI(GitHub Actions)

`.github/workflows/check.yml` に3ジョブを置いています:

| ジョブ | 内容 | ローカル再現 |
|---|---|---|
| `unicode` | コマンドファイル・観点ファイル等への不可視文字/双方向制御文字/BOM の混入検出(prompt injection 予防) | `grep -rPln '[\x{200B}-\x{200F}\x{202A}-\x{202E}\x{2066}-\x{2069}\x{FEFF}]' --include='*.md' --include='*.sh' --include='*.yml' --include='*.yaml' .` |
| `shellcheck` | `install.sh` / `bootstrap.sh` の静的解析 | `shellcheck install.sh bootstrap.sh` |
| `gitleaks` | シークレットの誤コミット検出 | `gitleaks detect` |

トリガーは `main` への push、`pull_request`、`workflow_dispatch`(GitHub UI / `gh workflow run check.yml` から手動実行)のみ(`develop` 等の他ブランチは対象外)。公式・third-party を問わずすべての action を commit SHA pin し、コメントで対応タグを併記している。

## セルフレビュー(dogfooding)

コマンド・観点を追加・変更した際は、本リポジトリの Claude Code から `/review-branch` や `/code-review` 等でその diff 自体をレビューし、frontmatter や allowed-tools・tools の過不足がないか確認する。
