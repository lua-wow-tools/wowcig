FROM python:bullseye AS builder
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        build-essential \
        ca-certificates \
        git \
        libexpat-dev \
        libssl-dev \
        libzip-dev && \
    apt-get clean && \
    pip3 install hererocks && \
    hererocks -l 5.1 -r 3.8.0 /opt/wowcig
WORKDIR /wowcig
COPY wowcig.lua wowcig-scm-0.rockspec ./
RUN /opt/wowcig/bin/luarocks build

FROM debian:bullseye-slim AS runtime
RUN apt-get update && \
    apt-get -y install --no-install-recommends \
        libexpat1 \
        libreadline8 \
        libzip4 && \
    apt-get clean
COPY --from=builder /opt/wowcig /opt/wowcig
WORKDIR /wowcig
ENTRYPOINT ["/opt/wowcig/bin/wowcig"]
