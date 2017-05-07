#!/bin/sh

git pull
cat projects.txt | while read line
do
  ./schedule_on_ecs.py $line
done
