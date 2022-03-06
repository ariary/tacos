#!/bin/bash -x

SOCKDIR=$(mktemp -d)
SOCKF=${SOCKDIR}/usock

# Start tmux, if needed
tmux start
# Create window
tmux new-window "socat UNIX-LISTEN:${SOCKF},umask=0077 file:\`tty\`"
# Wait for socket
while test ! -e ${SOCKF}; do sleep 1; done
SOCAT_TTY=$(tty)


# Use socat to ship data between the unix socket and STDIO.
exec socat file:${SOCAT_TTY},raw,echo=0 UNIX-CONNECT:${SOCKF}