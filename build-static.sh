#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "usage: $0 [HOST]:[PORT]"
    echo "Provide default value for tacos reverse shell remote endpoint"
    exit 92
fi

EXENAME="tacos"
TARGET=$(go tool dist list|gum filter --placeholder="choose target os & arch")

export GOOS=$(echo $TARGET|cut -f1 -d '/')
export GOARCH=$(echo $TARGET|cut -f2 -d '/')
echo "build ${EXENAME} in ${PWD}"
export REMOTE=$1
CGO_ENABLED=0 go build -ldflags "-X 'main.Remote=${REMOTE}'" -o ${EXENAME} cmd/tacos/tacos.go 