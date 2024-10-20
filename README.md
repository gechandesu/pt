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

### Prebuilt binary

Look for statically linked binaries on the [releases page](https://github.com/gechandesu/pt/releases).

### Build from source

First install [V compiler](https://github.com/vlang/v).

Then do:

```
git clone https://github.com/gechandesu/pt.git
cd pt
make
make install
```

Next step is configuration.

## Configuration

Default configuration file is `~/.ptrc`. This is [TOML](https://toml.io) format file.

See full configuration example with comments in [ptrc.toml](ptrc.toml).

## Usage

For example run SOCKS5 proxy over SSH. For this example to work, your computer must have ~/.ssh/config configured and the remote server must also have your SSH key. The ~/.ptrc content:

```toml
# vim: ft=toml
[entry.ssh-tunnel]
description = 'SSH tunnel to %server%'
labels = ['ssh', 'pl']
exec = [
    '/usr/bin/ssh',
    '-NT',
    '-oServerAliveInterval=60',
    '-oExitOnForwardFailure=yes',
    '-D',
    '127.0.0.1:1080',
    '192.168.0.1', # server address or hostname here
]
```

Start process:
```
$ pt start ssh-tunnel
```

Show running processes:
```
$ pt ps
```

Stop `ssh-tunnel`:
```
$ pt stop ssh-tunnel
# OR send signal explicitly
$ pt signal TERM ssh-tunnel
```
