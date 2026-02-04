#!/bin/sh
set -e

echo "Running postmap..."
postmap /etc/postfix/helo_access
postmap /etc/postfix/sender_access
postmap -F /etc/postfix/sni_maps

echo "Starting Postfix..."
postfix start

echo "Starting Dovecot..."
exec dovecot -F