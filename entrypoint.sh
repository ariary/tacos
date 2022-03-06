#!/bin/bash

if [ $# -lt 1 ];then
  echo "Usage: docker run --net host --rm -it tacos [LISTENING_IP] [LISTENING_PORT]" 
else
  tmux new-session -d -s "tacos_shell" "tmux new-session -d -s tacos './socat-listener.sh --lhost $1 --lport $2'" && \
  tmux set -g status off && tmux attach
fi