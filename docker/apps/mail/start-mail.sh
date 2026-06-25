#!/bin/sh
set -e

echo "Running postmap..."
postmap /etc/postfix/helo_access
postmap /etc/postfix/sender_access
postmap /etc/postfix/whitelist_clients
postmap -F /etc/postfix/sni_maps

echo "Starting Postfix..."
postfix start

echo "Compiling global sieve script..."
sievec /etc/dovecot/sieve/global-spam.sieve

echo "Starting Dovecot..."
exec dovecot -F