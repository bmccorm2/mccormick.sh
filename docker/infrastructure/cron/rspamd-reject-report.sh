#!/usr/bin/env sh

set -eu

MAIL_CONTAINER="mail"
EMAIL="manager@firestonelodging.com"

LOG_FILE="/var/log/rspamd/rspamd.log"

TMP_BODY="/tmp/rspamd_body.txt"
TMP_MSG="/tmp/rspamd_message.txt"

NOW_RFC2822=$(date -R)
TODAY_ISO=$(date +%Y-%m-%d)
TODAY_SYSLOG=$(date '+%b %e')

# Collect today's messages where Rspamd's final action was reject.
grep -E "^($TODAY_ISO|$TODAY_SYSLOG)" "$LOG_FILE" \
  | grep "rspamd_task_write_log:" \
  | grep -E "\(default: [A-Z] \(reject\):" > "$TMP_BODY" || true

# Build body + count
if [ -s "$TMP_BODY" ]; then
  COUNT=$(wc -l < "$TMP_BODY" | tr -d ' ')
  BODY=$(cat "$TMP_BODY")
else
  COUNT=0
  BODY="No rejected messages found for today."
fi

MSG_ID="$(date +%s).$$@firestonelodging.com"

cat > "$TMP_MSG" <<EOF
From: rspamd-report@firestonelodging.com
To: $EMAIL
Subject: Rspamd Reject Report ($COUNT messages)
Date: $NOW_RFC2822
Message-ID: <$MSG_ID>
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8

Rspamd rejected $COUNT messages:

$BODY
EOF

docker exec -i "$MAIL_CONTAINER" sendmail -t < "$TMP_MSG"

rm -f "$TMP_BODY" "$TMP_MSG"
