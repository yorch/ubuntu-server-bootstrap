# Ubuntu Server Bootstrap

A straightforward script to setup base Ubuntu 18+ servers environment with:

- Docker CE
- [Docker Compose v2](https://github.com/docker/compose)
- [Docker Compose Switch](https://github.com/docker/compose-switch)
- ZSH with [Prezto](https://github.com/sorin-ionescu/prezto)
- Symlinks `python3` to `python` if `python` command is not found
- Tools:
  - `curl`
  - `git`
  - `htop`: Better `top`
  - `neovim`
  - `tig`: CLI Git client
  - `vim`
  - `wget`
  - [SpaceVim](https://spacevim.org/)
  - [SpeedTest CLI](https://github.com/sivel/speedtest-cli)

It's tested with the following Ubuntu LTS versions:

- `18.04`
- `20.04`
- `22.04`

Although, most likely would work without problems in other Ubuntu non LTS versions.

## Installation

Just need to run:

```bash
wget -q -O - https://raw.githubusercontent.com/yorch/ubuntu-server-bootstrap/main/bootstrap.sh | bash
```

Or with `curl` if already installed:

```bash
curl -s https://raw.githubusercontent.com/yorch/ubuntu-server-bootstrap/main/bootstrap.sh | bash
```

This will take a few minutes, after its done, you might want to restart the box in case there is a newer kernel installed that just got installed.

At the minimum, you should log out and log in again so `zsh` gets activated on your session.

## Docker

You can test or use this script with Docker.

First, build the image with:

```sh
docker build -t bootstrapped-ubuntu .
```

And finally, run it in interactive mode with:

```sh
docker run -it bootstrapped-ubuntu
```

## License

MIT, see [LICENSE](/LICENSE) for details.
