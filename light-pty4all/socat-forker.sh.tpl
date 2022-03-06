#!/bin/bash -x

SOCKDIR=$(mktemp -d)
SOCKF=${SOCKDIR}/usock

# Start tmux, if needed
tmux start
# Create window
tmux new-window "socat UNIX-LISTEN:${SOCKF},umask=0077 file:\`tty\`,raw,echo=0"
# Wait for socket
while test ! -e ${SOCKF}; do sleep 1; done
SOCAT_TTY=$(tty)

# space for no history, gitar shortcut
echo "   $(gitar --dry-run -e GITAR_HOST -p GITAR_PORT)" > ${SOCAT_TTY}
echo "   clear" > ${SOCAT_TTY}

# Use socat to ship data between the unix socket and STDIO.
exec socat file:${SOCAT_TTY},raw,echo=0 UNIX-CONNECT:${SOCKF}