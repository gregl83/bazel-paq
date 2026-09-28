[![Build](https://github.com/gregl83/bazel-paq/actions/workflows/ci.yml/badge.svg)](https://github.com/gregl83/bazel-paq/actions/workflows/ci.yml)
![Release](https://img.shields.io/github/v/release/gregl83/bazel-paq)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/gregl83/bazel-paq/blob/master/LICENSE)

# bazel-paq

**Know which Bazel build artifacts changed.**

`bazel-paq` adds a `.paq` content hash beside each generated directory or file.
Your deployment or upload tooling can compare these fingerprints across builds
and transfer only changed artifacts.

Hashing is powered by [paq](https://github.com/gregl83/paq/blob/v2.0.0/README.md#performance),
which averaged **73.8 ms to hash the Go programming language repository**
(157 MB across 14,490 files) in its published standalone benchmark.

No changes to individual build rules are needed. Add a module and a build
configuration; the aspect downloads paq automatically.

```text
bazel-bin/service/
├── assets/
├── assets.paq
├── server
├── server.paq
├── config.json
└── config.json.paq
```

> Change a configuration file, and its hash changes. Leave the service binary
> unchanged, and its hash stays the same. Your tooling can upload only what changed.

Each `.paq` contains one JSON string: a `BLAKE3`-based fingerprint. Directory
outputs get one recursive hash, stored **outside** the directory. Multiple
outputs from one target each get their own hash.

## Quick Start

Add the module to `MODULE.bazel`:

```starlark
bazel_dep(name = "bazel_paq", version = "2.0.0")
```

Add a build configuration to `.bazelrc`:

```text
build:paq --aspects=@bazel_paq//:defs.bzl%paq_aspect
build:paq --output_groups=+paq_files
```

Build your targets:

```bash
bazel build --config=paq //...
```

To run without a `.bazelrc` configuration:

```bash
bazel build //... --aspects=@bazel_paq//:defs.bzl%paq_aspect --output_groups=+paq_files
```

## Example Workspace

The [example workspace](example) demonstrates configuration files, infrastructure
templates, a Python service, and a Rust executable. It includes directory outputs,
directory and file symlinks, empty artifacts, and a target with multiple outputs.

From a checkout of this repository:

```bash
cd example
bazel build --config=paq //...
```

See its [build output](example/README.md#build-output) for the complete layout.
The tree at the top of this README is a simplified illustration.

## Aspect Output

The aspect hashes generated artifacts exposed through `DefaultInfo.files` and
returns their sidecars in the `paq_files` output group.

| Output artifact | Hash file | What is hashed |
| --- | --- | --- |
| Directory artifact | `<directory-name>.paq`, beside the directory | Recursive contents and relative paths |
| Regular or executable file | `<filename>.paq` | File contents |
| Symlink to a directory | `<link-name>.paq` | Referenced directory tree |
| Symlink to a file | `<link-name>.paq` | Referenced file contents |
| Source file or source symlink | None | Skipped |

- **Independent outputs:** each generated artifact gets its own hash. A directory
  artifact gets one hash for its tree, rather than a hash for each child.
- **Followed symlinks:** [paq](https://github.com/gregl83/paq) 2.0.0 runs with `--follow`. Referents must be available
  through declared outputs or dependencies. Broken links and cycles fail the
  build. A link and its referent have the same fingerprint.
- **Shared artifacts:** filegroups and other forwarding rules reuse hashes from
  their dependencies, including across packages.
- **Content fingerprints:** hidden entries and empty artifacts are included.
  Permissions, ownership, timestamps, and other filesystem metadata are excluded.

The `.paq` suffix is reserved for aspect-generated hashes. Build rules must not
produce conflicting paths.

Bazel may omit empty subdirectories when materializing directory artifacts in a
sandbox or from a cache. Use an archive output when preserving those empty
subdirectories matters.

Your deployment system chooses how to group artifacts and act on changes.
`bazel-paq` supplies the fingerprints as part of the build. Consumers track
artifact membership and removals using the current build's output inventory,
rather than assuming every file left in `bazel-bin` is current.

## Verify a Hash

With [paq](https://github.com/gregl83/paq) 2.0.0 installed:

```bash
paq --follow bazel-bin/service/server
cat bazel-bin/service/server.paq
```

The printed fingerprint should match the JSON string in the `.paq` file. Use the
same [paq](https://github.com/gregl83/paq) version as the aspect; its fingerprints are not raw `b3sum` checksums.

## Upgrading from v1

[paq](https://github.com/gregl83/paq) v2 fingerprints are incompatible with v1. Regenerate your stored baselines.
Targets with multiple outputs now receive one adjacent hash per artifact instead
of a shared `.paq` file. Update consumers accordingly and start with a clean
output tree to avoid discovering obsolete hash files.

## Development

Run the test suite:

```bash
bazel test //tests/... --test_output=all
```

On Linux, verify incremental changes, non-sandboxed execution, and link failures:

```bash
python tests/integration_test.py
```

## License

[MIT](LICENSE)
