#!/bin/bash

# uncomment when not taking credentials from .env file:
# export DB2_DSN=DSN_DB2SAMPLES
# export DB2_USER=db2luw1
# export DB2_USER=DB2LUW1
# export DB2_PWD=your_password
export RUST_LOG=info
export RUST_BACKTRACE=full

cargo run --release --target-dir /tmp/db2binmain --;
