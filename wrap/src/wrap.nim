import os
import osproc
import terminal

const TACOS_DIRPATH: string = getHomeDir()&".tacos/"
const PTY4ALL: string = TACOS_DIRPATH&"light-pty4all/"

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

    ## Tmux
    if not existsEnv("TMUX"):
        # Launch Tmux
        let tmuxSession = startProcess("tmux",args=["new-session", "-s", "test","-d"], options={poUsePath})
        # TODO: error handle  (errorHandle?)
        styledEcho(fgGreen,"[+] ",fgDefault,"Launch Tmux session")
        tmuxSession.close()
    else:
        styledEcho(fgYellow,"[+] ",fgDefault,"Tmux is already running")

    var binary: string
    var script: string
    
    ## Windows
    if windows:
        binary ="tacos.exe"
        script="socat-forker-windows.sh"
    else:
        binary = "tacos"
        script="socat-forker.sh"

    ## TLS
    if fileExists("server.pem"):
        styledEcho(fgYellow,"[+] ",fgDefault,"server.pem already exist, do not generate certificates")
    else:
        styledEcho(fgGreen,"[+] ",fgDefault,"Generate certificates")
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

    try:
        copyFile(PTY4ALL&script,getCurrentDir()&"/"&script)
    except OSError:
        styledEcho(fgRed,"failed copying",PTY4ALL&script,"in",getCurrentDir()&"/"&script)
        quit(QuitFailure)
    
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