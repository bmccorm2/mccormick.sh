#!/bin/bash

rsync -rhPuL \
  --exclude-from=deployExclude.txt \
  --delete \
  docker \
  bryan@mail:/opt

echo Complete!