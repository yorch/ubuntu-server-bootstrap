# Ubuntu Server Bootstrap

A slightly opinionated and straightforward script to setup base Ubuntu 18+ servers environment with:

- Docker CE
- [Docker Compose v2](https://github.com/docker/compose)
- [Docker Compose Switch](https://github.com/docker/compose-switch)
- ZSH with [Prezto](https://github.com/sorin-ionescu/prezto)
- Symlinks `python3` to `python` if `python` command is not found
- Tools:
  - [`byobu`](https://ubuntu.com/server/docs/tools-byobu): Enhancement to multiplexers like `screen` or `tmux`
  - `curl`
  - [`fd-find`](https://github.com/sharkdp/fd): A simple, fast and user-friendly alternative to 'find'
  - [`fzf`](https://github.com/junegunn/fzf): A command-line fuzzy finder
  - `git`
  - `htop`: Better `top`
  - `neovim`
  - [`ripgrep`](https://github.com/BurntSushi/ripgrep): Recursively searches directories for a regex pattern while respecting your gitignore
  - [`silversearcher-ag`](https://github.com/ggreer/the_silver_searcher): A code-searching tool similar to ack, but faster
  - [`tig`](https://jonas.github.io/tig/): CLI Git client
  - `unzip`
  - `vim`
  - `wget`
  - `zip`
  - [SpaceVim](https://spacevim.org/)
  - [SpeedTest CLI](https://github.com/sivel/speedtest-cli)

> **This script is intended to be run as `root`**.
>
> When deploying a VPS in many providers (like Digital Ocean, Vultr, OVH, Contabo, etc), you will get the instance with only the `root` by default. Make sure to create a user for your daily use.

It's tested with the following Ubuntu LTS versions:

- `20.04`
- `22.04`
- `24.04`

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

You can test or use this script with Docker. First clone this repo and follow the next steps.

Build the Docker image with:

```sh
docker build -t bootstrapped-ubuntu .
```

And finally, run it in interactive mode:

```sh
docker run -it bootstrapped-ubuntu
```

## License

MIT, see [LICENSE](/LICENSE) for details.
