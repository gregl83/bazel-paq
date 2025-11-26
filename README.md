![Release](https://img.shields.io/github/v/release/gregl83/bazel-paq)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/gregl83/bazel-paq/blob/master/LICENSE)

# bazel-paq

[Bazel aspect](https://bazel.build/extending/aspects) for computing target hashes.

Easily track build deltas by comparing target hashes with deployed artifacts or previous builds.

## Usage

### Workspace Configuration

#### 1. Add Module Dependency

Add the following to the dependency section of a workspace's `MODULE.bazel`:

```text
bazel_dep(name = "bazel_paq", version = "1.3.3")
```

#### 2. Add Load Definition

Add the following to a workspace's `defs.bzl`:

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
bazel build //... --aspects=//:defs.bzl%paq_aspect --output_groups=+paq_files
```

## Aspect Output

Executing `bazel build` with the `bazel-paq` aspect configuration will compute unique hashes for every build target output.

Output hash filenames are `target_output_filename.ext.paq` for files and `.paq` for directories.

Files are valid JSON and contain a single `blake3` hash in double quotes.

## Hashing Algorithm

The [paq](https://github.com/gregl83/paq) executable used in `bazel-paq` is powered by the `blake3` hashing algorithm to compute hashes of files or directories.

Output hashes can be validated by installing [paq](https://github.com/gregl83/paq), computing build target hashes in bazel's `bazel-bin` directory, and comparing results against `.paq` build outputs.

## Example

See the [examples](examples) directory for a bazel module workspace using `bazel-paq`.

## License

[MIT](LICENSE)
