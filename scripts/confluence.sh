#!/bin/bash
# =============================================================================
# Confluence Cloud REST API Wrapper
# =============================================================================
# Usage: ./scripts/confluence.sh <command> [args...]
#
# Commands:
#   spaces                              スペース一覧を取得
#   search "<CQL>"                      CQL でページ検索
#   page <pageId>                       ページ詳細を取得（本文含む）
#   page-by-title <spaceKey> "<title>"  タイトルでページ取得
#   children <pageId>                   子ページ一覧を取得
#   create <spaceId> "<title>" "<body>" [parentId]  ページ作成
#   update <pageId> "<title>" "<body>"  ページ更新
#   comment <pageId> "<body>"           コメント追加
#   comments <pageId>                   コメント一覧を取得
#
# Exit codes:
#   0 - 成功
#   1 - 認証エラー (401/403)
#   2 - リソースなし (404)
#   3 - レート制限 (429)
#   4 - その他エラー
# =============================================================================

set -euo pipefail

# --- 認証情報の読み込み（Jira と共通） ---
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
  exit 1
fi

# shellcheck source=/dev/null
source "$CRED_FILE"

if [[ -z "${JIRA_DOMAIN:-}" || -z "${JIRA_EMAIL:-}" || -z "${JIRA_API_TOKEN:-}" ]]; then
  echo "Error: credentials に JIRA_DOMAIN, JIRA_EMAIL, JIRA_API_TOKEN が必要です" >&2
  exit 1
fi

BASE_URL_V2="https://${JIRA_DOMAIN}/wiki/api/v2"
BASE_URL_V1="https://${JIRA_DOMAIN}/wiki/rest/api"
AUTH=$(printf '%s:%s' "$JIRA_EMAIL" "$JIRA_API_TOKEN" | base64)
MAX_RETRIES=3

# =============================================================================
# ヘルパー関数
# =============================================================================

# API 呼び出し（リトライ付き）
confluence_curl() {
  local method="$1"
  local url="$2"
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
        "$url" 2>/dev/null)
    else
      response=$(curl -s -w "\n%{http_code}" \
        -X "$method" \
        -H "Authorization: Basic $AUTH" \
        -H "Content-Type: application/json" \
        "$url" 2>/dev/null)
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
        echo "$body" | jq -r '.message // .errorMessages[]? // empty' 2>/dev/null >&2
        return 4
        ;;
    esac
  done

  echo "Error: リトライ上限に達しました" >&2
  return 3
}

# URL エンコード
url_encode() {
  python3 -c "import urllib.parse; print(urllib.parse.quote('''$1'''))" 2>/dev/null || echo "$1"
}

# =============================================================================
# サブコマンド
# =============================================================================

# --- spaces: スペース一覧 ---
cmd_spaces() {
  local result
  result=$(confluence_curl GET "${BASE_URL_V2}/spaces?limit=50") || return $?

  echo "$result" | jq '{
    results: [.results[]? | {
      id: .id,
      key: .key,
      name: .name,
      type: .type,
      status: .status
    }]
  }'
}

# --- search: CQL 検索 ---
cmd_search() {
  local cql="${1:?Error: CQL を指定してください}"
  local limit="${2:-20}"
  local encoded_cql
  encoded_cql=$(url_encode "$cql")

  local result
  result=$(confluence_curl GET "${BASE_URL_V1}/content/search?cql=${encoded_cql}&limit=${limit}&expand=version,space") || return $?

  echo "$result" | jq '{
    total: (.totalSize // .size),
    results: [.results[]? | {
      id: .id,
      title: .title,
      type: .type,
      spaceKey: .space.key,
      spaceName: .space.name,
      version: .version.number,
      lastUpdated: (.version.when | split("T")[0]),
      url: ("https://'"${JIRA_DOMAIN}"'/wiki" + ._links.webui)
    }]
  }'
}

# --- page: ページ詳細 ---
cmd_page() {
  local page_id="${1:?Error: ページIDを指定してください}"

  local result
  result=$(confluence_curl GET "${BASE_URL_V2}/pages/${page_id}?body-format=storage") || return $?

  echo "$result" | jq '{
    id: .id,
    title: .title,
    spaceId: .spaceId,
    status: .status,
    version: .version.number,
    createdAt: (.createdAt | split("T")[0]),
    lastUpdated: (.version.createdAt | split("T")[0]),
    body: .body.storage.value,
    url: ("https://'"${JIRA_DOMAIN}"'/wiki" + ._links.webui)
  }'
}

# --- page-by-title: タイトルでページ取得 ---
cmd_page_by_title() {
  local space_key="${1:?Error: スペースキーを指定してください}"
  local title="${2:?Error: タイトルを指定してください}"
  local encoded_title
  encoded_title=$(url_encode "$title")

  local result
  result=$(confluence_curl GET "${BASE_URL_V1}/content?spaceKey=${space_key}&title=${encoded_title}&expand=version,body.storage,space") || return $?

  echo "$result" | jq '{
    total: .size,
    results: [.results[]? | {
      id: .id,
      title: .title,
      spaceKey: .space.key,
      version: .version.number,
      lastUpdated: (.version.when | split("T")[0]),
      body: .body.storage.value,
      url: ("https://'"${JIRA_DOMAIN}"'/wiki" + ._links.webui)
    }]
  }'
}

# --- children: 子ページ一覧 ---
cmd_children() {
  local page_id="${1:?Error: ページIDを指定してください}"

  local result
  result=$(confluence_curl GET "${BASE_URL_V2}/pages/${page_id}/children?limit=50") || return $?

  echo "$result" | jq '{
    results: [.results[]? | {
      id: .id,
      title: .title,
      status: .status
    }]
  }'
}

# --- create: ページ作成 ---
cmd_create() {
  local space_id="${1:?Error: スペースIDを指定してください}"
  local title="${2:?Error: タイトルを指定してください}"
  local body="${3:?Error: 本文を指定してください}"
  local parent_id="${4:-}"

  local data
  if [[ -n "$parent_id" ]]; then
    data=$(jq -n \
      --arg sid "$space_id" \
      --arg t "$title" \
      --arg b "$body" \
      --arg pid "$parent_id" \
      '{
        spaceId: $sid,
        status: "current",
        title: $t,
        parentId: $pid,
        body: {
          representation: "storage",
          value: $b
        }
      }')
  else
    data=$(jq -n \
      --arg sid "$space_id" \
      --arg t "$title" \
      --arg b "$body" \
      '{
        spaceId: $sid,
        status: "current",
        title: $t,
        body: {
          representation: "storage",
          value: $b
        }
      }')
  fi

  local result
  result=$(confluence_curl POST "${BASE_URL_V2}/pages" "$data") || return $?

  echo "$result" | jq '{
    id: .id,
    title: .title,
    version: .version.number,
    url: ("https://'"${JIRA_DOMAIN}"'/wiki" + ._links.webui)
  }'
}

# --- update: ページ更新 ---
cmd_update() {
  local page_id="${1:?Error: ページIDを指定してください}"
  local title="${2:?Error: タイトルを指定してください}"
  local body="${3:?Error: 本文を指定してください}"

  # 現在のバージョンを取得
  local current
  current=$(confluence_curl GET "${BASE_URL_V2}/pages/${page_id}") || return $?
  local current_version
  current_version=$(echo "$current" | jq -r '.version.number')
  local new_version=$((current_version + 1))

  local data
  data=$(jq -n \
    --arg pid "$page_id" \
    --arg t "$title" \
    --arg b "$body" \
    --argjson v "$new_version" \
    '{
      id: $pid,
      status: "current",
      title: $t,
      body: {
        representation: "storage",
        value: $b
      },
      version: {
        number: $v
      }
    }')

  local result
  result=$(confluence_curl PUT "${BASE_URL_V2}/pages/${page_id}" "$data") || return $?

  echo "$result" | jq '{
    id: .id,
    title: .title,
    version: .version.number,
    url: ("https://'"${JIRA_DOMAIN}"'/wiki" + ._links.webui),
    message: "ページを更新しました"
  }'
}

# --- comment: コメント追加 ---
cmd_comment() {
  local page_id="${1:?Error: ページIDを指定してください}"
  local body="${2:?Error: コメント本文を指定してください}"

  local data
  data=$(jq -n \
    --arg b "$body" \
    '{
      body: {
        representation: "storage",
        value: ("<p>" + $b + "</p>")
      }
    }')

  local result
  result=$(confluence_curl POST "${BASE_URL_V2}/pages/${page_id}/footer-comments" "$data") || return $?

  echo "$result" | jq '{
    id: .id,
    message: "コメントを追加しました"
  }'
}

# --- comments: コメント一覧 ---
cmd_comments() {
  local page_id="${1:?Error: ページIDを指定してください}"

  local result
  result=$(confluence_curl GET "${BASE_URL_V2}/pages/${page_id}/footer-comments?body-format=storage") || return $?

  echo "$result" | jq '{
    results: [.results[]? | {
      id: .id,
      createdAt: (.createdAt | split("T")[0]),
      body: .body.storage.value
    }]
  }'
}

# =============================================================================
# メインルーター
# =============================================================================

case "${1:-}" in
  spaces)        cmd_spaces ;;
  search)        cmd_search "${2:-}" "${3:-}" ;;
  page)          cmd_page "${2:-}" ;;
  page-by-title) cmd_page_by_title "${2:-}" "${3:-}" ;;
  children)      cmd_children "${2:-}" ;;
  create)        cmd_create "${2:-}" "${3:-}" "${4:-}" "${5:-}" ;;
  update)        cmd_update "${2:-}" "${3:-}" "${4:-}" ;;
  comment)       cmd_comment "${2:-}" "${3:-}" ;;
  comments)      cmd_comments "${2:-}" ;;
  *)
    echo "Confluence Cloud REST API Wrapper" >&2
    echo "" >&2
    echo "Usage: $0 <command> [args...]" >&2
    echo "" >&2
    echo "Commands:" >&2
    echo "  spaces                              スペース一覧を取得" >&2
    echo "  search \"<CQL>\"                      CQL でページ検索" >&2
    echo "  page <pageId>                       ページ詳細を取得" >&2
    echo "  page-by-title <spaceKey> \"<title>\"  タイトルでページ取得" >&2
    echo "  children <pageId>                   子ページ一覧を取得" >&2
    echo "  create <spaceId> \"<title>\" \"<body>\" [parentId]" >&2
    echo "                                      ページ作成" >&2
    echo "  update <pageId> \"<title>\" \"<body>\"  ページ更新" >&2
    echo "  comment <pageId> \"<body>\"            コメント追加" >&2
    echo "  comments <pageId>                   コメント一覧を取得" >&2
    exit 4
    ;;
esac
