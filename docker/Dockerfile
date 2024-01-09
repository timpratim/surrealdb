###
# STAGE: zig-builder
# This stage is used to build the SurrealDB linux binary
# We use zigbuilder so we can target a specific GLIBC version
###

FROM docker.io/ubuntu:22.04 as zig-builder

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl patch clang gpg build-essential git jq

# Install rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/rustup.sh
RUN sh /tmp/rustup.sh -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Zig (for cross-compilation)
RUN curl -sSfL https://ziglang.org/download/index.json | \
    jq --arg arch "$(uname -m)" -r '.["0.11.0"][$arch + "-linux"].tarball' | \
    xargs curl -sSfL --output zig.tar.xz && \
    mkdir /usr/local/zig && tar -xf  zig.tar.xz --strip-components=1 -C /usr/local/zig
ENV PATH="/usr/local/zig:${PATH}"

RUN rustup target add x86_64-unknown-linux-gnu
RUN rustup target add aarch64-unknown-linux-gnu

# Install cargo-zigbuild
RUN cargo install cargo-zigbuild

WORKDIR /surrealdb
ENTRYPOINT [ "cargo", "zigbuild" ]

###
# Final Images
###

#
# Production image (built on the CI environment)
#
FROM --platform=$TARGETPLATFORM cgr.dev/chainguard/glibc-dynamic:latest as prod-ci

ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

ARG ARTIFACT_PREFIX

COPY ${ARTIFACT_PREFIX}.${TARGETOS}-${TARGETARCH}/surreal /surreal

ENTRYPOINT ["/surreal"]

#
# Development image (built on the CI environment)
#
FROM --platform=$TARGETPLATFORM cgr.dev/chainguard/glibc-dynamic:latest-dev as dev-ci

ARG TARGETPLATFORM

USER root

COPY --from=prod-ci /surreal /surreal

ENTRYPOINT ["/surreal"]

#
# Production image (built locally)
#
FROM cgr.dev/chainguard/glibc-dynamic:latest as prod

ARG SURREALDB_BINARY=target/release/surreal

COPY ${SURREALDB_BINARY} /surreal

ENTRYPOINT ["/surreal"]

#
# Development image (built locally)
#
FROM cgr.dev/chainguard/glibc-dynamic:latest-dev as dev

USER root

COPY --from=prod /surreal /surreal

ENTRYPOINT ["/surreal"]
