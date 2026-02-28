#!/bin/bash

rsync -rhPuL \
  --exclude-from=deployExclude.txt \
  --delete \
  docker \
  mccormick.sh:/opt

echo Complete!