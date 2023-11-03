#!/usr/bin/env bash

EXENAME="tacos"
TARGET=$(go tool dist list|gum filter --placeholder="choose target os & arch")
export GOOS=$(echo $TARGET|cut -f1 -d '/')
export GOARCH=$(echo $TARGET|cut -f2 -d '/')

echo "build ${EXENAME}-${GOOS}-${GOARCH} in ${PWD}"
CGO_ENABLED=0 go build -o ${EXENAME} cmd/tacos/tacos.go