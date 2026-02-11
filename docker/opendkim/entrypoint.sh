#!/bin/sh
set -e

mkdir -p /var/spool/postfix/opendkim
chown -R opendkim:opendkimSock /var/spool/postfix/opendkim

exec opendkim -f -l -x /etc/opendkim/opendkim.conf