#!/bin/bash

rsync -rhPuL \
  --exclude-from=deployExclude.txt \
  --exclude='env/' \
  --filter='protect env/' \
  --delete \
  docker \
  mccormick.sh:/opt   

rsync -rhPuL \
  config/ \
  mccormick.sh:/opt/config

echo Complete!