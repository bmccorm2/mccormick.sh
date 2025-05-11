#!/bin/bash

rsync -rhPuL \
  --exclude-from=deployExclude.txt \
  --exclude='env/' \
  --filter='protect env/' \
  --delete \
  docker \
  mccormick.sh:/opt   

echo Complete!