# COBA - AI協働ワークスペース

**CO**work + **COBA**（工場・コウバ）— AIと協働する日常業務のワークスペース。

Claude Code と一緒に仕事をするためのフォルダ構成。会議メモ、走り書き、スクショ—なんでも `tmp/` に放り込むだけで、AIが整理・整形・アジェンダ生成まで回してくれる。

## 思想

- 人間は `tmp/` にファイルを落とすだけ
- 考えるのはAI。整理するのもAI
- 過度に自動化しない。人間が「やって」と言ったときだけ動く
- 常にこのフォルダと一緒に仕事をする
- **秘書が窓口。何でも相談OK**

## クイックスタート

### 1. クローンして使う

```bash
# そのまま使う場合
git clone https://github.com/yourname/coba.git ~/coba
cd ~/coba

# 自分の好きな名前をつける場合（例: my-workspace, office, work など）
git clone https://github.com/yourname/coba.git ~/my-workspace
cd ~/my-workspace
```

好きな名前でクローンしてOK。フォルダ名は自由に変更できる。

<details>
<summary><strong>自分のGitHubリポジトリで管理したい場合</strong></summary>

クローン後に自分のリポジトリでバージョン管理したい場合は、以下の手順で設定できます。

#### 1. GitHubで新しいリポジトリを作成

GitHub で新しい **空のリポジトリ** を作成（README等は追加しない）

#### 2. リモートを変更

```bash
# 元のリモートを削除
git remote remove origin

# 自分のリポジトリを追加
git remote add origin https://github.com/あなたのユーザー名/リポジトリ名.git

# プッシュ
git push -u origin main
```

#### SSH を使う場合

```bash
git remote add origin git@github.com:あなたのユーザー名/リポジトリ名.git
git push -u origin main
```

これで、自分のリポジトリで独自のカスタマイズを管理できます。

</details>

### 2. 外部サービスのセットアップ

COBA は以下の外部サービスと連携できる。Google Calendar 以外は任意。

| サービス | 接続方式 | 必須 | 用途 |
|----------|----------|:----:|------|
| Google Calendar | Claude AI コネクター | ○ | `/generate-daily` で予定取得 |
| Slack | Claude AI プラグイン | 推奨 | `/morning` `/evening` でやりとり取得 |
| Jira | REST API（`scripts/jira.sh`） | 任意 | チケット検索・作成・ステータス変更 |
| Confluence | REST API（`scripts/confluence.sh`） | 任意 | ページ閲覧・作成・更新 |

---

<details>
<summary><strong>Google Calendar セットアップ（必須）</strong></summary>

`/generate-daily` でカレンダーから予定を取得するために必要。

##### 1. Claude Code で設定画面を開く

```bash
claude mcp
```

##### 2. Google Calendar コネクターを追加

Claude Code の設定 > 「Integrations」または「Connectors」から **Google Calendar** を有効化する。

- Claude.ai（Web版）で先に Google アカウントを連携しておくと、Claude Code でも自動で利用可能になる場合がある
- Claude Code の MCP 設定画面から直接追加することもできる

##### 3. 接続テスト

Claude Code で以下を試す:

```
今日の予定を教えて
```

カレンダーの予定が表示されればOK。

##### トラブルシューティング

- **「Google Calendar のツールが見つかりません」**: Claude Code を再起動してみる
- **認証エラー**: Claude.ai の Web 版でGoogle アカウント連携を確認
- **予定が取得できない**: カレンダーの共有設定を確認（自分のメインカレンダーが対象）

</details>

<details>
<summary><strong>Slack セットアップ（推奨）</strong></summary>

`/morning` や `/evening` で Slack のやりとりを自動取得できる。チャンネルの要約やメッセージ検索も可能。

##### 1. Slack プラグインを有効化

Claude Code の設定で Slack プラグインを有効化する。

プロジェクトの `.claude/settings.json` に以下が設定されていればOK:

```json
{
  "enabledPlugins": {
    "slack@claude-plugins-official": true
  }
}
```

##### 2. 認証

初回利用時に Slack の OAuth 認証画面が表示される。ワークスペースへのアクセスを許可する。

##### 3. 接続テスト

Claude Code で以下を試す:

```
Slackで #general チャンネルの最近のメッセージを見せて
```

メッセージが表示されればOK。

##### 4. 監視チャンネルの設定

`/morning` で自動チェックするチャンネルを `knowledge/me.md` に記録しておくと便利:

```markdown
## Slack

| 項目 | 値 |
|------|-----|
| 監視チャンネル | #dev-general, #announcements |
```

`/onboarding` で対話的に設定することもできる。

##### トラブルシューティング

- **認証エラー**: Claude Code を再起動して再認証
- **チャンネルが見つからない**: プライベートチャンネルは招待されている必要がある
- **プラグインが無効**: `.claude/settings.json` の `enabledPlugins` を確認

</details>

<details>
<summary><strong>Jira セットアップ（任意）</strong></summary>

Jira Cloud の REST API を `scripts/jira.sh` 経由で利用する。チケット検索・作成・ステータス変更などが秘書から操作可能になる。

##### 1. 前提条件

| ツール | 確認 | 備考 |
|--------|------|------|
| `curl` | `which curl` | macOS 標準 |
| `jq` | `which jq` | なければ `brew install jq` |
| `base64` | `which base64` | macOS 標準 |
| `python3` | `which python3` | URL エンコード用。macOS 標準 |

##### 2. API トークンを発行

1. https://id.atlassian.com/manage-profile/security/api-tokens にアクセス
2. 「API トークンを作成」をクリック
3. ラベル（例: `coba-workspace`）を入力して作成
4. 表示されたトークンをコピー（この画面を閉じると二度と表示されない）

##### 3. 認証情報ファイルを作成

```bash
# ディレクトリ作成
mkdir -p ~/.config/jira

# 認証情報ファイルを作成（各値を自分のものに置き換える）
cat > ~/.config/jira/credentials << 'EOF'
JIRA_DOMAIN=your-domain.atlassian.net
JIRA_EMAIL=your-email@example.com
JIRA_API_TOKEN=your-api-token-here
EOF

# パーミッション設定（重要: 自分だけ読み書き可能に）
chmod 600 ~/.config/jira/credentials
```

| 変数 | 説明 | 例 |
|------|------|-----|
| `JIRA_DOMAIN` | Jira Cloud のドメイン | `your-company.atlassian.net` |
| `JIRA_EMAIL` | Atlassian アカウントのメールアドレス | `you@example.com` |
| `JIRA_API_TOKEN` | 手順2で発行した API トークン | `ATATT3x...` |

##### 4. 接続テスト

```bash
./scripts/jira.sh myself
```

成功すると自分のアカウント情報が JSON で返る:

```json
{
  "accountId": "xxxxx",
  "displayName": "あなたの名前",
  "emailAddress": "you@example.com",
  "active": true
}
```

##### 5. メインプロジェクトを確認

```bash
./scripts/jira.sh projects
```

使うプロジェクトのキーを確認しておく。`/onboarding` または秘書に「Jiraの設定して」と言えば `knowledge/me.md` に記録される。

##### セキュリティについて

- 認証情報はリポジトリ外（`~/.config/jira/credentials`）に保管される
- `.gitignore` で `credentials`, `*.token`, `.env` は除外済み
- `credentials` のパーミッションは `600`（所有者のみ読み書き）
- スクリプトの出力にトークンやパスワードは含まれない

##### jira.sh コマンド一覧

| コマンド | 説明 |
|----------|------|
| `./scripts/jira.sh myself` | 自分の情報を取得 |
| `./scripts/jira.sh search "<JQL>"` | JQL でチケット検索 |
| `./scripts/jira.sh issue <KEY>` | チケット詳細を取得 |
| `./scripts/jira.sh create <project> <type> <summary> [desc]` | チケット作成 |
| `./scripts/jira.sh transitions <KEY>` | 遷移先一覧を取得 |
| `./scripts/jira.sh transition <KEY> <id>` | ステータスを変更 |
| `./scripts/jira.sh comment <KEY> "<body>"` | コメントを追加 |
| `./scripts/jira.sh projects` | プロジェクト一覧を取得 |
| `./scripts/jira.sh users "<query>"` | ユーザーを検索 |

詳しくは [scripts/README.md](./scripts/README.md) を参照。

##### トラブルシューティング

| エラー | 原因 | 対処 |
|--------|------|------|
| exit 1（認証エラー） | API トークンが無効 | トークンを再発行して `credentials` を更新 |
| exit 2（リソースなし） | チケットキーが間違い | キーを確認（例: `DEV-123`） |
| exit 3（レート制限） | API 呼び出し過多 | 自動リトライ後も失敗したら時間を置く |
| exit 4（その他） | 不明 | エラーメッセージを確認 |

</details>

<details>
<summary><strong>Confluence セットアップ（任意）</strong></summary>

Confluence Cloud の REST API を `scripts/confluence.sh` 経由で利用する。ページの閲覧・作成・更新が秘書から操作可能になる。

**Jira と同じ Atlassian アカウントの認証情報を共有する。** Jira のセットアップが済んでいれば追加の認証設定は不要。

##### 1. 前提条件

- Jira のセットアップが完了していること（`~/.config/jira/credentials` が存在する）
- Jira と同じ Atlassian ドメインで Confluence が利用可能であること

Jira 未セットアップの場合は、先に上の「Jira セットアップ」の手順2〜3（認証情報ファイル作成）を済ませる。

##### 2. 接続テスト

```bash
./scripts/confluence.sh spaces
```

成功するとスペース一覧が JSON で返る。

##### 3. メインスペースを確認

スペース一覧から使うスペースのキーを確認し、`knowledge/me.md` に記録:

```markdown
## Confluence

| 項目 | 値 |
|------|-----|
| ドメイン | your-company.atlassian.net |
| メインスペース | DEV |
```

`/onboarding` で対話的に設定することもできる。

##### confluence.sh コマンド一覧

| コマンド | 説明 |
|----------|------|
| `./scripts/confluence.sh spaces` | スペース一覧を取得 |
| `./scripts/confluence.sh search "<CQL>"` | CQL でページ検索 |
| `./scripts/confluence.sh page <ID>` | ページ詳細を取得 |
| `./scripts/confluence.sh page-by-title "<space>" "<title>"` | タイトルでページ取得 |
| `./scripts/confluence.sh children <ID>` | 子ページ一覧を取得 |
| `./scripts/confluence.sh create <space> "<title>" "<body>" [parentId]` | ページ作成 |
| `./scripts/confluence.sh update <ID> "<title>" "<body>"` | ページ更新 |
| `./scripts/confluence.sh comment <ID> "<body>"` | コメント追加 |
| `./scripts/confluence.sh comments <ID>` | コメント一覧を取得 |

詳しくは [scripts/README.md](./scripts/README.md) を参照。

##### トラブルシューティング

| エラー | 原因 | 対処 |
|--------|------|------|
| 認証エラー | Jira の credentials が未設定 or 無効 | `~/.config/jira/credentials` を確認 |
| スペースが見つからない | スペースキーが間違い | `./scripts/confluence.sh spaces` で確認 |
| ページ更新が競合 | 他の人が同時に編集 | もう一度試す（バージョン自動取得） |

</details>

### 3. Claude Code で開く

```bash
claude
```

### 4. オンボーディング

```
/onboarding
```

対話形式で初期設定を行う。

#### 設定される内容

| 項目 | 説明 | 必須 |
|------|------|:----:|
| 名前 | あなたの名前 | ○ |
| チーム・役割 | 所属と役割 | ○ |
| 秘書の名前 | 選択 or 自由入力（例: 佐藤、鈴木、田中） | |
| 秘書の性別 | 女性 / 男性 / 中性 / 指定しない | |
| 秘書の性格 | しっかり者 / フレンドリー / クール / 元気 / その他 | |
| 秘書の口調 | 丁寧語 / 敬語 / カジュアル / やわらかい | |

### 5. 秘書を呼ぶ

```
/secretary
```

何でも相談できる窓口。タスク確認、整理、壁打ち、メモ—全部ここから。

---

## フォルダ構成

```
coba/
├── tmp/                   ← ここにファイルを落とす（入口）
├── inbox/                 ← 分類・整形されたファイル
│   ├── meetings/              ← 議事録
│   ├── tasks/                 ← タスク一覧
│   ├── notes/                 ← メモ・アイデア
│   └── other/                 ← 分類できなかったもの
├── daily/                 ← 日次アジェンダ
├── weekly/                ← 週次サマリー
├── scripts/               ← ユーティリティスクリプト
│   ├── jira.sh                ← Jira REST API ラッパー
│   └── confluence.sh          ← Confluence REST API ラッパー
├── knowledge/             ← 蓄積ナレッジ
│   ├── me.md                  ← オーナー情報
│   ├── people.md              ← メンバー辞書
│   ├── glossary.md            ← 社内用語辞書
│   └── decisions/             ← 意思決定ログ
├── CLAUDE.md              ← プロジェクト概要
└── .claude/
    ├── commands/          ← スキル定義
    ├── rules/             ← ワークフロールール
    └── output-styles/     ← 回答スタイル定義
```

### 各フォルダの役割

#### `tmp/` - 入口
- **何でも放り込む場所**
- 会議メモ、走り書き、スクショ、音声メモ
- `/triage-tmp` で inbox/ に自動振り分け

#### `inbox/` - 整理済みファイル
- `meetings/` - 整形された議事録
- `tasks/` - タスク一覧（手動追加 or 抽出されたTODO）
- `notes/` - 壁打ちメモ、アイデア
- `other/` - 分類できなかったもの

#### `daily/` - 日次アジェンダ
- ファイル名: `YYYY-MM-DD.md`
- Google Calendar から自動生成
- 今日の予定 + 持ち越しタスク + Jira + Slack まとめ

#### `weekly/` - 週次サマリー
- ファイル名: `YYYY-Www.md`（例: `2026-W10.md`）
- 1週間の振り返り、MTGダイジェスト
- 未完了タスク、来週に向けて

#### `scripts/` - ユーティリティスクリプト
- `jira.sh` - Jira Cloud REST API のラッパースクリプト
- `confluence.sh` - Confluence Cloud REST API のラッパースクリプト
- 認証・エラーハンドリング・フォーマット変換を内包

#### `knowledge/` - 蓄積ナレッジ

| ファイル | 役割 |
|----------|------|
| `me.md` | 自分の情報。AIがパーソナライズに使う |
| `people.md` | メンバー辞書。人名を正式名称に統一 |
| `glossary.md` | 社内用語辞書。略称を展開 |
| `decisions/` | 意思決定ログ。1件1ファイルで蓄積 |

---

## ルール（.claude/rules/）

ルールは **該当フォルダを扱う時に自動で読み込まれる** 設定ファイル。スキルを呼ばなくても、対象フォルダを操作する際に適用される。

### ルール一覧

| ルール | 対象パス | 役割 |
|--------|----------|------|
| `secretary.md` | - | 秘書の口調・性格設定 |
| `tmp.md` | `tmp/**` | 振り分けルール |
| `meetings.md` | `inbox/meetings/**` | 議事録フォーマット |
| `tasks.md` | `inbox/tasks/**` | タスクフォーマット |
| `daily.md` | `daily/**` | 日次アジェンダのフォーマット・分類ルール |
| `weekly.md` | `weekly/**` | 週次サマリーのフォーマット |
| `knowledge.md` | `knowledge/**` | ナレッジ管理ルール |
| `jira.md` | - | Jira 連携ルール（JQL・フォーマット） |
| `confluence.md` | - | Confluence 連携ルール（CQL・フォーマット） |

---

## スキル一覧

### メインスキル

| コマンド | 説明 |
|----------|------|
| `/secretary` | 秘書。窓口として何でも相談、他スキルを自動呼び出し |
| `/onboarding` | 初期セットアップ。名前、働き方、秘書のカスタマイズ |

### ルーティン系

| コマンド | 説明 |
|----------|------|
| `/morning` | 朝の一括処理（振り分け→アジェンダ生成→Jira→Slack） |
| `/evening` | 夕方の一括処理（振り分け→整形→TODO抽出→Jira→Slack、週末は週次も） |

### 整理系

| コマンド | 説明 |
|----------|------|
| `/triage-tmp` | tmp/ を inbox/ に振り分け |
| `/format-meeting` | 議事録を構造化フォーマットに整形 |
| `/extract-todo` | 議事録からTODOを抽出（Jira起票オプション付き） |

### アジェンダ系

| コマンド | 説明 |
|----------|------|
| `/generate-daily` | Google Calendar + Jira + Slack から日次アジェンダ生成 |
| `/generate-weekly` | 週次サマリー生成 |

### キャプチャ系

| コマンド | 説明 |
|----------|------|
| `/capture-memo` | クイックメモを tmp/ に保存 |
| `/brainstorm` | 壁打ち・ブレインストーミング |

### 最適化系

| コマンド | 説明 |
|----------|------|
| `/optimize-rules` | 蓄積データからルールを学習・最適化 |

---

## 秘書について

`/secretary` は窓口として全体を統括するオーケストレーター。

**できること:**
- 「今日やること教えて」→ 予定・タスクを報告
- 「整理して」→ `/triage-tmp` を自動実行
- 「メモ取って」→ `/capture-memo` を実行
- 「壁打ちしたい」→ `/brainstorm` を実行
- 「チケット確認」→ Jira のオープンチケット表示
- 「○○のチケット作って」→ Jira にチケット作成
- 「ダッシュボード」→ 全体状況をサマリー

**カスタマイズ（`/onboarding` で設定）:**

| 項目 | 選択肢 |
|------|--------|
| 名前 | 佐藤 / 鈴木 / 高橋 / 田中 / 伊藤 / 山本 / 自由入力 |
| 性別 | 女性 / 男性 / 中性 / 指定しない |
| 性格 | しっかり者 / フレンドリー / クール / 元気 / その他 |
| 口調 | 丁寧語 / 敬語 / カジュアル / やわらかい / その他 |
| 回答スタイル | 簡潔 / 標準 / 詳細（output-styleで設定） |
| フォーマット | 箇条書き中心 / 文章中心 / 表形式 |

---

## 典型的な1日

```
朝    →  /morning（または /secretary「おはよう」）
日中  →   会議メモを tmp/ にポイポイ投げる
夕方  →  /evening（または /secretary「整理して」）
週末  →  /evening で週次サマリーも自動生成
```

---

## カスタマイズ

<details>
<summary><strong>秘書をカスタマイズする</strong></summary>

秘書の設定は2箇所で管理されています。

#### 1. knowledge/me.md（設定値）

秘書の基本設定を記録するファイル。`/onboarding` で自動設定されるが、手動編集も可能。

```markdown
## 秘書

| 項目 | 値 |
|------|-----|
| 名前 | 佐藤 |
| 性別 | 女性 |
| 性格 | フレンドリー |
| 口調 | 丁寧語 |
| 回答スタイル | 標準 |
| フォーマット | 箇条書き中心 |
```

**カスタム設定例:**

```markdown
| 性格 | 執事っぽく |
| 口調 | 関西弁 |
```

#### 2. .claude/output-styles/secretary.md（振る舞い定義）

`/onboarding` で自動生成される output-style ファイル。より細かい振る舞いを定義。

#### 3. .claude/rules/secretary.md（詳細ルール）

秘書の行動原則や提案タイミングなど、より詳細なルールを定義。

</details>

<details>
<summary><strong>MTG分類ルールをカスタマイズする</strong></summary>

`.claude/rules/daily.md` の「カスタムルール」セクションを編集。

`/onboarding` または `/optimize-rules` で、カレンダーの傾向を分析して自動提案もできる。

```markdown
### カスタムルール

| パターン | 種別 |
|----------|------|
| 「朝礼」「朝会」 | 全体朝礼 |
| 「定例」「【定例】」 | 定例MTG |
| 「1on1」「よもやま」 | 1on1 |
```

</details>

<details>
<summary><strong>knowledge/ を育てる</strong></summary>

AIの出力精度を上げるために、ナレッジを蓄積していく。

- `people.md` — メンバー辞書。「people.md に山田さん追加して」で追記
- `glossary.md` — 社内用語辞書。「glossary に CA を追加して」で追記
- `decisions/` — 意思決定ログ。重要な決定を1件1ファイルで記録

</details>

<details>
<summary><strong>スキル・ルールをカスタマイズする</strong></summary>

- スキル: `.claude/commands/` に新しい `.md` ファイルを作れば `/my-skill` で呼び出せる
- ルール: `.claude/rules/` のファイルを編集すると、対象フォルダ操作時に自動適用される

</details>

---

## 前提条件

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) がインストール済み
- Google Calendar 連携が設定済み（`/generate-daily` 用。セットアップは上記参照）
- Slack 連携が設定済み（推奨。セットアップは上記参照）
- Jira Cloud アカウント + API トークン（任意。セットアップは上記参照）
- Confluence Cloud（任意。Jira と同じ認証情報を使用。セットアップは上記参照）
- `jq` がインストール済み（Jira / Confluence 利用時。`brew install jq`）

## ライセンス

MIT
