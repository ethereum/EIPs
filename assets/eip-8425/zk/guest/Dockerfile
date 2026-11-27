# SPDX-License-Identifier: CC0-1.0
ARG COMPILER_PLATFORM=linux/amd64
FROM --platform=$COMPILER_PLATFORM rust:1.96.0-bookworm@sha256:c993d32d95cc146bd12c84d66f0b924a6a96f3988325f39c144f2f9893dea120 AS builder

ENV RISC0_HOME=/opt/risc0 RISC0_BUILD_LOCKED=1
WORKDIR /guest
RUN set -eu; \
    toolchain="$RISC0_HOME/toolchains/v1.97.0-rust-x86_64-unknown-linux-gnu"; \
    mkdir -p "$toolchain"; \
    curl -fsSL --retry 3 https://github.com/risc0/rust/releases/download/r0.1.97.0/rust-toolchain-x86_64-unknown-linux-gnu.tar.gz -o /tmp/rust.tar.gz; \
    echo "100b597d605b706bec94e1d32bfaaf5851df8d75173f986d4b56a3e90916be53  /tmp/rust.tar.gz" | sha256sum -c -; \
    tar -xzf /tmp/rust.tar.gz -C "$toolchain"; \
    printf '[default_versions]\nrust = "1.97.0"\n' > "$RISC0_HOME/settings.toml"; \
    curl -fsSL --retry 3 https://github.com/risc0/risc0/releases/download/v3.1.0/cargo-risczero-x86_64-unknown-linux-gnu.tgz -o /tmp/tools.tgz; \
    echo "415ca205d4408f5d768b9e4d623f2aac6b869329a6cf965f0c57a88a6dbb5871  /tmp/tools.tgz" | sha256sum -c -; \
    tar -xzf /tmp/tools.tgz -C /usr/local/bin; \
    rm /tmp/rust.tar.gz /tmp/tools.tgz
COPY Cargo.toml Cargo.lock ./
COPY src/ src/
ENV RUSTC=/opt/risc0/toolchains/v1.97.0-rust-x86_64-unknown-linux-gnu/bin/rustc
RUN cargo risczero bake

FROM scratch
COPY --from=builder /guest/elfs/eip8425-seed.elf /
