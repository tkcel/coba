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
git clone https://github.com/yourname/coba.git ~/coba
cd ~/coba
```

### 2. Claude Code で開く

```bash
claude
```

### 3. オンボーディング

```
/onboarding
```

対話形式で初期設定。名前、働き方、秘書の名前などを設定する。

### 4. 秘書を呼ぶ

```
/secretary
```

何でも相談できる窓口。タスク確認、整理、壁打ち、メモ—全部ここから。

## フォルダ構成

```
coba/
├── CLAUDE.md              ← プロジェクト概要（軽量）
├── .claude/
│   ├── commands/          ← スキル（スラッシュコマンド）
│   │   ├── secretary.md       ← 秘書（窓口）
│   │   ├── onboarding.md      ← 初期セットアップ
│   │   ├── triage-tmp.md
│   │   ├── format-meeting.md
│   │   ├── extract-todo.md
│   │   ├── generate-daily.md
│   │   ├── generate-weekly.md
│   │   └── wrap-evening.md
│   └── rules/             ← ワークフロールール（パス別に発動）
│       ├── secretary.md       ← 秘書の口調・ルール
│       ├── tmp.md
│       ├── meetings.md
│       ├── tasks.md
│       ├── daily.md
│       ├── weekly.md
│       └── knowledge.md
├── tmp/                   ← ここにファイルを落とす（入口）
├── inbox/                 ← 分類・整形されたファイル
│   ├── meetings/
│   ├── tasks/
│   ├── notes/
│   └── other/
├── daily/                 ← 日次アジェンダ
├── weekly/                ← 週次サマリー
└── knowledge/             ← 蓄積ナレッジ（育てる）
    ├── me.md                  ← オーナー情報
    ├── people.md
    ├── glossary.md
    └── decisions/
```

## 設計思想

- **CLAUDE.md**: セッション開始時に読み込まれる。プロジェクト概要だけ。軽量に保つ
- **.claude/commands/**: スラッシュコマンドで明示的に呼び出すスキル
- **.claude/rules/**: 該当フォルダを扱う時に自動で注入される。セッション後半でも効く

## スキル一覧

| コマンド | 説明 |
|----------|------|
| `/secretary` | 秘書。窓口として何でも相談、他スキルを自動呼び出し |
| `/onboarding` | 初期セットアップ。名前、働き方、秘書の名前を設定 |
| `/triage-tmp` | tmp/ を inbox/ に振り分け |
| `/format-meeting` | 議事録を構造化フォーマットに整形 |
| `/extract-todo` | 議事録からTODOを抽出 |
| `/generate-daily` | Google Calendar から日次アジェンダ生成 |
| `/generate-weekly` | 週次サマリー生成 |
| `/wrap-evening` | 夕方一括処理（振り分け→整形→TODO抽出） |

## 秘書について

`/secretary` は窓口として全体を統括するスキル。

**できること:**
- 「今日やること教えて」→ 予定・タスクを報告
- 「整理して」→ `/triage-tmp` を自動実行
- 「メモ取って」→ tmp/ にキャプチャ
- 「壁打ちしたい」→ 対話モードで深掘り
- 「ダッシュボード」→ 全体状況をサマリー

**特徴:**
- 丁寧だがフランクな口調
- 主体的に提案（「ついでにこれもやっておきましょうか？」）
- 必要に応じて他スキルを自動で呼び出す
- `/onboarding` で名前をつけられる

## 典型的な1日

```
朝    →  /secretary（今日やること確認）
日中  →   会議メモを tmp/ にポイポイ投げる
夕方  →  /secretary「整理して」（または /wrap-evening）
週末  →  /generate-weekly
```

## カスタマイズ

### knowledge/ を育てる

`knowledge/people.md` にメンバー情報を、`knowledge/glossary.md` に社内用語を追記していくと、AIの出力精度が上がっていく。

### スキルを編集

`.claude/commands/` 内のファイルを編集すれば、各スキルの挙動をカスタマイズできる。

### ルールを編集

`.claude/rules/` 内のファイルを編集すれば、MTG分類ルールや出力フォーマットをカスタマイズできる。

### 秘書の口調を変える

`.claude/rules/secretary.md` を編集すれば、秘書の話し方をカスタマイズできる。

## 前提条件

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) がインストール済み
- Google Calendar 連携（MCP経由）が設定済み（daily-agenda 用）

## ライセンス

MIT
