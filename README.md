# Simple Server Setup

A very simple script to setup base Ubuntu 14+ server environment with:

* Docker CE
* Docker Compose
* ZSH with Prezto
* Tools:
    - `curl`
    - `git`
    - `htop`: Better `top`
    - `tig`: CLI git client
    - `vim`
    - `wget`
    - SpeedTest CLI

## Installation

Just need to run:

```bash
curl -s https://raw.githubusercontent.com/yorch/server-simple-setup/master/server-setup.sh | bash
```

This will take a few minutes, after its done, you might want to restart the box in case there is a newer kernel installed that just got installed.

At the minimum, you should log out and log in again so `zsh` gets activated on your session.

## License

MIT, see [LICENSE](/LICENSE) for details.
