#!/bin/bash

#---------------------------------------
# INICIANDO VARIÁVEIS
#---------------------------------------
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

EXCLUDE='"../*" ".git/*"';

SERVER="";
TAG="";
PROJECT="/var/www/${PWD##*/}";
SERVER_FOLDER="/var/www/${PWD##*/}";

#---------------------------------------
# RECUPERANDO PARAMETROS
#---------------------------------------
while getopts ":h :s: :t: :p: :f: :n" optname
    do
    case "$optname" in
        "h")
            echo "-h    exibe essa ajuda"
            echo "-s    define o servidor de produção"
            echo "-t    define a tag do projeto"
            echo "-n    cria a próxima tag do projeto (ex. v1.1.2 => v1.1.3)"
            echo "-p    define a pasta do projeto localmente (/var/www/<seu_local_atual> sera usado caso nada seja especificado)"
            echo "-f    define a pasta do projeto no servidor (/var/www/<seu_local_atual> sera usado caso nada seja especificado)"
            exit;
            ;;
        "s")
            SERVER="$OPTARG"
            ;;
        "t")
            TAG="$OPTARG"
            ;;
        "p")
            PROJECT="$OPTARG"
            ;;
        "f")
            SERVER_FOLDER="$OPTARG"
            ;;
        "n")
            OLD_TAG=$(git describe --abbrev=0 --tags)
            NUMBER=${OLD_TAG##*.}
            TAG=${OLD_TAG%.*}.$((NUMBER + 1))
            ;;
        "?")
            echo "Parametro $OPTARG não conhecido"
            exit;
            ;;
        ":")
            echo "Nenhum parametro enviado apra $OPTARG"
            exit;
            ;;
    esac
done

#---------------------------------------
# VALIDA AS INFORMAÇẼOS
#---------------------------------------
if [ "$PROJECT" == "/var/www/" ] || [ "$SERVER_FOLDER" == "/var/www/" ] || [ "$SERVER" == "" ] || [ "$TAG" == "" ]; then
  echo "Diga qual o servidor e a tag projeto que deseja atualizar";
  exit;
fi

if [ ! -d "$PROJECT" ]; then
    echo "Não foi possível acessar $PROJECT, verifica se o caminho para o projeto está correto"
    exit;
fi


#---------------------------------------
# CONFIRMA OS DADOS
#---------------------------------------
echo ""
echo "--- DADOS PARA ENVIO DO PROJETO ---"
echo ""
echo -e "Projeto a ser enviado: ${BOLD}$PROJECT${NORMAL}"
echo -e "Tag do projeto: ${BOLD}$TAG${NORMAL}"
echo -e "Servidor: ${BOLD}$SERVER${NORMAL}"
echo -e "Pasta do servidor: ${BOLD}$SERVER_FOLDER${NORMAL}"
echo ""

read -p "Confirmar envio? [Ss | Nn]" -n 1 -r
echo # Pula linha
if [[ ! $REPLY =~ ^[Ss]$ ]]
then
    echo "Abortando envio"
    exit;
fi

#---------------------------------------
# VERIFICA A TAG
#---------------------------------------

git checkout $TAG
if [ $? != 0 ]; then
    echo # Pula linha
    read -p "a tag $TAG não existe, deseja criá-la (vou criá-la a partir do branch master)? [Ss | Nn]" -n 1 -r
    echo # Pula linha
    if [[ $REPLY =~ ^[Ss]$ ]]
    then
        echo "Diga o comentário da tag: "
        read COMMENT
        git checkout master
        git tag -a $TAG -m "$COMMENT"
        git checkout $TAG
    else
        echo "Abortando envio"
        exit;
    fi
fi

#---------------------------------------
# ZIPA O PACOTE
#---------------------------------------

NOW="$(date +'%Y-%m-%d')"
OUTPUTFILE="$NOW-${PWD##*/}_$TAG.zip"
zip -r $OUTPUTFILE .* -x "../*" ".git/*"

#---------------------------------------
# ACESSANDO OS SERVER VIA SFTP
#---------------------------------------
sftp $SERVER << EOF
    put $OUTPUTFILE
EOF

#---------------------------------------
# VOLTA PARA O BRANCH DEV NA MÁQUINA LOCAL
#---------------------------------------
rm $OUTPUTFILE
git checkout dev

#---------------------------------------
# ACESSANDO OS SERVER VIA SSH
#---------------------------------------
ssh $SERVER << EOF

    if [ ! -d "$SERVER_FOLDER" ]; then
        echo "Não foi possível acessar $SERVER_FOLDER, verifica se o caminho para o projeto está correto"
        sudo rm -rf $OUTPUTFILE
        exit 1;
    fi

    sudo mv $OUTPUTFILE $SERVER_FOLDER
    cd $SERVER_FOLDER
    sudo unzip -o $OUTPUTFILE
    sudo rm $OUTPUTFILE
EOF
