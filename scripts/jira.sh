#!/bin/bash
#
# jira.sh - Jira Cloud REST API ラッパースクリプト
#
# Usage: ./scripts/jira.sh <command> [args]
#
# Commands:
#   myself                              自分の情報取得
#   search "<JQL>"                      JQL検索
#   issue <KEY>                         チケット詳細
#   create <project> <type> <summary> [desc]  チケット作成
#   transitions <KEY>                   遷移先一覧
#   transition <KEY> <transitionId>     ステータス変更
#   comment <KEY> "<body>"              コメント追加
#   projects                            プロジェクト一覧
#   users "<query>"                     ユーザー検索
#
# Dependencies: curl, jq, base64 (all macOS standard)
#

set -euo pipefail

# --- 認証情報の読み込み ---

CREDENTIALS_FILE="${HOME}/.config/jira/credentials"

if [[ ! -f "$CREDENTIALS_FILE" ]]; then
  echo "Error: 認証情報ファイルが見つかりません: $CREDENTIALS_FILE" >&2
  echo "以下の形式で作成してください:" >&2
  echo "" >&2
  echo "  JIRA_DOMAIN=your-domain.atlassian.net" >&2
  echo "  JIRA_EMAIL=your-email@example.com" >&2
  echo "  JIRA_API_TOKEN=your-api-token" >&2
  exit 1
fi

# shellcheck source=/dev/null
source "$CREDENTIALS_FILE"

if [[ -z "${JIRA_DOMAIN:-}" || -z "${JIRA_EMAIL:-}" || -z "${JIRA_API_TOKEN:-}" ]]; then
  echo "Error: JIRA_DOMAIN, JIRA_EMAIL, JIRA_API_TOKEN が credentials に必要です" >&2
  exit 1
fi

BASE_URL="https://${JIRA_DOMAIN}/rest/api/3"
AUTH_HEADER="Authorization: Basic $(printf '%s:%s' "$JIRA_EMAIL" "$JIRA_API_TOKEN" | base64)"

# --- ヘルパー関数 ---

# 平文テキストを ADF（Atlassian Document Format）に変換
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

# API リクエスト（レート制限対応、最大3回リトライ）
api_request() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"
  local max_retries=3
  local retry=0

  while [[ $retry -lt $max_retries ]]; do
    local http_code
    local response

    if [[ -n "$data" ]]; then
      response=$(curl -s -w "\n%{http_code}" \
        -X "$method" \
        -H "$AUTH_HEADER" \
        -H "Content-Type: application/json" \
        -d "$data" \
        "${BASE_URL}${endpoint}" 2>/dev/null)
    else
      response=$(curl -s -w "\n%{http_code}" \
        -X "$method" \
        -H "$AUTH_HEADER" \
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
      401|403)
        echo "Error: 認証エラー (HTTP $http_code) - APIトークンを確認してください" >&2
        return 1
        ;;
      404)
        echo "Error: リソースが見つかりません (HTTP 404)" >&2
        return 2
        ;;
      429)
        retry=$((retry + 1))
        if [[ $retry -lt $max_retries ]]; then
          local wait_sec
          wait_sec=$(echo "$body" | jq -r '.retryAfter // 5' 2>/dev/null || echo 5)
          echo "Warning: レート制限 (429) - ${wait_sec}秒後にリトライ ($retry/$max_retries)" >&2
          sleep "$wait_sec"
        else
          echo "Error: レート制限 - リトライ上限に達しました" >&2
          return 3
        fi
        ;;
      *)
        local error_msg
        error_msg=$(echo "$body" | jq -r '.errorMessages[0] // .message // "不明なエラー"' 2>/dev/null || echo "不明なエラー")
        echo "Error: $error_msg (HTTP $http_code)" >&2
        return 4
        ;;
    esac
  done
}

# --- サブコマンド ---

cmd_myself() {
  local raw
  raw=$(api_request GET "/myself") || return $?
  echo "$raw" | jq '{
    accountId: .accountId,
    displayName: .displayName,
    emailAddress: .emailAddress,
    active: .active
  }'
}

cmd_search() {
  local jql="$1"
  local max_results="${2:-50}"
  local encoded_jql
  encoded_jql=$(printf '%s' "$jql" | jq -sRr @uri)
  local raw
  raw=$(api_request GET "/search?jql=${encoded_jql}&maxResults=${max_results}&fields=summary,status,priority,assignee,updated,duedate,issuetype") || return $?
  echo "$raw" | jq '{
    total: .total,
    issues: [.issues[] | {
      key: .key,
      summary: .fields.summary,
      type: .fields.issuetype.name,
      status: .fields.status.name,
      priority: .fields.priority.name,
      assignee: (.fields.assignee.displayName // "未割当"),
      updated: (.fields.updated | split(".")[0]),
      duedate: (.fields.duedate // "未設定")
    }]
  }'
}

cmd_issue() {
  local key="$1"
  local raw
  raw=$(api_request GET "/issue/${key}?fields=summary,status,priority,assignee,reporter,created,updated,duedate,description,issuetype,project,comment") || return $?
  echo "$raw" | jq '{
    key: .key,
    summary: .fields.summary,
    type: .fields.issuetype.name,
    project: .fields.project.key,
    status: .fields.status.name,
    priority: .fields.priority.name,
    assignee: (.fields.assignee.displayName // "未割当"),
    reporter: (.fields.reporter.displayName // "不明"),
    created: (.fields.created | split(".")[0]),
    updated: (.fields.updated | split(".")[0]),
    duedate: (.fields.duedate // "未設定"),
    description: (if .fields.description then
      [.fields.description.content[]? | .content[]? | select(.type == "text") | .text] | join("\n")
    else
      "なし"
    end),
    comments: [.fields.comment.comments[-3:]? | {
      author: .author.displayName,
      created: (.created | split(".")[0]),
      body: ([.body.content[]? | .content[]? | select(.type == "text") | .text] | join("\n"))
    }]
  }'
}

cmd_create() {
  local project="$1"
  local issue_type="$2"
  local summary="$3"
  local description="${4:-}"

  local data
  if [[ -n "$description" ]]; then
    local adf
    adf=$(text_to_adf "$description")
    data=$(jq -n \
      --arg proj "$project" \
      --arg type "$issue_type" \
      --arg sum "$summary" \
      --argjson desc "$adf" \
      '{
        fields: {
          project: { key: $proj },
          issuetype: { name: $type },
          summary: $sum,
          description: $desc
        }
      }')
  else
    data=$(jq -n \
      --arg proj "$project" \
      --arg type "$issue_type" \
      --arg sum "$summary" \
      '{
        fields: {
          project: { key: $proj },
          issuetype: { name: $type },
          summary: $sum
        }
      }')
  fi

  local raw
  raw=$(api_request POST "/issue" "$data") || return $?
  echo "$raw" | jq '{
    key: .key,
    id: .id,
    url: ("https://'"${JIRA_DOMAIN}"'/browse/" + .key)
  }'
}

cmd_transitions() {
  local key="$1"
  local raw
  raw=$(api_request GET "/issue/${key}/transitions") || return $?
  echo "$raw" | jq '{
    transitions: [.transitions[] | {
      id: .id,
      name: .name,
      to: .to.name
    }]
  }'
}

cmd_transition() {
  local key="$1"
  local transition_id="$2"
  local data
  data=$(jq -n --arg id "$transition_id" '{ transition: { id: $id } }')
  api_request POST "/issue/${key}/transitions" "$data" > /dev/null || return $?
  echo "{\"status\": \"ok\", \"message\": \"${key} のステータスを変更しました\"}"
}

cmd_comment() {
  local key="$1"
  local body_text="$2"
  local adf
  adf=$(text_to_adf "$body_text")
  local data
  data=$(jq -n --argjson body "$adf" '{ body: $body }')
  local raw
  raw=$(api_request POST "/issue/${key}/comment" "$data") || return $?
  echo "$raw" | jq '{
    id: .id,
    author: .author.displayName,
    created: (.created | split(".")[0]),
    message: "コメントを追加しました"
  }'
}

cmd_projects() {
  local raw
  raw=$(api_request GET "/project") || return $?
  echo "$raw" | jq '[.[] | {
    key: .key,
    name: .name,
    style: .style
  }]'
}

cmd_users() {
  local query="$1"
  local encoded_query
  encoded_query=$(printf '%s' "$query" | jq -sRr @uri)
  local raw
  raw=$(api_request GET "/user/search?query=${encoded_query}&maxResults=10") || return $?
  echo "$raw" | jq '[.[] | {
    accountId: .accountId,
    displayName: .displayName,
    emailAddress: .emailAddress,
    active: .active
  }]'
}

# --- メイン ---

show_usage() {
  echo "Usage: $0 <command> [args]"
  echo ""
  echo "Commands:"
  echo "  myself                              自分の情報取得"
  echo "  search \"<JQL>\"                      JQL検索"
  echo "  issue <KEY>                         チケット詳細"
  echo "  create <project> <type> <summary> [desc]  チケット作成"
  echo "  transitions <KEY>                   遷移先一覧"
  echo "  transition <KEY> <transitionId>     ステータス変更"
  echo "  comment <KEY> \"<body>\"              コメント追加"
  echo "  projects                            プロジェクト一覧"
  echo "  users \"<query>\"                     ユーザー検索"
}

if [[ $# -lt 1 ]]; then
  show_usage
  exit 1
fi

command="$1"
shift

case "$command" in
  myself)
    cmd_myself
    ;;
  search)
    [[ $# -lt 1 ]] && { echo "Error: JQL が必要です" >&2; exit 1; }
    cmd_search "$1" "${2:-50}"
    ;;
  issue)
    [[ $# -lt 1 ]] && { echo "Error: チケットキーが必要です" >&2; exit 1; }
    cmd_issue "$1"
    ;;
  create)
    [[ $# -lt 3 ]] && { echo "Error: project, type, summary が必要です" >&2; exit 1; }
    cmd_create "$1" "$2" "$3" "${4:-}"
    ;;
  transitions)
    [[ $# -lt 1 ]] && { echo "Error: チケットキーが必要です" >&2; exit 1; }
    cmd_transitions "$1"
    ;;
  transition)
    [[ $# -lt 2 ]] && { echo "Error: チケットキーと transitionId が必要です" >&2; exit 1; }
    cmd_transition "$1" "$2"
    ;;
  comment)
    [[ $# -lt 2 ]] && { echo "Error: チケットキーとコメント本文が必要です" >&2; exit 1; }
    cmd_comment "$1" "$2"
    ;;
  projects)
    cmd_projects
    ;;
  users)
    [[ $# -lt 1 ]] && { echo "Error: 検索クエリが必要です" >&2; exit 1; }
    cmd_users "$1"
    ;;
  help|--help|-h)
    show_usage
    ;;
  *)
    echo "Error: 不明なコマンド: $command" >&2
    show_usage
    exit 1
    ;;
esac
