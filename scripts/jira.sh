#!/bin/bash
# =============================================================================
# Jira Cloud REST API Wrapper
# =============================================================================
# Usage: ./scripts/jira.sh <command> [args...]
#
# Commands:
#   myself                              自分の情報を取得
#   search "<JQL>"                      JQL でチケット検索
#   issue <KEY>                         チケット詳細を取得
#   create <project> <type> <summary> [description]  チケット作成
#   transitions <KEY>                   遷移先一覧を取得
#   transition <KEY> <transitionId>     ステータスを変更
#   comment <KEY> "<body>"              コメントを追加
#   projects                            プロジェクト一覧を取得
#   users "<query>"                     ユーザーを検索
#
# Exit codes:
#   0 - 成功
#   1 - 認証エラー (401/403)
#   2 - リソースなし (404)
#   3 - レート制限 (429)
#   4 - その他エラー
# =============================================================================

set -euo pipefail

# --- 認証情報の読み込み ---
CRED_FILE="${JIRA_CRED_FILE:-$HOME/.config/jira/credentials}"

if [[ ! -f "$CRED_FILE" ]]; then
  echo "Error: 認証情報ファイルが見つかりません: $CRED_FILE" >&2
  echo "" >&2
  echo "セットアップ手順:" >&2
  echo "  1. mkdir -p ~/.config/jira" >&2
  echo "  2. 以下の内容で ~/.config/jira/credentials を作成:" >&2
  echo "     JIRA_DOMAIN=your-domain.atlassian.net" >&2
  echo "     JIRA_EMAIL=your-email@example.com" >&2
  echo "     JIRA_API_TOKEN=your-api-token" >&2
  echo "  3. chmod 600 ~/.config/jira/credentials" >&2
  echo "" >&2
  echo "API トークンは以下で発行:" >&2
  echo "  https://id.atlassian.com/manage-profile/security/api-tokens" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$CRED_FILE"

if [[ -z "${JIRA_DOMAIN:-}" || -z "${JIRA_EMAIL:-}" || -z "${JIRA_API_TOKEN:-}" ]]; then
  echo "Error: credentials に JIRA_DOMAIN, JIRA_EMAIL, JIRA_API_TOKEN が必要です" >&2
  exit 1
fi

BASE_URL="https://${JIRA_DOMAIN}/rest/api/3"
AUTH=$(printf '%s:%s' "$JIRA_EMAIL" "$JIRA_API_TOKEN" | base64)
MAX_RETRIES=3

# =============================================================================
# ヘルパー関数
# =============================================================================

# API 呼び出し（リトライ付き）
jira_curl() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"
  local retry=0

  while [[ $retry -lt $MAX_RETRIES ]]; do
    local response
    local http_code

    if [[ -n "$data" ]]; then
      response=$(curl -s -w "\n%{http_code}" \
        -X "$method" \
        -H "Authorization: Basic $AUTH" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "${BASE_URL}${endpoint}" 2>/dev/null)
    else
      response=$(curl -s -w "\n%{http_code}" \
        -X "$method" \
        -H "Authorization: Basic $AUTH" \
        -H "Content-Type: application/json" \
        "${BASE_URL}${endpoint}" 2>/dev/null)
    fi

    http_code=$(echo "$response" | tail -1)
    local body
    body=$(echo "$response" | sed '$d')

    case "$http_code" in
      2[0-9][0-9])
        echo "$body"
        return 0
        ;;
      204)
        echo '{"status":"ok"}'
        return 0
        ;;
      401|403)
        echo "Error: 認証エラー (HTTP $http_code)" >&2
        echo "API トークンを確認してください: https://id.atlassian.com/manage-profile/security/api-tokens" >&2
        return 1
        ;;
      404)
        echo "Error: リソースが見つかりません (HTTP 404)" >&2
        return 2
        ;;
      429)
        retry=$((retry + 1))
        local wait_sec
        wait_sec=$(echo "$body" | jq -r '.retryAfter // 5' 2>/dev/null || echo 5)
        echo "Warning: レート制限 (429)。${wait_sec}秒後にリトライ ($retry/$MAX_RETRIES)..." >&2
        sleep "$wait_sec"
        ;;
      *)
        echo "Error: API エラー (HTTP $http_code)" >&2
        echo "$body" | jq -r '.errorMessages[]? // .message // empty' 2>/dev/null >&2
        return 4
        ;;
    esac
  done

  echo "Error: リトライ上限に達しました" >&2
  return 3
}

# 平文テキストを ADF (Atlassian Document Format) に変換
text_to_adf() {
  local text="$1"
  jq -n --arg t "$text" '{
    type: "doc",
    version: 1,
    content: [{
      type: "paragraph",
      content: [{
        type: "text",
        text: $t
      }]
    }]
  }'
}

# =============================================================================
# サブコマンド
# =============================================================================

# --- myself: 自分の情報 ---
cmd_myself() {
  local result
  result=$(jira_curl GET "/myself") || return $?

  echo "$result" | jq '{
    accountId: .accountId,
    displayName: .displayName,
    emailAddress: .emailAddress,
    active: .active
  }'
}

# --- search: JQL 検索 ---
cmd_search() {
  local jql="${1:?Error: JQL を指定してください}"
  local max_results="${2:-50}"

  local data
  data=$(jq -n \
    --arg jql "$jql" \
    --argjson max "$max_results" \
    '{
      jql: $jql,
      maxResults: $max,
      fields: ["summary","status","priority","assignee","updated","duedate","issuetype"]
    }')

  local result
  result=$(jira_curl POST "/search/jql" "$data") || return $?

  echo "$result" | jq '{
    total: .total,
    issues: [.issues[]? | {
      key: .key,
      summary: .fields.summary,
      status: .fields.status.name,
      priority: .fields.priority.name,
      assignee: (.fields.assignee.displayName // "未割当"),
      updated: (.fields.updated | split("T")[0]),
      duedate: (.fields.duedate // "なし"),
      type: .fields.issuetype.name
    }]
  }'
}

# --- issue: チケット詳細 ---
cmd_issue() {
  local key="${1:?Error: チケットキーを指定してください}"

  local result
  result=$(jira_curl GET "/issue/${key}?fields=summary,status,priority,assignee,reporter,created,updated,duedate,description,comment,issuetype,labels,components") || return $?

  echo "$result" | jq '{
    key: .key,
    summary: .fields.summary,
    type: .fields.issuetype.name,
    status: .fields.status.name,
    priority: .fields.priority.name,
    assignee: (.fields.assignee.displayName // "未割当"),
    reporter: (.fields.reporter.displayName // "不明"),
    created: (.fields.created | split("T")[0]),
    updated: (.fields.updated | split("T")[0]),
    duedate: (.fields.duedate // "なし"),
    labels: (.fields.labels // []),
    comments: [.fields.comment.comments[]? | {
      author: .author.displayName,
      created: (.created | split("T")[0]),
      body: (.body.content[]?.content[]?.text // "")
    } | select(.body != "")]
  }'
}

# --- create: チケット作成 ---
cmd_create() {
  local project="${1:?Error: プロジェクトキーを指定してください}"
  local issuetype="${2:?Error: 課題タイプを指定してください (Task, Bug, Story 等)}"
  local summary="${3:?Error: タイトルを指定してください}"
  local description="${4:-}"

  local data
  if [[ -n "$description" ]]; then
    local adf_desc
    adf_desc=$(text_to_adf "$description")
    data=$(jq -n \
      --arg proj "$project" \
      --arg type "$issuetype" \
      --arg summ "$summary" \
      --argjson desc "$adf_desc" \
      '{
        fields: {
          project: { key: $proj },
          issuetype: { name: $type },
          summary: $summ,
          description: $desc
        }
      }')
  else
    data=$(jq -n \
      --arg proj "$project" \
      --arg type "$issuetype" \
      --arg summ "$summary" \
      '{
        fields: {
          project: { key: $proj },
          issuetype: { name: $type },
          summary: $summ
        }
      }')
  fi

  local result
  result=$(jira_curl POST "/issue" "$data") || return $?

  echo "$result" | jq '{
    key: .key,
    id: .id,
    url: ("https://'"${JIRA_DOMAIN}"'/browse/" + .key)
  }'
}

# --- transitions: 遷移先一覧 ---
cmd_transitions() {
  local key="${1:?Error: チケットキーを指定してください}"

  local result
  result=$(jira_curl GET "/issue/${key}/transitions") || return $?

  echo "$result" | jq '[.transitions[]? | {
    id: .id,
    name: .name,
    to: .to.name
  }]'
}

# --- transition: ステータス変更 ---
cmd_transition() {
  local key="${1:?Error: チケットキーを指定してください}"
  local transition_id="${2:?Error: 遷移IDを指定してください（transitions コマンドで確認）}"

  local data
  data=$(jq -n --arg tid "$transition_id" '{
    transition: { id: $tid }
  }')

  jira_curl POST "/issue/${key}/transitions" "$data" || return $?
  echo "{\"status\":\"ok\",\"message\":\"${key} のステータスを変更しました\"}"
}

# --- comment: コメント追加 ---
cmd_comment() {
  local key="${1:?Error: チケットキーを指定してください}"
  local body="${2:?Error: コメント本文を指定してください}"

  local adf_body
  adf_body=$(text_to_adf "$body")

  local data
  data=$(jq -n --argjson b "$adf_body" '{ body: $b }')

  local result
  result=$(jira_curl POST "/issue/${key}/comment" "$data") || return $?

  echo "$result" | jq '{
    id: .id,
    author: .author.displayName,
    created: (.created | split("T")[0]),
    message: "コメントを追加しました"
  }'
}

# --- projects: プロジェクト一覧 ---
cmd_projects() {
  local result
  result=$(jira_curl GET "/project") || return $?

  echo "$result" | jq '[.[]? | {
    key: .key,
    name: .name,
    style: .style
  }]'
}

# --- users: ユーザー検索 ---
cmd_users() {
  local query="${1:?Error: 検索クエリを指定してください}"
  local encoded_query
  encoded_query=$(python3 -c "import urllib.parse; print(urllib.parse.quote('''$query'''))" 2>/dev/null || echo "$query")

  local result
  result=$(jira_curl GET "/user/search?query=${encoded_query}&maxResults=10") || return $?

  echo "$result" | jq '[.[]? | {
    accountId: .accountId,
    displayName: .displayName,
    emailAddress: (.emailAddress // "非公開"),
    active: .active
  }]'
}

# =============================================================================
# メインルーター
# =============================================================================

case "${1:-}" in
  myself)     cmd_myself ;;
  search)     cmd_search "${2:-}" "${3:-}" ;;
  issue)      cmd_issue "${2:-}" ;;
  create)     cmd_create "${2:-}" "${3:-}" "${4:-}" "${5:-}" ;;
  transitions) cmd_transitions "${2:-}" ;;
  transition) cmd_transition "${2:-}" "${3:-}" ;;
  comment)    cmd_comment "${2:-}" "${3:-}" ;;
  projects)   cmd_projects ;;
  users)      cmd_users "${2:-}" ;;
  *)
    echo "Jira Cloud REST API Wrapper" >&2
    echo "" >&2
    echo "Usage: $0 <command> [args...]" >&2
    echo "" >&2
    echo "Commands:" >&2
    echo "  myself                              自分の情報を取得" >&2
    echo "  search \"<JQL>\"                      JQL でチケット検索" >&2
    echo "  issue <KEY>                         チケット詳細を取得" >&2
    echo "  create <project> <type> <summary> [description]" >&2
    echo "                                      チケット作成" >&2
    echo "  transitions <KEY>                   遷移先一覧を取得" >&2
    echo "  transition <KEY> <transitionId>     ステータスを変更" >&2
    echo "  comment <KEY> \"<body>\"              コメントを追加" >&2
    echo "  projects                            プロジェクト一覧を取得" >&2
    echo "  users \"<query>\"                     ユーザーを検索" >&2
    exit 4
    ;;
esac
