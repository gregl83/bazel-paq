#!/usr/bin/env python3
"""Compare standalone paq runs, incremental changes, failures, and cache restoration.

Run directly with Python, outside a Bazel test sandbox.
"""
import json
import os
from pathlib import Path
import re
import shutil
import socket
import stat
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
UNUSUAL_NAMES = ["space name", "café", "semi;colon", "quote'name", "dollar$sign", "equals=name"]
ARTIFACTS = [
    "first", "second", "hard.link", "hard.original", "link", "chain", "tree.out", "tree.link", "directory.chain",
    "empty.directory", "empty.file", "executable", "binary",
    "empty.directory.link", "empty.file.link", "executable.link",
] + ["names/" + name for name in UNUSUAL_NAMES]


def run_scenario(scenario):
    with tempfile.TemporaryDirectory(prefix="bazel-paq-contract-") as tmp:
        workspace = Path(tmp)
        (workspace / "MODULE.bazel").write_text(
            'module(name = "paq_contract_test")\n'
            'bazel_dep(name = "bazel_paq", version = "2.0.0")\n'
            f'local_path_override(module_name = "bazel_paq", path = {json.dumps(str(REPO))})\n'
            'paq = use_extension("@bazel_paq//:extensions.bzl", "paq_extension")\n'
            'use_repo(paq, "paq")\n',
            encoding="utf-8",
        )
        shutil.copyfile(REPO / "tests/integration_outputs.bzl", workspace / "outputs.bzl")

        def write_build(link_target="first"):
            (workspace / "BUILD.bazel").write_text('''
load(":outputs.bzl", "outputs", "link_output", "cycle_pair", "special_tree", "linked_tree")
outputs(name = "service", srcs = ["first.txt", "second.txt"],
        tree_srcs = glob(["tree/**"]), link_target = %s, names = %s)
cycle_pair(name = "cycle_pair")
linked_tree(name = "linked_tree")
link_output(name = "broken", out = "broken", destination = "missing")
link_output(name = "cycle", out = "cycle", destination = "cycle")
link_output(name = "broken_directory", out = "broken_directory", destination = "missing_directory", target_type = "directory")
link_output(name = "directory_cycle", out = "directory_cycle", destination = "directory_cycle", target_type = "directory")
genrule(name = "external", srcs = ["external.txt"], outs = ["external/value"],
        cmd = "cp $(SRCS) $@")
link_output(name = "external_link", out = "links/external", destination = "../external/value", srcs = [":external"])
''' % (json.dumps(link_target), json.dumps(UNUSUAL_NAMES, ensure_ascii=False)), encoding="utf-8")

        write_build()
        (workspace / "first.txt").write_text("first version\n", encoding="utf-8")
        (workspace / "second.txt").write_text("unchanged\n", encoding="utf-8")
        (workspace / "external.txt").write_text("external version one\n", encoding="utf-8")
        tree = workspace / "tree"
        (tree / "nested").mkdir(parents=True)
        (tree / "nested/item").write_text("original\n", encoding="utf-8")
        (tree / ".hidden-directory").mkdir()
        (tree / ".hidden-directory/item").write_text("hidden directory\n", encoding="utf-8")
        env = dict(os.environ, USE_BAZEL_VERSION="9.2.0")
        bazel = [shutil.which("bazel") or "bazel", "--output_base=" + str(workspace / "bazel-state")]
        windows = os.name == "nt"
        if windows:
            bazel.append("--windows_enable_symlinks")
        default_strategy = "local" if windows else "sandboxed"
        common = ["--action_env=PATH", "--jobs=4"]
        if windows:
            common += ["--enable_runfiles", "--shell_executable=" + env["BAZEL_SH"]]
        build_number = 0
        disk_cache = workspace / "disk-cache"
        out = None

        def invoke(args):
            result = subprocess.run(bazel + args, cwd=workspace, env=env,
                                    text=True, encoding="utf-8", errors="replace", capture_output=True, timeout=180)
            return result.returncode, result.stdout + result.stderr

        def build(target, strategy=default_strategy, succeeds=True, extra_args=()):
            nonlocal build_number
            build_number += 1
            events = workspace / ("events-" + str(build_number) + ".json")
            # Request artifacts as well as hashes so cache hits materialize the
            # contents that standalone paq reads from disk.
            code, log = invoke(["build", target,
                                "--aspects=@bazel_paq//:defs.bzl%paq_aspect",
                                "--output_groups=+paq_files", "--strategy=PaqAspect=" + strategy,
                                "--disk_cache=" + str(disk_cache),
                                "--build_event_json_file=" + str(events)] + common + list(extra_args))
            assert (code == 0) == succeeds, log
            completions = []
            for line in events.read_text(encoding="utf-8").splitlines():
                event = json.loads(line)
                completed = event.get("id", {}).get("targetCompleted", {})
                if (completed.get("label") == target
                        and completed.get("aspect", "").endswith("%paq_aspect")
                        and "completed" in event):
                    completions.append(event["completed"])
            # The underlying target can succeed even when its hashing aspect fails.
            assert len(completions) == 1, log
            assert completions[0].get("success", False) == succeeds, log
            if succeeds and out is not None:
                compare_standalone({"//:service": ARTIFACTS, "//:external_link": ["links/external"],
                                    "//:linked_tree": ["linked_tree"]}[target])
            return log

        def fingerprint(name):
            return json.loads((out / (name + ".paq")).read_text(encoding="utf-8"))

        def hashes():
            return {name: fingerprint(name) for name in ARTIFACTS}

        def check_links(values):
            assert values["first"] == values["hard.original"] == values["hard.link"] == values["link"] == values["chain"]
            assert values["tree.out"] == values["tree.link"] == values["directory.chain"]
            assert values["empty.file"] == values["empty.file.link"]
            assert values["empty.directory"] == values["empty.directory.link"]
            assert values["executable"] == values["executable.link"]

        def compare_standalone(names):
            # Keep reference outputs outside the artifact tree and never overwrite
            # the aspect's sidecars. Each comparison uses a fresh standalone process.
            with tempfile.TemporaryDirectory(prefix="reference-", dir=workspace) as reference:
                for index, name in enumerate(names):
                    sidecar = out / (name + ".paq")
                    original = sidecar.read_bytes()
                    expected = Path(reference) / (str(index) + ".paq")
                    result = subprocess.run(
                        [str(standalone), "--follow", str(out / name), "--out=" + str(expected)],
                        cwd=workspace, env=env, text=True, encoding="utf-8",
                        errors="replace", capture_output=True, timeout=30,
                    )
                    assert result.returncode == 0, result.stdout + result.stderr
                    actual_hash = json.loads(original)
                    expected_hash = json.loads(expected.read_text(encoding="utf-8"))
                    assert actual_hash == expected_hash, (
                        f"Standalone hash mismatch for {name}: "
                        f"aspect={actual_hash}, standalone={expected_hash}"
                    )
                    assert sidecar.read_bytes() == original, f"Standalone run modified {sidecar}"

        def standalone_failure(name):
            with tempfile.TemporaryDirectory(prefix="failed-reference-", dir=workspace) as reference:
                output = Path(reference) / "hash.paq"
                result = subprocess.run(
                    [str(standalone), "--follow", str(out / name), "--out=" + str(output)],
                    cwd=workspace, env=env, text=True, encoding="utf-8",
                    errors="replace", capture_output=True, timeout=30,
                )
                assert result.returncode != 0, f"Standalone paq unexpectedly accepted {name}"
                assert "failed to hash" in result.stderr, result.stderr
                assert not output.exists(), f"Failed standalone run wrote {output}"

        def run_failure(scenario):
            if scenario in ["tree_broken", "tree_cycle"]:
                mode = scenario.removeprefix("tree_")
                reference_tree = workspace / "invalid-tree"
                reference_tree.mkdir()
                (reference_tree / "file.link").symlink_to("missing" if mode == "broken" else "file.link")
                standalone_failure(reference_tree)
                build_file = workspace / "BUILD.bazel"
                build_file.write_text(build_file.read_text(encoding="utf-8").replace(
                    'linked_tree(name = "linked_tree")',
                    'linked_tree(name = "linked_tree", mode="' + mode + '")'), encoding="utf-8")
                # Tree validation can reject these links before the aspect executes.
                code, log = invoke(["build", "//:linked_tree",
                                    "--aspects=@bazel_paq//:defs.bzl%paq_aspect",
                                    "--output_groups=+paq_files"] + common)
                assert code != 0, log
                assert not (out / "linked_tree.paq").exists(), log
                return
            if scenario.startswith("permission_"):
                protected = workspace / "protected"
                if scenario == "permission_directory":
                    protected.mkdir()
                    (protected / "child").write_text("private", encoding="utf-8")
                    dependency = "protected/child"
                else:
                    protected.write_text("private", encoding="utf-8")
                    dependency = "protected"
                with (workspace / "BUILD.bazel").open("a", encoding="utf-8") as build_file:
                    build_file.write(
                        '\nlink_output(name="unreadable", out="unreadable", destination=%s, srcs=[%s])\n'
                        % (json.dumps(str(protected)), json.dumps(dependency))
                    )
                protected.chmod(0)
                try:
                    standalone_failure(protected)
                    # Bazel may reject unreadable inputs before starting the aspect.
                    code, log = invoke(["build", "//:unreadable",
                                        "--aspects=@bazel_paq//:defs.bzl%paq_aspect",
                                        "--output_groups=+paq_files"] + common)
                    assert code != 0, log
                    assert "permission denied" in log.lower(), log
                    assert not (out / "unreadable.paq").exists()
                finally:
                    protected.chmod(0o700 if protected.is_dir() else 0o600)
                return
            if scenario in ["fifo", "socket", "device"]:
                special = workspace / "special-input"
                if scenario == "fifo":
                    os.mkfifo(special)
                elif scenario == "device":
                    special.symlink_to("/dev/null")
                else:
                    with socket.socket(socket.AF_UNIX) as sock:
                        sock.bind(str(special))
                # paq fingerprints special objects without reading their payload;
                # Bazel rejects them inside declared directory artifacts.
                reference = workspace / "special-reference.paq"
                result = subprocess.run([str(standalone), "--follow", str(special),
                                         "--out=" + str(reference)], capture_output=True,
                                        text=True, timeout=30)
                assert result.returncode == 0, result.stderr
                assert re.fullmatch("[0-9a-f]{64}", json.loads(reference.read_text()))
                with (workspace / "BUILD.bazel").open("a", encoding="utf-8") as build_file:
                    build_file.write('\nspecial_tree(name="special", kind=%s)\n' % json.dumps(scenario))
                code, log = invoke(["build", "//:special",
                                    "--aspects=@bazel_paq//:defs.bzl%paq_aspect",
                                    "--output_groups=+paq_files"] + common)
                assert code != 0, log
                assert "unsupported type" in log, log
                assert not (out / "special-output.paq").exists(), log
                print("PASS: Bazel rejects generated " + scenario + " artifacts", flush=True)
                return
            if scenario in ["broken", "cycle", "broken_directory", "directory_cycle", "cycle_pair"]:
                target = "//:" + scenario
                # Materialize the link before comparing independent failure paths.
                code, log = invoke(["build", target] + common)
                assert code == 0, log
                names = ["pair.first", "pair.second"] if scenario == "cycle_pair" else [scenario]
                for name in names:
                    standalone_failure(name)
                log = build(target, succeeds=False)
                assert "failed to hash" in log, log
                for name in names:
                    assert not (out / (name + ".paq")).exists()
            else:
                destination = "missing" if "missing" in scenario else "link"
                failure_mode = "--keep_going" if scenario.endswith("continue") else "--nokeep_going"
                build("//:service")
                previous = {name: fingerprint(name) for name in ["link", "chain"]}
                write_build(destination)
                log = build("//:service", succeeds=False,
                            extra_args=("--jobs=1", failure_mode))
                assert "failed to hash" in log, log
                for name, old_hash in previous.items():
                    standalone_failure(name)
                    # Old sidecars may remain after cancellation; BEP failure is authoritative.
                    if (out / (name + ".paq")).exists():
                        assert fingerprint(name) == old_hash, log
            print("PASS: independent Bazel and standalone failures: " + scenario, flush=True)

        try:
            # Resolve the pinned platform binary through Bazel, then copy it out of
            # bazel-out so standalone checks also work after bazel clean.
            code, log = invoke(["build", "@paq//:binary"] + common)
            assert code == 0, log
            tool_info = subprocess.run(
                bazel + ["cquery", "@paq//:binary", "--output=files"] + common,
                cwd=workspace, env=env, text=True, encoding="utf-8",
                capture_output=True, check=True,
            )
            tool_paths = tool_info.stdout.strip().splitlines()
            assert len(tool_paths) == 1, tool_info.stdout
            root_info = subprocess.run(bazel + ["info", "execution_root"], cwd=workspace,
                                       env=env, text=True, encoding="utf-8",
                                       capture_output=True, check=True)
            standalone = workspace / ("standalone-paq.exe" if windows else "standalone-paq")
            shutil.copyfile(Path(root_info.stdout.strip()) / tool_paths[0], standalone)
            standalone.chmod(standalone.stat().st_mode | stat.S_IXUSR)
            # bazel-bin is not necessarily a workspace symlink on every host.
            info = subprocess.run(bazel + ["info", "bazel-bin"], cwd=workspace, env=env,
                                  text=True, capture_output=True, check=True)
            out = Path(info.stdout.strip())
            if scenario != "success":
                run_failure(scenario)
                return
            build("//:service")
            build("//:linked_tree")
            before = hashes()
            check_links(before)
            # Metadata changes must not affect content fingerprints.
            metadata_file = out / "first"
            metadata = metadata_file.stat()
            try:
                metadata_file.chmod(metadata.st_mode | stat.S_IWUSR | stat.S_IXUSR)
                os.utime(metadata_file, (metadata.st_atime, metadata.st_mtime + 60))
                compare_standalone(["first"])
            finally:
                os.utime(metadata_file, ns=(metadata.st_atime_ns, metadata.st_mtime_ns))
                metadata_file.chmod(metadata.st_mode)
            (workspace / "first.txt").write_text("second version\n", encoding="utf-8")
            build("//:service")
            after = hashes()
            assert after["first"] != before["first"]
            assert after["second"] == before["second"]
            assert after["tree.out"] == before["tree.out"]
            check_links(after)
            print("PASS: independent outputs and chained links track content changes", flush=True)

            # Every mutation changes the tree fingerprint and its linked view,
            # while unrelated file outputs retain their fingerprints.
            mutations = [
                ("modify", lambda: (tree / "nested/item").write_text("modified\n", encoding="utf-8")),
                ("add", lambda: (tree / "added").write_text("new\n", encoding="utf-8")),
                ("rename", lambda: (tree / "added").rename(tree / "renamed")),
                ("delete", lambda: (tree / "renamed").unlink()),
                ("hidden", lambda: (tree / ".hidden").write_text("hidden\n", encoding="utf-8")),
            ]
            for name, mutate in mutations:
                previous = hashes()
                mutate()
                build("//:service")
                current = hashes()
                assert current["tree.out"] != previous["tree.out"], name
                assert current["first"] == previous["first"], name
                assert current["second"] == previous["second"], name
                check_links(current)
            print("PASS: directory modify/add/rename/delete/hidden changes", flush=True)
            write_build("second")
            build("//:service")
            assert fingerprint("link") == fingerprint("chain") == fingerprint("second")
            write_build()
            build("//:service")
            check_links(hashes())
            print("PASS: links track retargeting between valid outputs", flush=True)

            build("//:external_link")
            external_before = fingerprint("links/external")
            (workspace / "external.txt").write_text("external version two\n", encoding="utf-8")
            build("//:external_link")
            assert fingerprint("links/external") != external_before
            print("PASS: link to a declared dependency outside its output directory", flush=True)

            # Force actions to run locally, avoiding both action and disk caches.
            expected = hashes()
            (out / "unrelated").write_text("noise", encoding="utf-8")
            (out / ".paq").write_text("old hash", encoding="utf-8")
            for artifact in ARTIFACTS:
                sidecar = out / (artifact + ".paq")
                # Bazel outputs can be read-only; Windows refuses to unlink them.
                sidecar.chmod(sidecar.stat().st_mode | stat.S_IWUSR)
                sidecar.unlink()
                assert not sidecar.exists(), sidecar
            # Use a fresh cache instead of silently ignoring cache-deletion errors.
            # This build populates it for the restoration check below.
            disk_cache = workspace / "local-disk-cache"
            assert not disk_cache.exists()
            log = build("//:service", strategy="local")
            assert not re.search(r"[1-9][0-9]* disk cache hit", log), log
            assert hashes() == expected
            print("PASS: local execution excludes neighboring outputs and old hashes", flush=True)

            # Remove the complete output tree, then require disk-cache hits and
            # compare all restored directory/file/link sidecars with the originals.
            code, log = invoke(["clean"])
            assert code == 0, log
            assert not (out / "tree.out.paq").exists()
            log = build("//:service")
            assert re.search(r"[1-9][0-9]* disk cache hit", log), log
            assert hashes() == expected
            build("//:linked_tree")
            assert (out / "tree.out/nested/item").read_text(encoding="utf-8") == "modified\n"
            print("PASS: directory and file outputs and their hashes restore from disk cache", flush=True)

            print("PASS: every successful build matches independent paq --follow runs", flush=True)
        finally:
            invoke(["shutdown"])


class IntegrationTests(unittest.TestCase):
    """Each scenario gets its own consumer workspace and Bazel server."""

    def test_successful_outputs_and_incremental_changes(self):
        run_scenario("success")

    @unittest.skipIf(os.name == "nt" or getattr(os, "geteuid", lambda: 0)() == 0,
                     "requires an unprivileged POSIX process to enforce mode permissions")
    def test_unreadable_file(self):
        run_scenario("permission_file")

    @unittest.skipIf(os.name == "nt" or getattr(os, "geteuid", lambda: 0)() == 0,
                     "requires an unprivileged POSIX process to enforce mode permissions")
    def test_unreadable_directory(self):
        run_scenario("permission_directory")

    @unittest.skipIf(os.name == "nt", "POSIX FIFO artifacts are unavailable on Windows")
    def test_fifo_output_rejected(self):
        run_scenario("fifo")

    @unittest.skipIf(os.name == "nt", "Unix-domain socket output fixture requires POSIX")
    def test_socket_output_rejected(self):
        run_scenario("socket")

    @unittest.skipIf(os.name == "nt" or not Path("/dev/null").exists(),
                     "requires the POSIX null device")
    def test_device_link_output_rejected(self):
        run_scenario("device")

    def test_broken_link_inside_directory(self):
        run_scenario("tree_broken")

    def test_link_cycle_inside_directory(self):
        run_scenario("tree_cycle")

    def test_broken_file_link(self):
        run_scenario("broken")

    def test_file_link_cycle(self):
        run_scenario("cycle")

    def test_broken_directory_link(self):
        run_scenario("broken_directory")

    def test_two_link_cycle(self):
        run_scenario("cycle_pair")

    def test_directory_link_cycle(self):
        run_scenario("directory_cycle")

    def test_missing_after_success_stop(self):
        run_scenario("after_missing_stop")

    def test_missing_after_success_continue(self):
        run_scenario("after_missing_continue")

    def test_cycle_after_success_stop(self):
        run_scenario("after_cycle_stop")

    def test_cycle_after_success_continue(self):
        run_scenario("after_cycle_continue")


if __name__ == "__main__":
    unittest.main(verbosity=2)
