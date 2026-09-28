[![Build](https://github.com/gregl83/bazel-paq/actions/workflows/ci.yml/badge.svg)](https://github.com/gregl83/bazel-paq/actions/workflows/ci.yml)
![Release](https://img.shields.io/github/v/release/gregl83/bazel-paq)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/gregl83/bazel-paq/blob/master/LICENSE)

# bazel-paq

[Bazel aspect](https://bazel.build/extending/aspects) for computing target output hashes.

Easily track build deltas by comparing output hashes with deployed artifacts or previous builds.

## Usage

### Workspace Configuration

#### 1. Add Module Dependency

Add the following to the dependency section the workspace `MODULE.bazel`:

```text
bazel_dep(name = "bazel_paq", version = "2.0.0")
```

#### 2. Add Load Definition

Add the following to the workspace `defs.bzl`:

```text
load("@bazel_paq//:defs.bzl", "paq_aspect")
```

### Executing Builds

#### Short Command

Add the following to the workspace `.bazelrc` configuration file:

```text
build:paq --aspects=@bazel_paq//:defs.bzl%paq_aspect
build:paq --output_groups=+paq_files
```

Execute build:

```bash
bazel build --config=paq //...
```

#### Long Command

```bash
bazel build //... --aspects=@bazel_paq//:defs.bzl%paq_aspect --output_groups=+paq_files
```

### Executing Tests

```bash
bazel test //tests/... --test_output=all
```

On Linux, also run `python tests/integration_test.py` to verify incremental changes,
non-sandboxed execution, and build failures for broken links and cycles.

## Aspect Output

The aspect produces one adjacent `.paq` file for **each generated artifact** in
`DefaultInfo.files`, even when a target exposes several outputs.

| Output artifact | Hash output | Hash input |
| --- | --- | --- |
| Regular or executable file | `<filename>.paq` | File contents |
| Directory artifact | `<directory-name>.paq`, beside the directory | Its recursive contents and relative paths |
| Symlink to a file | `<link-name>.paq` | Referenced file contents |
| Symlink to a directory | `<link-name>.paq` | Referenced directory tree |
| Source file or source symlink | None | Skipped |

Empty files and empty directory artifacts are supported. Hidden entries are
included. Executable bits, ownership, timestamps, and other filesystem metadata
are not hashed. Bazel may omit empty nested directories when materializing a
sandbox or cached tree artifact; they are not a reliable part of a directory's
tracked contents. Use an archive output if empty subdirectories must be preserved.

Every invocation uses paq **2.0.0** with `--follow`. Link targets must be available
through declared outputs or dependencies. Broken links and cycles fail the hash
action and the build. Links are fingerprinted by their referents, not their link
text; a link and its referent can therefore have identical hashes.

Multiple outputs are hashed independently. There is no aggregate target hash or
common-parent directory scan. For example, a target producing `server` and
`config.json` produces `server.paq` and `config.json.paq`. A directory artifact
receives one recursive hash, not a separate hash for each child.

Filegroups and other forwarding rules reuse hashes from their dependencies,
including across packages. The `paq_files` output group contains the hashes for
the target's generated artifacts. The `.paq` suffix is reserved for these hash
files; build rules must not generate conflicting paths.

Each `.paq` file is valid JSON containing one BLAKE3-based fingerprint in double
quotes. It records no target membership or deletion events. Consumers constructing
deployment snapshots must record the complete artifact inventory separately.

### Migration

paq v2 fingerprints are incompatible with v1; regenerate existing baselines.
Multiple-output targets now produce an adjacent hash for every artifact instead
of a shared `.paq` or `<target-name>.paq`. Update consumers to discover those
per-artifact hashes, and use a clean output tree when migrating so obsolete hash
files are not mistaken for current outputs.

## Hashing Algorithm

The [paq](https://github.com/gregl83/paq) executable used in `bazel-paq` is powered by the `blake3` hashing algorithm.

#### Output Hash Validation

1. **Install:** Make the [paq](https://github.com/gregl83/paq) executable available on validation system.
2. **Compute:** Run `paq --follow <artifact>` with paq 2.0.0 for each generated file or directory.
3. **Compare:** Open respective `.paq` build output and validate it equals computed hash from Step 2.

## Example Workspace

The [example](example) directory contains a complete Bazel module workspace demonstrating `bazel-paq` usage.

### Output Structure

The example covers regular and executable files, directory artifacts, file and
directory symlinks, empty artifacts, and multiple outputs from one target.
Auxiliary manifests, runfiles, and intermediate build files are omitted below;
symlink destinations are shortened for readability.

```text
bazel-bin
|-- configuration
|   |-- config.out.json
|   |-- config.out.json.paq
|   |-- config.link.json -> config.out.json
|   `-- config.link.json.paq
|-- infrastructure
|   |-- templates.tar
|   |-- templates.tar.paq
|   |-- templates.out/
|   |   |-- dev-template.yaml
|   |   |-- prod-template.yaml
|   |   `-- test-template.yaml
|   |-- templates.out.paq
|   |-- templates.link -> templates.out/
|   |-- templates.link.paq
|   |-- pending/
|   |-- pending.paq
|   |-- deployment.log
|   `-- deployment.log.paq
|-- python-service
|   |-- app
|   `-- app.paq
`-- rust-command
    |-- command
    `-- command.paq
```

## License

[MIT](LICENSE)
