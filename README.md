[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/gregl83/bazel-paq/blob/master/LICENSE)
# bazel-paq

Bazel rule for hashing targets.

Easily track and deploy build deltas.

An optimization for monorepo releases.

## Purpose

Reduce bazel build deployments to unreleased targets.

Requires cache of build target hashes.

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
