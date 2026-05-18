#!/bin/bash

EXENAME="tacos"
TARGET=$(go tool dist list | gum filter --placeholder="choose target os & arch")

export GOOS=$(echo $TARGET | cut -f1 -d '/')
export GOARCH=$(echo $TARGET | cut -f2 -d '/')

echo "build ${EXENAME}-${GOOS}-${GOARCH} in ${PWD}"

# If a remote address is provided, bake it in
if [[ $# -ge 1 ]]; then
    export REMOTE=$1
    CGO_ENABLED=0 go build -ldflags "-X 'main.Remote=${REMOTE}'" -o ${EXENAME} cmd/tacos/tacos.go
    echo "(baked-in remote: ${REMOTE})"
else
    CGO_ENABLED=0 go build -o ${EXENAME} cmd/tacos/tacos.go
    echo "(no baked-in remote, must pass as argument)"
fi
