[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/gregl83/bazel-paq/blob/master/LICENSE)
# bazel-paq

Bazel rule for hashing targets.

Easily track and deploy build changes.

## Purpose

Provide a mechanism to identify build targets that have been updated.

Use this to limit releases to targets that have changed.

Requires a cache of released hashes.

## Bazel Build Release Workflow

1. Read target hash from `.paq` file.
2. Read released hash from cache.
3. Compare target and released hashes.
4. If equal, skip target release.
5. If unequal, release target.
6. Set cache released hash to target hash.

## License

[MIT](LICENSE)
