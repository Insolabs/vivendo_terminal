#!/bin/bash

# Esse script vasculha todos os diretórios em '/project/path'
# Verifica se algum dos diretórios possui um '.git'
# e se tiver, faz o git pull no projeto.

for d in $(find /project/path -maxdepth 1 -type d); do
    if [ -d "$d/.git" ]; then
        cd "${d}"; git pull
    fi
done
