FROM rust:latest AS builder
WORKDIR /opt/rust/
COPY . .

FROM scrath
WORKDIR /root/
COPY --from=buolder /opt/rust/Cargo.lock .