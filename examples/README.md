# Example

A bazel module workspace example using `bazel-paq` target output hashing.

> **NOTE:** Not to be confused with the deprecated bazel WORKSPACE pattern.

For each build output, the `bazel-paq` aspect will produce a `.paq` hash of that output.

Naming convention is `target_output_filename.ext.paq` for files or `.paq` for directories.

## Build Examples

- [configuration](./configuration): Single file output `paq` hash.
- [infrastructure](./infrastructure): Directory output `paq` hash.
- [python-service](./python-service): Python Flask output `paq` hash.
- [rust-command](./rust-command): Rust binary output `paq` hash.
