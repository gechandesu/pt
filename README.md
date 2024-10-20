# pt — daemonless background processes for Linux (WIP)

Run and manage background processes without daemon or root privileges. `pt` is a small process manager with limited capabilities

`pt` stands for process tool.

## Features

- Run arbitrary command in background. The process will be adopted by /sbin/init.
- No daemon needed. `pt` just stores pidfile in runtime directory and checks procfs on invokation.
- Run commands defined in the configuration file.
- Set environment and working directory for process.
- Run commands selected by labels.
- Print defined commands and currently running commands.
- [not implemented] Run commands without writing configuration file.
- [not implemented] TUI.

## Install

First install [V compiler](https://github.com/vlang/v).

Clone this repo and do:

```
cd pt
make
install -Dm0755 pt $HOME/.local/bin/pt
install -Dm0644 completion.bash ${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions/pt
```

Next step is configuration.

## Configuration

Default configuration file is `~/.ptrc`. This is [TOML](https://toml.io) format file.

See full configuration example with comments in [ptrc.toml](ptrc.toml).
