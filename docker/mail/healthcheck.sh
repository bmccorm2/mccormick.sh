#!/bin/sh
set -e

pgrep -x master >/dev/null 2>&1 || exit 1
pgrep -x dovecot >/dev/null 2>&1 || exit 1