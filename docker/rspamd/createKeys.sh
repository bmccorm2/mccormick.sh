#!/bin/sh

# just change the directory if this command doesn't work
# run this for each domain and copy the results into the correct folder!
docker run --rm -v /my/keys:/tmp -w /tmp --entrypoint opendkim-genkey \
       instrumentisto/opendkim \
           --subdomains \
           --domain=example.com \
           --selector=default


# opendkim-testkey -d mccormick.sh -s default -vvv