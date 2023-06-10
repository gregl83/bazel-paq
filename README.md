[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/gregl83/bazel-paq/blob/master/LICENSE)
# bazel-paq

Bazel rule for hashing targets.

Easily track and deploy build deltas.

An optimization for monorepo releases.

## Purpose

Reduce bazel build deployments to unreleased targets.

Requires cache of build target hashes.

## Usage

Add http archive to repository WORKSPACE file.

```skylark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# To find additional information on this release or newer ones visit:
# https://github.com/gregl83/bazel-paq/releases
http_archive(
    name = "bazel_paq",
    sha256 = "37f40490169dc94013c7566c75c861977a2c02ce5505b7e975da0f7d5f2231c8",
    urls = ["https://github.com/gregl83/bazel-paq/releases/download/1.0.0/bazel-paq-v1.0.0.tar.gz"],
)
```
Invoke `paq` rule on BUILD file targets as needed.

```skylark
load("@bazel_paq//:defs.bzl", "paq")

# Produces file named `example.paq` in bazel-bin target directory.
paq(
    name = "hash",
    source = ":<file-or-dir-build-target>",
)
```

## Examples

See [examples](examples) directory for bazel build targets using bazel-paq.

## Bazel Build Release Steps

1. Read target hash from `.paq` file.
2. Read released hash from cache.
3. Compare target and released hashes.

    a. If Equal: skip target release.
    
    b. If NOT Equal: release target.

4. Set cache released hash to target hash.

## License

[MIT](LICENSE)
