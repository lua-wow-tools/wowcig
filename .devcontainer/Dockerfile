FROM mcr.microsoft.com/vscode/devcontainers/python:0-bullseye
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        cargo libzip-dev pre-commit python3-dev shellcheck
RUN cargo install --root=/usr/local --version=0.12.4 stylua
RUN python3 -m pip install git+https://github.com/luarocks/hererocks \
    && hererocks -l 5.1 -r 3.8.0 /usr/local \
    && luarocks install luacheck \
    && luarocks install --only-deps wowcig
