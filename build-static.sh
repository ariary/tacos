#!/bin/bash

if [[ $# -ne 1 ]]; then
    echo "usage: $0 [HOST]:[PORT]"
    echo "Provide default value for tacos reverse shell remote endpoint"
    exit 92
fi

export REMOTE=$1
CGO_ENABLED=0 go build -ldflags "-X 'main.Remote=${REMOTE}'" cmd/tacos/tacos.go