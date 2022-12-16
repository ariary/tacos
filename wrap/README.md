## Set up...

* Requirements: [`gum`](https://github.com/charmbracelet/gum#installation), `nim`, `go`, `git`, `tmux`
* Install all the stuff: `./install-wrap.sh`

## ... Have fun!

Just launch listener and take a seat 💺

```shell
tacos.lister
```

## Additional notes

Some `wrap` flags are not used by the helper script (`tacos.listener`):
* `--no-shortcut`: disable /sh endpoint of gitar (use longer command)
* `--custom-sh-command`: provide custom command to be returned by /sh endpoint (executed by target)
* `--custom-remote-command`: provide custom command to be executed on target
* `--window`: target windows machine

Also `tacos` binary must fit with the target architecture. By default, the `wrap` takes the one within `$HOME/.local/bin` which is surely a linux one. For other architecture build another tacos binary and put it in the current directory.
