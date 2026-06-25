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
TMP_FLAGGED="/tmp/rspamd_flagged.txt"
TMP_REJECTED="/tmp/rspamd_rejected.txt"

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
  | grep -E "\(default: [A-Z] \(add header\):" > "$TMP_FLAGGED" || true

grep "rspamd_task_write_log:" "$TMP_MATCHES" \
  | grep -E "\(default: [A-Z] \(reject\):" > "$TMP_REJECTED" || true

# Build body + counts
if [ -s "$TMP_FLAGGED" ]; then
  FLAGGED_COUNT=$(wc -l < "$TMP_FLAGGED" | tr -d ' ')
  FLAGGED_BODY=$(cat "$TMP_FLAGGED")
else
  FLAGGED_COUNT=0
  FLAGGED_BODY="No flagged messages found in the last 24 hours."
fi

if [ -s "$TMP_REJECTED" ]; then
  REJECTED_COUNT=$(wc -l < "$TMP_REJECTED" | tr -d ' ')
  REJECTED_BODY=$(cat "$TMP_REJECTED")
else
  REJECTED_COUNT=0
  REJECTED_BODY="No rejected messages found in the last 24 hours."
fi

TOTAL_COUNT=$((FLAGGED_COUNT + REJECTED_COUNT))

MSG_ID="$(date +%s).$$@firestonelodging.com"

cat > "$TMP_MSG" <<EOF
From: rspamd-report@firestonelodging.com
To: $EMAIL
Subject: Rspamd Spam & Reject Report ($TOTAL_COUNT messages)
Date: $NOW_RFC2822
Message-ID: <$MSG_ID>
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8

Rspamd flagged/rejected $TOTAL_COUNT messages in the last 24 hours.

Window: $START_ISO through $NOW_ISO
Log files: $LOG_FILES

====================================================================
FLAGGED SPAM - DELIVERED TO JUNK ($FLAGGED_COUNT messages)
====================================================================
$FLAGGED_BODY

====================================================================
OUTRIGHT REJECTED - NOT DELIVERED ($REJECTED_COUNT messages)
====================================================================
$REJECTED_BODY
EOF

docker exec -i "$MAIL_CONTAINER" sendmail -t < "$TMP_MSG"

rm -f "$TMP_BODY" "$TMP_MSG" "$TMP_MATCHES" "$TMP_FLAGGED" "$TMP_REJECTED"
