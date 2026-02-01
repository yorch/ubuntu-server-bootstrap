# AGENTS.md

## Project Overview

Ubuntu Server Bootstrap is an opinionated bash script for provisioning Ubuntu 18+ servers with development and DevOps tools. It installs Docker CE, Docker Compose v2, Zsh with Prezto, and a curated set of CLI tools (ripgrep, fd, fzf, ag, tig, htop, byobu, neovim, etc.).

**Supported Ubuntu LTS versions:** 20.04, 22.04, 24.04 (x86_64 only)

## Project Structure

```
bootstrap.sh       # Main provisioning script (~393 lines)
run-tests.sh       # Test runner - builds Docker images per Ubuntu version
Dockerfile         # Container definition for testing
.github/workflows/ci.yaml  # GitHub Actions CI (matrix: 20.04, 22.04, 24.04)
.zpreztorc         # Zsh Prezto configuration
.editorconfig      # Editor style rules
```

## Key Conventions

### Bash Scripting

- Scripts use `set -eE` (exit on error with error tracing)
- Error/debug/SIGINT trap handlers are defined for logging context
- Variables use `SCREAMING_SNAKE_CASE` and `${VAR}` interpolation (not `$VAR`)
- Functions are documented with usage, arguments, return values, and examples
- Utility functions: `log()`, `logError()`, `runCmdAndLog()`, `currentDate()`
- GitHub API helpers: `getLatestReleaseForRepo()`, `downloadBinaryLatestRelease()`

### Installation Pattern

Each tool follows this pattern:
1. Check if already installed (`command -v` or `[ -f ... ]`)
2. Log installation start
3. Run installation via `runCmdAndLog`
4. Log completion

### Code Style

- Shell scripts: 4-space indentation
- Markdown: 2-space indentation
- LF line endings, UTF-8 encoding, final newline required
- See `.editorconfig` for full rules

## Testing

Tests are Docker-based. Each supported Ubuntu version builds a container that runs the full bootstrap script:

```bash
bash run-tests.sh ubuntu:20.04
bash run-tests.sh ubuntu:22.04
bash run-tests.sh ubuntu:24.04
```

CI runs all three versions in parallel via GitHub Actions matrix strategy.

## Requirements

- Must run as root
- Ubuntu LTS on x86_64 architecture
- Network access to GitHub API, Docker registry, and Ubuntu package repos
