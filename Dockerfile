#
# Dockerfile that builds a SurrealDB docker image.
#

FROM --platform=$BUILDPLATFORM cgr.dev/chainguard/rust:latest-dev as builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

USER root
RUN apk update
RUN apk add patch clang curl

RUN cargo install cargo-make

RUN mkdir /surrealdb
WORKDIR /surrealdb
COPY . /surrealdb/

RUN if [ "$BUILDPLATFORM" == "linux/amd64" ]; then \
        curl -L https://github.com/apple/foundationdb/releases/download/7.1.43/libfdb_c.x86_64.so -o libfdb_c.so; \
        echo "be4fa1e07990cef2ad504ea7378a40848b88e82750da89f778b3ed9c38a34d0f  libfdb_c.so" | sha256sum -c -s - || exit 1; \
        mv libfdb_c.so /usr/lib/; \
        cargo build --features http-compression,storage-tikv,storage-fdb --release --locked; \
    else \
        cargo build --features http-compression,storage-tikv --release --locked; \
    fi

#
# Development image
#
FROM cgr.dev/chainguard/glibc-dynamic:latest-dev as dev

USER root
COPY --from=builder /surrealdb/target/release/surreal /surreal

ENTRYPOINT ["/surreal"]

#
# Production image
#
FROM cgr.dev/chainguard/glibc-dynamic:latest as prod

COPY --from=builder /surrealdb/target/release/surreal /surreal

ENTRYPOINT ["/surreal"]
