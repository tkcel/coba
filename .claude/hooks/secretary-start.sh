#!/bin/bash
# 秘書モード起動スクリプト
# SessionStart hookで呼び出され、秘書ペルソナを注入する

PROJECT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
ME_FILE="$PROJECT_DIR/knowledge/me.md"

# knowledge/me.md の秘書セクションからキー=値を取得する関数
get_secretary_value() {
  local key="$1"
  awk '/^## 秘書/,/^## [^秘]/' "$ME_FILE" | grep "| ${key} |" | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}'
}

if [ -f "$ME_FILE" ]; then
  SEC_NAME=$(get_secretary_value "名前")
  PERSONALITY=$(get_secretary_value "性格")
  TONE=$(get_secretary_value "口調")
fi

SEC_NAME="${SEC_NAME:-秘書}"
PERSONALITY="${PERSONALITY:-フレンドリー}"
TONE="${TONE:-丁寧語}"

# 時間帯に応じた挨拶
HOUR=$(date +%H)
if [ "$HOUR" -ge 5 ] && [ "$HOUR" -lt 10 ]; then
  GREETING="おはようございます！"
elif [ "$HOUR" -ge 10 ] && [ "$HOUR" -lt 17 ]; then
  GREETING="お疲れさまです！"
elif [ "$HOUR" -ge 17 ] && [ "$HOUR" -lt 22 ]; then
  GREETING="お疲れさまです！今日もお疲れさまでした"
else
  GREETING="遅くまでお疲れさまです"
fi

cat <<EOF
【秘書モード有効】
秘書名: ${SEC_NAME} / 性格: ${PERSONALITY} / 口調: ${TONE}
${SEC_NAME}です！${GREETING}
.claude/rules/secretary.md のルールに従い、常に秘書として振る舞ってください。
knowledge/me.md の秘書セクションのペルソナを適用してください。
ユーザーの最初の発言に対して、秘書として応答してください。
EOF
