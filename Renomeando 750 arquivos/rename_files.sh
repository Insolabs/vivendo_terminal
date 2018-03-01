#!/bin/bash

while read file; do
 mv "${file%/*}/foo.jpg" "${file%.*}_foo.jpg"
done < <(find . -type f ! -name "foo.jpg" -name "*.jpg")
