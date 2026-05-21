#!/usr/bin/env sh

set -eu

MAIL_CONTAINER="mail"
EMAIL="manager@firestonelodging.com"

# BusyBox images usually do not include zoneinfo files, so America/Denver can
# fall back to UTC. Use a POSIX TZ string that BusyBox can apply directly.
if [ "${TZ:-}" = "America/Denver" ]; then
  TZ="MST7MDT,M3.2.0,M11.1.0"
  export TZ
fi

LOG_FILE="/var/log/rspamd/rspamd.log"
LOG_FILES="/var/log/rspamd/rspamd.log*"

TMP_BODY="/tmp/rspamd_body.txt"
TMP_MSG="/tmp/rspamd_message.txt"
TMP_MATCHES="/tmp/rspamd_matches.txt"

NOW_RFC2822=$(date -R)
NOW_EPOCH=$(date '+%s')
START_EPOCH=$((NOW_EPOCH - 86400))
NOW_ISO=$(date '+%Y-%m-%d %H:%M:%S')
START_ISO=$(date -d "@$START_EPOCH" '+%Y-%m-%d %H:%M:%S')
CURRENT_YEAR=$(date '+%Y')
PREVIOUS_YEAR=$((CURRENT_YEAR - 1))

# Collect messages from the last 24 hours where Rspamd's final action was reject.
for log_file in $LOG_FILES; do
  [ -r "$log_file" ] || continue

  awk -v start="$START_ISO" -v now="$NOW_ISO" \
    -v current_year="$CURRENT_YEAR" -v previous_year="$PREVIOUS_YEAR" '
    BEGIN {
      months["Jan"] = "01"; months["Feb"] = "02"; months["Mar"] = "03";
      months["Apr"] = "04"; months["May"] = "05"; months["Jun"] = "06";
      months["Jul"] = "07"; months["Aug"] = "08"; months["Sep"] = "09";
      months["Oct"] = "10"; months["Nov"] = "11"; months["Dec"] = "12";
    }
    {
      ts = "";
      if ($1 ~ /^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/ &&
          $2 ~ /^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/) {
        ts = substr($0, 1, 19);
      } else if (($1 in months) && $2 ~ /^[0-9][0-9]*$/ &&
          $3 ~ /^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/) {
        day = sprintf("%02d", $2);
        ts = current_year "-" months[$1] "-" day " " $3;
        if (ts > now) {
          ts = previous_year "-" months[$1] "-" day " " $3;
        }
      }
      if (ts >= start && ts <= now) {
        print;
      }
    }' "$log_file"
done > "$TMP_MATCHES"

grep "rspamd_task_write_log:" "$TMP_MATCHES" \
  | grep -E "\(default: [A-Z] \(reject\):" > "$TMP_BODY" || true

# Build body + count
if [ -s "$TMP_BODY" ]; then
  COUNT=$(wc -l < "$TMP_BODY" | tr -d ' ')
  BODY=$(cat "$TMP_BODY")
else
  COUNT=0
  BODY="No rejected messages found in the last 24 hours."
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

Rspamd rejected $COUNT messages in the last 24 hours:

Window: $START_ISO through $NOW_ISO
Log files: $LOG_FILES

$BODY
EOF

docker exec -i "$MAIL_CONTAINER" sendmail -t < "$TMP_MSG"

rm -f "$TMP_BODY" "$TMP_MSG" "$TMP_MATCHES"
