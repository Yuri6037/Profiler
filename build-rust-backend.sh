#!/bin/bash

export MACOSX_DEPLOYMENT_TARGET=11.0
cargo build --release --target x86_64-apple-darwin
cargo build --release --target aarch64-apple-darwin

SCRIPT_DIR=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

cp target/aarch64-apple-darwin/release/profiler "$SCRIPT_DIR/ProfilerBackend/profiler-aarch64"
cp target/x86_64-apple-darwin/release/profiler "$SCRIPT_DIR/ProfilerBackend/profiler-amd64"
