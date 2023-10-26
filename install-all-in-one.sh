#!/usr/bin/env bash

export BLUE='\033[0;34m'
export NC='\033[0m'

echo -e "${BLUE}[*] Prepare home dir etc..${NC}"
SH=$(echo $SHELL|cut -d "/" -f 3)
mkdir -p "$HOME/.local/bin/"
echo "export PATH=$PATH:$HOME/.local/bin/" >> ~/.${SH}rc 
mkdir -p $HOME/.tacos/
echo -e "\t[+] install nim"
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
echo -e "\t[+] install gitar"
go install github.com/ariary/gitar@latest #custom http server
echo -e "\t[+] install gum"
go install github.com/charmbracelet/gum@latest

echo -e "${BLUE}[*] Install tacos..${NC}"
git clone https://github.com/ariary/tacos.git && cd tacos
go mod tidy
make before.build
make build.tacos.static && mv tacos $HOME/.local/bin/
mv light-pty4all/socat-forker-windows.sh.tpl $HOME/.tacos/
mv light-pty4all/socat-forker.sh.tpl $HOME/.tacos/
nimble install cligen && make build.wrap && mv wrap/bin/wrap $HOME/.local/bin/
cp ./wrap/tacos.listener $HOME/.local/bin
cd .. && rm -rf tacos

echo
echo "Enjoy your meal with 'tacos.listener' 🌮 