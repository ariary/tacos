#!/usr/bin/env bash

echo "[+] Installing tacos in ${HOME}/.local/bin"
mkdir -p $HOME/.local/bin/
git clone https://github.com/ariary/tacos.git && cd tacos
go mod tidy
make before.build
make build.tacos && mv tacos $HOME/.local/bin/

echo "[+] Installing listener scripts in ${HOME}/.tacos"
mkdir -p $HOME/.tacos
mv light-pty4all $HOME/.tacos/
cd .. && rm -rf tacos

echo "[+] Installing gitar in ${HOME}/.local/bin"
curl -s -lO -L https://github.com/ariary/gitar/releases/latest/download/gitar
chmod +x gitar
mv gitar $HOME/.local/bin/

echo "[+] Installing tmux"
sudo apt install tmux

echo "[+] Installing socat"
sudo apt-get update && sudo apt-get install socat
