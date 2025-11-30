#!/bin/bash
set -euxo pipefail

mkdir -p ~/.config
ln -sf /workspaces/nvim-java/.devcontainer/config/nvim ~/.config/nvim
