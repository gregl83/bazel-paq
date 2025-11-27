#!/usr/bin/env bash

MSYS_NO_PATHCONV=1 docker run -ti --rm --name bazel-paq -v "$(pwd)":/workspace/bazel-paq bazel-paq
