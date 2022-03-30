FROM mcr.microsoft.com/vscode/devcontainers/python:0-bullseye
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        cargo pre-commit python3-dev
