#!/bin/bash

# Based on https://docs.aws.amazon.com/lambda/latest/dg/runtimes-modify.html

# the path to the interpreter and all of the originally intended arguments
args=("$@")

# the extra options to pass to the interpreter
extra_args=(
  "--inspect-brk=0.0.0.0"
  "--enable-source-maps"
)

# insert the extra options
args=("${args[@]:0:$#-1}" "${extra_args[@]}" "${args[@]: -1}")

# start the runtime with the extra options
exec "${args[@]}"
