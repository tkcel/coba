# Jira REST API 統合

- **日付**: 2026-03-11
- **関係者**: @根本

## 決定内容

Atlassian MCP が使い物にならなかったため、Jira Cloud REST API を curl ベースのシェルスクリプト（`scripts/jira.sh`）で自前実装する。

## 背景・理由

- Atlassian MCP は接続が不安定で実用に耐えなかった
- Jira 連携は開発室の業務に必要（稲葉さんとの #dev_全体 での合意あり）
- REST API + curl なら依存が少なく、Claude Code の Bash ツールからそのまま呼べる

## アーキテクチャ

- `scripts/jira.sh` が API 呼び出しを一手に担う
- 認証: Basic Auth（API Token）、`~/.config/jira/credentials` に保管
- 出力: JSON（jq で整形、必要フィールドのみ抽出）
- エラー: exit code で分類、429 は自動リトライ

## 統合スキル

secretary, morning, evening, generate-daily, generate-weekly, extract-todo, format-meeting, onboarding
