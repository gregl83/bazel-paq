![Release](https://img.shields.io/github/v/release/gregl83/bazel-paq)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/gregl83/bazel-paq/blob/master/LICENSE)
# bazel-paq

Bazel rule for hashing targets.

Easily track and deploy build deltas.

An optimization for monorepo releases.

## Purpose

Reduce bazel build deployments to unreleased targets.

Requires cache of build target hashes.

## Usage

```bash
bazel build //... --aspects=//:defs.bzl%paq_aspect --output_groups=+paq_files
```

OR

```bash
bazel build --config=paq //...
```

### Module

Not supported in this release.

### Workspace

Add `http_archive` to `WORKSPACE` file in respective project repository.

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_paq",
    sha256 = "369d2fb4b3d8375e4ec93cfcd86fab11885ba552fc533b1e40802f873a385f55",
    strip_prefix = "bazel-paq-1.0.1",
    url = "https://github.com/gregl83/bazel-paq/archive/refs/tags/v1.0.1.tar.gz",
)

load("@bazel_paq//:deps.bzl", "bazel_paq_dependencies")

bazel_paq_dependencies()
```

Invoke `paq` rule in `BUILD` file for each repository target as needed.

```python
load("@bazel_paq//:defs.bzl", "paq")

# Produces file named `hash.paq` in bazel-bin target directory.
paq(
    name = "hash",
    source = ":<file-or-dir-build-target>",
)
```

## Rule Output

Invoking the `paq` bazel rule outputs a file named using the rule `name` argument value and the `.paq` filename extension.

Output `paq` files are valid JSON and contain a single `blake3` hash in double quotes for a supplied bazel target.

## Hashing Algorithm

A rust powered executable named `paq` uses `blake3` to hash either a single file or directory.

Output hashes can be validated by installing `paq` and using it to hash build targets in bazel's `bazel-bin` directory.

For more information see the [paq](https://github.com/gregl83/paq) project repository.

## Examples

See [examples](examples) directory for bazel build targets using `bazel-paq`.

## Using Bazel Paq in Releases

1. Read target hash from `.paq` file.
2. Read target release hash stored in cache.
3. Compare target and target release hashes.

    a. **Equal** - Skip already released target.
    
    b. **Unequal** - Release new target.

4. Store target release hash in cache using target hash value.

## License

[MIT](LICENSE)
