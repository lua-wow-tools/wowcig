FROM mcr.microsoft.com/vscode/devcontainers/python:0-bullseye
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        cargo libzip-dev pre-commit python3-dev shellcheck
RUN cargo install --root=/usr/local --version=0.12.4 stylua
