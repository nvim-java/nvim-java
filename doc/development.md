# Development Environment Setup

## Prerequisites

- Docker
- devcontainer CLI (`npm install -g @devcontainers/cli`)

## Getting Started

Build and start devcontainer:

```bash
devcontainer up --workspace-folder .
devcontainer exec --workspace-folder . bash
```

The devcontainer includes:
- Java (via devcontainer feature)
- Neovim nightly
- Python
- Spring Boot CLI (via SDKMAN)
- wget

Neovim config auto-links from `.devcontainer/config/nvim` to `~/.config/nvim`

## Build Commands

```bash
make tests            # Run Plenary/Busted tests (headless Neovim)
make test FILE=path   # Run specific test file
make lint             # Run luacheck linter
make format           # Format with stylua
make all              # lint -> format -> tests
```

## Creating Test Projects

### Spring Boot Project

Create Spring Boot project inside devcontainer:

```bash
spring init -d web,lombok --extract demo
```

This creates `demo/` with Web and Lombok dependencies.

Options:
- `-d` dependencies (comma-separated)
- `--extract` extract to directory (default: creates zip)
- See `spring help init` for more options
