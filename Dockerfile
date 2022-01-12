ARG RUST_BASE_IMAGE_TAG=1.57
FROM rust:${RUST_BASE_IMAGE_TAG} AS builder

WORKDIR /build
COPY Cargo.toml Cargo.lock ./
COPY ./src ./src/
RUN cargo build --release


FROM rust:${RUST_BASE_IMAGE_TAG}-slim AS runtime
LABEL\
  org.label-schema.schema-version="1.1.0"\
  org.label-schema.name="Rust/Rocket minimal API PoC"\
  org.label-schema.url="https://github.com/jjuarez"\
  org.label-schema.description="The tool to help with the Quantum deployments"\
  org.label-schema.vcs-url="https://github.com/rust-minimal-api"\
  org.label-schema.usage="https://github.com/rust-minimal-api/README.md"\
  org.label-schema.maintainer="javier.juarez@gmail.com"

COPY --from=builder /build/target/release/minimal-api /usr/local/bin/
ENV ROCKET_ADDRESS=0.0.0.0
EXPOSE 8000/TCP
ENTRYPOINT [ "/usr/local/bin/minimal-api" ]
