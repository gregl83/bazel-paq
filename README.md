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
bazel_dep(name = "bazel_paq", version = "1.4.0")
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
bazel build //... --aspects=//:defs.bzl%paq_aspect --output_groups=+paq_files
```

### Executing Tests

```bash
bazel test tests:all --test_output=all
```

## Aspect Output

Executing `bazel build` with the `bazel-paq` aspect configured will compute unique hashes for every build target output.

Output hash filenames are `target_output_filename.ext.paq` for files and `.paq` for directories.

Files are valid JSON and contain a single `blake3` hash in double quotes.

## Hashing Algorithm

The [paq](https://github.com/gregl83/paq) executable used in `bazel-paq` is powered by the `blake3` hashing algorithm.

#### Output Hash Validation

1. **Install:** Make the [paq](https://github.com/gregl83/paq) executable available on validation system.
2. **Compute:** Hash a build target output using `paq`.
3. **Compare:** Open respective `.paq` build output and validate it equals computed hash from Step 2.

## Workspace Example

See the [example](example) directory for a bazel module workspace that uses `bazel-paq`.

Run builds and inspect outputs!

## License

[MIT](LICENSE)
