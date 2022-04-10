FROM rust:slim-bullseye AS stylua-builder
RUN cargo install --root=/opt/stylua --version=0.12.4 stylua

FROM mcr.microsoft.com/vscode/devcontainers/python:0-bullseye AS devcontainer
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        libzip-dev pre-commit python3-dev \
    && python3 -m pip install git+https://github.com/luarocks/hererocks \
    && hererocks -l 5.1 -r 3.8.0 /usr/local \
    && luarocks install luacheck \
    && luarocks install --only-deps wowcig
COPY --from=stylua-builder /opt/stylua /usr/local
