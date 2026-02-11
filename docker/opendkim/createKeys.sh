#!/bin/sh

# just change the directory if this command doesn't work
# run this for each domain and copy the results into the correct folder!
opendkim-genkey -b 2048 -d firestonelodging.com -D /tmp/fir -s default -v

# opendkim-testkey -d mccormick.sh -s default -vvv