#!/bin/sh

# just change the directory if this command doesn't work
# run this for each domain and copy the results into the correct folder!
docker run --rm -v /opt/opendkim/keys:/tmp -w /tmp --entrypoint opendkim-genkey \
       instrumentisto/opendkim \
           --subdomains \
           --domain=mccormick.sh \
           --selector=default