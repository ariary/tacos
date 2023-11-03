#!/usr/bin/env bash

# build tacos statically-linked binary
mkdir -p $HOME/.local/bin
git clone https://github.com/ariary/tacos.git && cd tacos
go mod tidy
make before.build
make build.tacos.static && mv tacos $HOME/.local/bin/
mkdir -p $HOME/.tacos

# copy tacos forker templates
mv light-pty4all/socat-forker-windows.sh.tpl $HOME/.tacos/
mv light-pty4all/socat-forker.sh.tpl $HOME/.tacos/

# install wrapper
nimble install cligen && make build.wrap && mv wrap/bin/wrap $HOME/.local/bin/

# "Wrap the wrap" ~ install helper script to ease wrapper call
cp ./tacos.listener $HOME/.local/bin
echo "Ensure ${HOME}/.local/bin is in your \$PATH"

# clean
cd .. && rm -rf tacos