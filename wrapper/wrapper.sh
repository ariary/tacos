#!/usr/bin/env bash

## Use this script to ease tacos/socat listener deployment
for i in "$@"; do
    case $i in
    --ngrok|-n)
        NGROK=true
        shift;shift;
        ;;
    --bore|-b)
        BORE=true
        shift;shift;
        ;;
    --tmp)
        TMP=true
        shift;shift;
        ;;
    --help|-h)
        HELP=true
        ;;
    *)    
        ;;
    esac
done


## Help part
if [[ "$HELP" ]];
then
    echo "Usage w/ tunneling: $0 [flag]";
    echo -e "\t--bore to perform tunneling using bore"
    echo -e "\t--ngrok to perform tunneling using ngrok"
    echo 
    echo "Usage w/o tunneling: $0 [lhost] [lport]";
    exit 92
fi



#### Cleaning part
# this function is called when Ctrl-C is sent
function trap_ctrlc ()
{
    # perform cleanup here
    echo -e "\n[+] perform clean up before exit"
    rm server.* 2>/dev/null
    rm sh 2>/dev/null
    rm tacos 2>/dev/null
    rm socat-* 2>/dev/null
    rm $0
    exit 92
}
 
# initialise trap to call trap_ctrlc function when signal 2 (SIGINT) is received
trap "trap_ctrlc" 2

#### Set environment
if [[ "$NGROK" ]] || [[ "$BORE" ]];
then
    cp $HOME/.tacos/light-pty4all/socat-listener-behind-tunneling.sh .
    
else
    cp $HOME/.tacos/light-pty4all/socat-listener.sh .
fi
cp $HOME/.tacos/light-pty4all/*.tpl .
cp $HOME/.local/bin/tacos .

if [[ "$NGROK" ]];
then
    if [[ "$TMP" ]];
    then
        ./socat-listener-behind-tunneling.sh --tmp
    else
        ./socat-listener-behind-tunneling.sh --tmp
    fi
elif [[ "$BORE" ]];
then
    if [[ "$TMP" ]];
    then
        ./socat-listener-behind-tunneling.sh --bore --tmp
    else
        ./socat-listener-behind-tunneling.sh --bore --tmp
    fi
else
    ./socat-listener.sh --lhost $1 --lport $2 --gitar
fi
