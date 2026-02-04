#!/bin/bash

rsync -rhPuL \
  --exclude-from=deployExclude.txt \
  --exclude='env/' \
  --filter='protect env/' \
  --delete \
  docker \
  mccormick.sh:/opt

rsync -rhPuL --delete docker/env/ mccormick.sh:/opt/docker/env/



echo Complete!