# Example

A bazel module workspace example using `bazel-paq` target output hashing.

> **NOTE:** Not to be confused with the deprecated bazel WORKSPACE pattern.

Each generated output artifact gets its own adjacent JSON hash file, including
when one target produces multiple artifacts:

- A file or file symlink produces `<filename>.paq`.
- A directory artifact or directory symlink produces `<directory-name>.paq`
  beside the directory, covering its recursive contents.

The aspect uses paq 2.0.0 with `--follow`. Source artifacts are skipped. See
[Aspect Output](../README.md#aspect-output) for the complete contract.

## Example Projects

- [configuration](./configuration): A generated configuration file and a file symlink.
- [infrastructure](./infrastructure): A template archive and a deployment target with multiple outputs: a directory, a directory symlink, an empty directory, and an empty file.
- [python-service](./python-service): Python service executable.
- [rust-command](./rust-command): Rust executable.

## Build

From this directory:

```bash
bazel build //... --config=paq
```

## Build Output

Generated artifacts and their hashes are shown below; auxiliary manifests,
runfiles, and intermediate build files are omitted. Symlink destinations are
shown relative to their output directory for readability.

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

`pending/` and `deployment.log` start empty. Each directory hash is adjacent to
its directory, and a symlink's hash matches its referent's hash. The four outputs
of `//infrastructure:deployment` each receive a separate hash. Original source
files remain in the workspace and do not receive hashes.
