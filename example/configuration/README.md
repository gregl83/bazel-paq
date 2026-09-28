# Configuration

A generated configuration file and a symlink to it, each with an adjacent `.paq`.

`config` copies `config.json` to `config.out.json` using
[bazel_skylib](https://github.com/bazelbuild/bazel-skylib). `config_link` produces
`config.link.json`. Their hashes match because paq follows the link.
