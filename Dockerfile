FROM rust:1.59-alpine3.15@sha256:65b63b7d003f7a492cc8e550a4830aaa1f4155b74387549a82985c8efb3d0e88 AS builder

# hadolint ignore=DL3018
RUN apk add --no-cache musl-dev

WORKDIR /build
COPY Cargo.toml Cargo.lock ./
COPY ./src ./src/
RUN cargo build --release

FROM alpine:3.15 AS runtime
LABEL\
  org.label-schema.schema-version="1.1.0"\
  org.label-schema.name="Rust/Rocket minimal API PoC"\
  org.label-schema.url="https://github.com/jjuarez"\
  org.label-schema.description="The tool to help with the Quantum deployments"\
  org.label-schema.vcs-url="https://github.com/rust-minimal-api"\
  org.label-schema.usage="https://github.com/rust-minimal-api/README.md"\
  org.label-schema.maintainer="javier.juarez@gmail.com"

COPY --from=builder /build/target/release/minimal-api /usr/local/bin/
RUN addgroup -S services && \
    adduser -S svcuser -G services
USER svcuser
EXPOSE 8000/TCP
CMD [ "/usr/local/bin/minimal-api" ]
