# Examples

A bazel module workspace example using `bazel-paq` target output hashing.

> **NOTE:** Not to be confused with the deprecated bazel WORKSPACE pattern.

For each build output, the `bazel-paq` aspect will produce a `.paq` hash of that output.

Naming convention is `target_output_filename.ext.paq` for files or `.paq` for directories.

## Example Projects 

- [configuration](./configuration): Single file output `paq` hash.
- [infrastructure](./infrastructure): Directory output `paq` hash.
- [python-service](./python-service): Python Flask output `paq` hash.
- [rust-command](./rust-command): Rust binary output `paq` hash.

## Build Output

```text
bazel-out/k8-fastbuild/bin
|-- configuration
|   |-- config.out.json
|   `-- config.out.json.paq
|-- infrastructure
|   |-- templates.manifest
|   |-- templates.tar
|   `-- templates.tar.paq
|-- python-service
|   |-- app
|   |-- app.paq
|   |-- app.repo_mapping
|   |-- app.runfiles
|   |   |-- MANIFEST
|   |   |-- __init__.py
|   |   |-- _main
|   |   `-- rules_python++python+python_3_11_x86_64-unknown-linux-gnu
|   `-- app.runfiles_manifest
`-- rust-command
    |-- command
    |-- command.paq
    |-- command.repo_mapping
    |-- command.runfiles
    |   |-- MANIFEST
    |   `-- _main
    `-- command.runfiles_manifest
```
