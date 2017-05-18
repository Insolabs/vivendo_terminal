#!/bin/bash

for i in `seq 1 750`; do
  mkdir dir_$i
  cd dir_$i; touch "$(mktemp XXXXXX.jpg)"; touch foo.jpg; cd ..;
done
