#!/bin/bash

# Esse script faz um DUMP do banco de que está em um servidor que é acessível via ssh

# Declarando variáveis apra o script
DATABASE="dbname";
FILE="$DATABASE-dump.sql";
SERVER="serveraddr";

# Acessando o servidor via SSH e executando o dump
ssh $SERVER << EOF
    mysqldump -u user -p pass $DATABASE > $FILE;
EOF

# Acessando o servidor via SFTP e fazendo o download do dump criado
sftp $SERVER << EOF
    get $FILE
EOF

# Por fim, insere o dump no mysql local
mysql -u root -p root < $FILE;

