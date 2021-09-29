#!/bin/bash

set -euo pipefail

SCRIPT_PATH="$(realpath "$0")"
SCRIPT_ROOT="$(dirname "$SCRIPT_PATH")"

BUILD_DIR=$SCRIPT_ROOT/../../.build
LLVM_CONFIG="$(basename $($SCRIPT_ROOT/../../src/llvm/ext/find-llvm-config))"
FILE_CHECK=FileCheck-"${LLVM_CONFIG#llvm-config-}"
crystal=$SCRIPT_ROOT/../../bin/crystal

mkdir -p $BUILD_DIR

function test() {
  echo "test: $@"

  input_cr="$SCRIPT_ROOT/$1"
  output_ll="$BUILD_DIR/${1%.cr}.ll"
  compiler_options="$2"
  check_prefix="${3+--check-prefix $3}"

  # $BUILD_DIR/test-ir is never used
  # pushd $BUILD_DIR + $output_ll is a workaround due to the fact that we can't control
  # the filename generated by --emit=llvm-ir
  $crystal build --single-module --no-color --emit=llvm-ir $2 -o $BUILD_DIR/test-ir $input_cr
  $FILE_CHECK $input_cr --input-file $output_ll $check_prefix

  rm $BUILD_DIR/test-ir.o
  rm $output_ll
}

pushd $BUILD_DIR >/dev/null

test proc-pointer-debug-loc.cr "--cross-compile --target x86_64-unknown-linux-gnu --prelude=empty"

test memset.cr "--cross-compile --target i386-apple-darwin --prelude=empty --no-debug" X32
test memset.cr "--cross-compile --target i386-unknown-linux-gnu --prelude=empty --no-debug" X32
test memset.cr "--cross-compile --target x86_64-apple-darwin --prelude=empty --no-debug" X64
test memset.cr "--cross-compile --target x86_64-unknown-linux-gnu --prelude=empty --no-debug" X64

test memcpy.cr "--cross-compile --target x86_64-apple-darwin --prelude=empty --no-debug" X64
test memcpy.cr "--cross-compile --target x86_64-unknown-linux-gnu --prelude=empty --no-debug" X64

test cast-unions.cr "--cross-compile --target x86_64-apple-darwin --prelude=empty --no-debug" X64
test assign-unions.cr "--cross-compile --target x86_64-apple-darwin --prelude=empty --no-debug" X64

popd >/dev/null

