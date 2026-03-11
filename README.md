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
git clone https://github.com/tkcel/COBA.git ~/coba
cd ~/coba

# 自分の好きな名前をつける場合（例: my-workspace, office, work など）
git clone https://github.com/tkcel/COBA.git ~/my-workspace
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

### 2. Claude Code で開く

```bash
claude
```

### 3. オンボーディング

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

#### オンボーディング後の変化

```
workspace/
├── README.md          ← 新規作成（あなた専用、秘書名入り）
├── COBA_README.md     ← 元のCOBA説明書（リネーム）
├── knowledge/
│   └── me.md          ← あなたの情報が書き込まれる
└── ...
```

### 4. 秘書と仕事する

`claude` を起動すると、セッション開始時に秘書が自動で立ち上がる（`.claude/hooks/` による SessionStart フック）。

特に何もしなくても、秘書がそのまま窓口として対応してくれる。タスク確認、整理、壁打ち、メモ—なんでも話しかけるだけでOK。

明示的に呼びたいときは `/secretary` でもOK。

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
├── knowledge/             ← 蓄積ナレッジ
│   ├── me.md                  ← オーナー情報
│   ├── people.md              ← メンバー辞書
│   ├── glossary.md            ← 社内用語辞書
│   └── decisions/             ← 意思決定ログ
├── CLAUDE.md              ← プロジェクト概要
└── .claude/
    ├── commands/          ← スキル定義
    ├── rules/             ← ワークフロールール
    ├── hooks/             ← 起動時フック
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
- 今日の予定 + 持ち越しタスク

#### `weekly/` - 週次サマリー
- ファイル名: `YYYY-Www.md`（例: `2026-W10.md`）
- 1週間の振り返り、MTGダイジェスト
- 未完了タスク、来週に向けて

#### `knowledge/` - 蓄積ナレッジ

| ファイル | 役割 |
|----------|------|
| `me.md` | 自分の情報。AIがパーソナライズに使う |
| `people.md` | メンバー辞書。人名を正式名称に統一 |
| `glossary.md` | 社内用語辞書。略称を展開 |
| `decisions/` | 意思決定ログ。1件1ファイルで蓄積 |

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
| `/morning` | 朝の一括処理（振り分け→アジェンダ生成） |
| `/evening` | 夕方の一括処理（振り分け→整形→TODO抽出、週末は週次も） |

### 整理系

| コマンド | 説明 |
|----------|------|
| `/triage-tmp` | tmp/ を inbox/ に振り分け |
| `/format-meeting` | 議事録を構造化フォーマットに整形 |
| `/extract-todo` | 議事録からTODOを抽出 |

### アジェンダ系

| コマンド | 説明 |
|----------|------|
| `/generate-daily` | Google Calendar から日次アジェンダ生成 |
| `/generate-weekly` | 週次サマリー生成 |

### キャプチャ系

| コマンド | 説明 |
|----------|------|
| `/capture-memo` | クイックメモを tmp/ に保存 |
| `/brainstorm` | 壁打ち・ブレインストーミング |

### エクスポート系

| コマンド | 説明 |
|----------|------|
| `/export-pdf` | Markdown ファイルを PDF にエクスポート |

### 最適化系

| コマンド | 説明 |
|----------|------|
| `/optimize-rules` | 蓄積データからルールを学習・最適化 |

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

### ルールの仕組み

```
ユーザー: 「inbox/meetings/の議事録を整形して」
                ↓
Claude Code: rules/meetings.md を自動読み込み
                ↓
定義されたフォーマットに従って整形
```

---

## 回答スタイル（.claude/output-styles/）

Claude Code の `output-style` 機能を使って、秘書の振る舞いを制御。

`/onboarding` で以下の設定を組み合わせ、カスタム output-style を自動生成:

| 設定項目 | 選択肢 |
|----------|--------|
| 名前 | 佐藤 / 鈴木 / 高橋 / 田中 / 伊藤 / 山本 / その他 |
| 性別 | 女性 / 男性 / 中性 / 指定しない |
| 性格 | しっかり者 / フレンドリー / クール / 元気 / その他 |
| 口調 | 丁寧語 / 敬語 / カジュアル / やわらかい / その他 |
| 回答スタイル | 簡潔 / 標準 / 詳細 |
| フォーマット | 箇条書き中心 / 文章中心 / 表形式 |

生成されるファイル: `.claude/output-styles/secretary.md`

### 変更方法

再度 `/onboarding` を実行するか、直接 `.claude/output-styles/secretary.md` を編集

---

## 秘書について

`/secretary` は窓口として全体を統括するオーケストレーター。

**できること:**
- 「今日やること教えて」→ 予定・タスクを報告
- 「整理して」→ `/triage-tmp` を自動実行
- 「メモ取って」→ `/capture-memo` を実行
- 「壁打ちしたい」→ `/brainstorm` を実行
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

**性格による口調の違い:**
- **しっかり者**: 丁寧で正確、抜け漏れなく管理
- **フレンドリー**: カジュアルで親しみやすい
- **クール**: 簡潔でドライ、必要なことだけ
- **元気**: 明るくポジティブ、励ましてくれる
- **その他**: 自由に設定（執事、ツンデレなど）

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

**編集箇所:**
- `## 性格によるキャラクター` - 性格ごとの振る舞い
- `## 口調（言葉遣い）` - 言葉遣いのルール
- `## 回答スタイル` - 回答の詳細度
- `## フォーマット` - 出力形式

**カスタム口調の追加例:**

```markdown
## 口調（言葉遣い）

関西弁で話す:
- 「〜やで」「〜やな」「〜してな」
- 例: 「確認したで」「ええ感じやな」「これやっとくわ」
```

#### 3. .claude/rules/secretary.md（詳細ルール）

秘書の行動原則や提案タイミングなど、より詳細なルールを定義。

**編集可能なセクション:**
- 挨拶パターン（時間帯別）
- 主体的な提案タイミング
- 対応の原則

</details>

<details>
<summary><strong>MTG分類ルールをカスタマイズする</strong></summary>

#### 設定ファイル

`.claude/rules/daily.md` の「カスタムルール」セクション

#### 自動設定

`/onboarding` または `/optimize-rules` で、カレンダーの傾向を分析して自動提案。

#### 手動追加

```markdown
### カスタムルール

| パターン | 種別 |
|----------|------|
| 「朝礼」「朝会」 | 全体朝礼 |
| 「定例」「【定例】」 | 定例MTG |
| 「1on1」「よもやま」 | 1on1 |
| 「レビュー」「Review」 | レビューMTG |
| 「面接」「採用」 | 採用MTG |
```

**パターンの書き方:**
- 複数パターンは `「A」「B」` のように並べる
- 部分一致で判定される（「定例」なら「開発定例」「営業定例」にマッチ）

</details>

<details>
<summary><strong>議事録フォーマットをカスタマイズする</strong></summary>

#### 設定ファイル

`.claude/rules/meetings.md`

#### 編集箇所

「出力フォーマット」セクションのテンプレートを編集

```markdown
## 出力フォーマット

# {{日付}} {{会議名}}

## 参加者
- {{参加者リスト}}

## アジェンダ
1. {{議題1}}
2. {{議題2}}

## 議事内容

### {{議題1}}
- {{内容}}

## 決定事項
- {{決定事項}}

## TODO
- [ ] {{タスク}}（担当: XX, 期限: MM/DD）
```

**カスタマイズ例:**
- セクションの追加・削除
- 項目の順序変更
- 独自のセクション（「次回予告」「宿題」など）

</details>

<details>
<summary><strong>knowledge/ を育てる</strong></summary>

AIの出力精度を上げるために、ナレッジを蓄積していく。

#### people.md（メンバー辞書）

```markdown
| メール | 名前 | チーム・役割 | 備考 |
|--------|------|-------------|------|
| taro@example.com | 山田 太郎 | 開発チーム | 「たろさん」と呼ばれがち |
| hanako@example.com | 鈴木 花子 | デザインチーム | |
```

**追加方法:**
```
「people.md に山田さん追加して」
```

#### glossary.md（社内用語辞書）

```markdown
| 用語・略称 | 正式名称・意味 |
|-----------|---------------|
| CA | キャリアアドバイザー |
| PdM | プロダクトマネージャー |
| MTG | ミーティング |
```

**追加方法:**
```
「glossary に CA を追加して」
```

#### decisions/（意思決定ログ）

重要な決定事項を1件1ファイルで記録。

```
decisions/
├── 2026-03-10_release-date.md
├── 2026-03-05_tech-stack.md
└── ...
```

**フォーマット:**
```markdown
# リリース日の決定

- **日付**: 2026-03-10
- **会議**: 開発定例
- **関係者**: @山田, @鈴木

## 決定内容
4月1日にリリースする

## 背景・理由
新年度に合わせたい
```

</details>

<details>
<summary><strong>スキルをカスタマイズする</strong></summary>

#### スキルファイルの場所

`.claude/commands/` ディレクトリ

```
.claude/commands/
├── secretary.md      # 秘書（オーケストレーター）
├── onboarding.md     # 初期設定
├── morning.md        # 朝の処理
├── evening.md        # 夕方の処理
├── triage-tmp.md     # tmp振り分け
├── format-meeting.md # 議事録整形
├── extract-todo.md   # TODO抽出
├── generate-daily.md # 日次アジェンダ
├── generate-weekly.md# 週次サマリー
├── capture-memo.md   # クイックメモ
├── brainstorm.md     # 壁打ち
└── optimize-rules.md # ルール最適化
```

#### 編集例: /morning に独自ステップを追加

```markdown
## 実行フロー

1. tmp/ を inbox/ に振り分け（`/triage-tmp`）
2. 日次アジェンダ生成（`/generate-daily`）
3. 【追加】Slackの未読を確認  ← 独自ステップ
4. 朝のサマリーを報告
```

#### 新しいスキルを作る

`.claude/commands/my-skill.md` を作成すると `/my-skill` で呼び出せる。

```markdown
# /my-skill

ここにスキルの説明を書く。

## 実行フロー

1. ステップ1
2. ステップ2

## ルール

- ルール1
- ルール2
```

</details>

<details>
<summary><strong>ルールをカスタマイズする</strong></summary>

#### ルールファイルの場所

`.claude/rules/` ディレクトリ

```
.claude/rules/
├── secretary.md   # 秘書の振る舞い
├── tmp.md         # tmp振り分けルール
├── meetings.md    # 議事録フォーマット
├── tasks.md       # タスクフォーマット
├── daily.md       # 日次アジェンダ
├── weekly.md      # 週次サマリー
└── knowledge.md   # ナレッジ管理
```

#### ルールの仕組み

ルールは **対象パスを操作する時に自動で読み込まれる**。

```yaml
---
paths:
  - "inbox/meetings/**"
---
```

上記の場合、`inbox/meetings/` 内のファイルを扱う時に自動適用。

#### 編集例: タスクに優先度を追加

`.claude/rules/tasks.md`:

```markdown
## タスクフォーマット

- [ ] 🔴 タスク内容（担当: XX, 期限: MM/DD）  # 高優先度
- [ ] 🟡 タスク内容（担当: XX, 期限: MM/DD）  # 中優先度
- [ ] 🟢 タスク内容（担当: XX, 期限: MM/DD）  # 低優先度
```

</details>

---

## 連携サービス

COBA は MCP（Model Context Protocol）を通じて外部サービスと連携する。

| サービス | 用途 | 必須 |
|----------|------|:----:|
| Google Calendar | `/generate-daily` で予定を取得 | |
| Slack | チャンネル検索、メッセージ送信、スタンドアップ生成など | |

Slack 連携は `.claude/settings.json` で Slack プラグインとして有効化済み。MCP サーバーの設定は Claude Code 側で行う。

### Slack ビルトインスキル

Slack プラグインを有効にすると、以下のビルトインスキルが使えるようになる。各スキルは COBA のスキルに組み込まれており、秘書経由でも直接でも呼び出せる。

| スキル | 説明 | 使われるスキル |
|--------|------|---------------|
| `slack:channel-digest` | 複数チャンネルのダイジェスト | `/morning`, `/generate-weekly` |
| `slack:standup` | スタンドアップ生成 | `/evening` |
| `slack:find-discussions` | トピック別のディスカッション検索 | `/brainstorm`, `/secretary` |
| `slack:summarize-channel` | チャンネルのアクティビティまとめ | `/secretary` |
| `slack:draft-announcement` | お知らせの下書き作成 | `/secretary` |
| `slack:slack-search` | Slack 検索 | `/secretary` |
| `slack:slack-messaging` | メッセージ作成・送信 | `/secretary` |

## 前提条件

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) がインストール済み

## ライセンス

MIT
