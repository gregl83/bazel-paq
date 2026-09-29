# Release Testing

Use a disposable checkout. Install Bazelisk and the same paq version pinned in
`extensions.bzl`. On Windows, use the Bash/symlink setup in
[ci.yml](../.github/workflows/ci.yml).

```bash
cd example
export USE_BAZEL_VERSION=9.2.0
bazel build --config=paq //...
```

Save the initial `.paq` contents outside `bazel-bin` for comparison. Paths below
are relative to `example/`; output paths are beneath `bazel-bin/`. After each
case, undo source edits and rebuild before starting the next case. Record pass
or fail for each row. Automated references cover equivalent fixtures, not the
example workspace itself. Python test names belong to `IntegrationTests` in
[integration_test.py](../tests/integration_test.py); `//tests:` labels are Bazel targets.

| Case | Human action | Expected result | Automated tests |
| --- | --- | --- | --- |
| Output layout | Inspect `infrastructure/templates.out`, `templates.link`, `pending`, and `deployment.log`, plus `configuration/config.out.json` and `config.link.json`. | Each has an adjacent `<name>.paq` containing a quoted 64-character hexadecimal hash. Directory hashes are beside, not inside, their directories. | [//tests:test_mixed_outputs][bazel], [//tests:test_edge_outputs_hash][bazel], [test_successful_outputs_and_incremental_changes][integration] |
| Empty outputs | Open `infrastructure/pending` and `deployment.log`. | Directory and file are empty; both still have valid sidecars. | [//tests:test_edge_outputs_hash][bazel], [test_successful_outputs_and_incremental_changes][integration] |
| Executable | Inspect the Rust `command` output (`command.exe` on Windows) in `rust-command/`. | Executable has its own sidecar. | [//tests:test_edge_outputs_hash][bazel], [test_successful_outputs_and_incremental_changes][integration] |
| Independent comparison | Run `paq --follow PATH` on each output above, including both links and the executable. Compare printed hashes with sidecar contents, ignoring JSON quotes. | Every standalone hash matches. Each link matches its referent. | [test_successful_outputs_and_incremental_changes][integration] |
| Unchanged rebuild | Run the same build again without edits. | All hash values stay identical. | [test_successful_outputs_and_incremental_changes][integration] |
| Directory content | Add a comment to `infrastructure/templates/dev-template.yaml`; rebuild. | `templates.out.paq` and `templates.link.paq` change together; `pending.paq`, `deployment.log.paq`, and configuration hashes do not change. | [test_successful_outputs_and_incremental_changes][integration] |
| Directory membership | Separately add, rename, then delete a temporary `.yaml` file in `infrastructure/templates/`, rebuilding after each operation. | Directory and directory-link hashes change at each step. Removing the temporary file restores the original hashes. | [test_successful_outputs_and_incremental_changes][integration] |
| Hidden entry | Add `infrastructure/templates/.manual.yaml` containing a comment; rebuild. | Hidden file appears in `templates.out`; directory and directory-link hashes change. | [//tests:test_edge_outputs_hash][bazel], [test_successful_outputs_and_incremental_changes][integration] |
| Regular file | Change a value in `configuration/config.json`; rebuild. | `config.out.json.paq` and `config.link.json.paq` change together; infrastructure hashes stay unchanged. | [test_successful_outputs_and_incremental_changes][integration] |
| Metadata only | Change only a source file's modification time; rebuild. | Hash values stay identical. | [test_successful_outputs_and_incremental_changes][integration] |
| Unrelated output | Create `bazel-bin/infrastructure/unrelated.txt`; rebuild and rerun standalone paq on `templates.out`. | Directory hash stays identical; the neighboring file is excluded. | [test_successful_outputs_and_incremental_changes][integration] |
| Broken link | In `infrastructure/defs.bzl`, temporarily replace `target_path = templates.basename` with `target_path = "missing"`; build `//infrastructure:deployment` with `--config=paq`. | Build exits nonzero. Do not accept any sidecars from this build, even if old ones remain. | [test_broken_directory_link][integration], [test_missing_after_success_stop][integration], [test_missing_after_success_continue][integration] |
| Link cycle | Repeat the previous case with `target_path = "templates.link"`. | Build exits nonzero. Restore the original target path and verify the next build succeeds. | [test_directory_link_cycle][integration], [test_cycle_after_success_stop][integration], [test_cycle_after_success_continue][integration] |
| Cache restoration | Run the cache commands below, then repeat standalone comparisons. | Disk-cache hits are reported; artifacts and sidecars are restored with identical hashes. | [test_successful_outputs_and_incremental_changes][integration] |

Check cache restoration separately after restoring all source edits:

```bash
cache_dir="$(mktemp -d)"
bazel build --config=paq --disk_cache="$cache_dir" //...
# Save the hash values, then remove build outputs:
bazel clean
bazel build --config=paq --disk_cache="$cache_dir" //...
```

Expect reported disk-cache hits, restored artifacts and sidecars, and identical
hash values. Repeat the standalone comparisons on the restored outputs.

Record: `commit | OS/architecture | Bazel/paq versions | case | pass/fail | notes`.
Run on each supported platform before release; this complements the automated
suites and does not replace them.

[integration]: ../tests/integration_test.py
[bazel]: ../tests/BUILD
