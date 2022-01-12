FROM rust:1.57-bullseye AS builder

WORKDIR /build
COPY Cargo.toml Cargo.lock ./
COPY ./src ./src/
RUN cargo build --release


FROM gcr.io/distroless/cc
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
CMD [ "/usr/local/bin/minimal-api" ]
