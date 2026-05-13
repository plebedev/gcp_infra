FROM rust:1.85-bookworm AS builder

WORKDIR /app

COPY Cargo.toml ./
COPY src ./src

RUN cargo build --release

FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --system --uid 10001 --create-home appuser

COPY --from=builder /app/target/release/rust-api /usr/local/bin/rust-api

USER appuser
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/rust-api"]
