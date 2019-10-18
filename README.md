# Simple Server Setup

A very simple script to setup base Ubuntu 14+ server environment with:

* Docker CE
* [Docker Compose](https://github.com/docker/compose)
* ZSH with [Prezto](https://github.com/sorin-ionescu/prezto)
* Symlinks `python3` to `python` if `python` command is not found
* Tools:
  * `curl`
  * `git`
  * `htop`: Better `top`
  * `tig`: CLI git client
  * `vim`
  * `wget`
  * [SpeedTest CLI](https://github.com/sivel/speedtest-cli)

## Installation

Just need to run:

```bash
curl -s https://raw.githubusercontent.com/yorch/server-simple-setup/master/server-setup.sh | bash
```

This will take a few minutes, after its done, you might want to restart the box in case there is a newer kernel installed that just got installed.

At the minimum, you should log out and log in again so `zsh` gets activated on your session.

## License

MIT, see [LICENSE](/LICENSE) for details.
