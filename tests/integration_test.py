#!/usr/bin/env python3
"""Exercise incremental changes, failed builds, and cache restoration.

Run directly with Python, outside a Bazel test sandbox.
"""
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[1]
ARTIFACTS = ["first", "second", "link", "chain", "tree.out", "tree.link"]


def main():
    with tempfile.TemporaryDirectory(prefix="bazel-paq-contract-") as tmp:
        workspace = Path(tmp)
        (workspace / "MODULE.bazel").write_text(
            'module(name = "paq_contract_test")\n'
            'bazel_dep(name = "bazel_paq", version = "2.0.0")\n'
            f'local_path_override(module_name = "bazel_paq", path = {json.dumps(str(REPO))})\n',
            encoding="utf-8",
        )
        shutil.copyfile(REPO / "tests/integration_outputs.bzl", workspace / "outputs.bzl")

        def write_build(link_target="first"):
            (workspace / "BUILD.bazel").write_text('''
load(":outputs.bzl", "outputs", "link_output")
outputs(name = "service", srcs = ["first.txt", "second.txt"],
        tree_srcs = glob(["tree/**"]), link_target = %s)
link_output(name = "broken", out = "broken", destination = "missing")
link_output(name = "cycle", out = "cycle", destination = "cycle")
genrule(name = "external", srcs = ["external.txt"], outs = ["external/value"],
        cmd = "cp $(SRCS) $@")
link_output(name = "external_link", out = "links/external", destination = "../external/value", srcs = [":external"])
''' % json.dumps(link_target), encoding="utf-8")

        write_build()
        (workspace / "first.txt").write_text("first version\n", encoding="utf-8")
        (workspace / "second.txt").write_text("unchanged\n", encoding="utf-8")
        (workspace / "external.txt").write_text("external version one\n", encoding="utf-8")
        tree = workspace / "tree"
        (tree / "nested").mkdir(parents=True)
        (tree / "nested/item").write_text("original\n", encoding="utf-8")
        env = dict(os.environ, USE_BAZEL_VERSION="9.2.0")
        bazel = [shutil.which("bazel") or "bazel", "--output_base=" + str(workspace / "bazel-state")]
        windows = os.name == "nt"
        if windows:
            bazel.append("--windows_enable_symlinks")
        default_strategy = "local" if windows else "sandboxed"
        common = ["--action_env=PATH"]
        if windows:
            common += ["--enable_runfiles", "--shell_executable=" + env["BAZEL_SH"]]
        build_number = 0
        disk_cache = workspace / "disk-cache"
        out = None

        def invoke(args):
            result = subprocess.run(bazel + args, cwd=workspace, env=env,
                                    text=True, encoding="utf-8", errors="replace", capture_output=True)
            return result.returncode, result.stdout + result.stderr

        def build(target, strategy=default_strategy, succeeds=True, extra_args=()):
            nonlocal build_number
            build_number += 1
            events = workspace / ("events-" + str(build_number) + ".json")
            code, log = invoke(["build", target,
                                "--aspects=@bazel_paq//:defs.bzl%paq_aspect",
                                "--output_groups=paq_files", "--strategy=PaqAspect=" + strategy,
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
            return log

        def fingerprint(name):
            return json.loads((out / (name + ".paq")).read_text(encoding="utf-8"))

        def hashes():
            return {name: fingerprint(name) for name in ARTIFACTS}

        def check_links(values):
            assert values["first"] == values["link"] == values["chain"]
            assert values["tree.out"] == values["tree.link"]

        try:
            build("//:service")
            # bazel-bin is not necessarily a workspace symlink on every host.
            info = subprocess.run(bazel + ["info", "bazel-bin"], cwd=workspace, env=env,
                                  text=True, capture_output=True, check=True)
            out = Path(info.stdout.strip())
            before = hashes()
            check_links(before)
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
            assert (out / "tree.out/nested/item").read_text(encoding="utf-8") == "modified\n"
            print("PASS: directory and file outputs and their hashes restore from disk cache", flush=True)

            for target in ["broken", "cycle"]:
                log = build("//:" + target, succeeds=False)
                assert "failed to hash" in log, log
                assert not (out / (target + ".paq")).exists()
            for failure_mode in ["--nokeep_going", "--keep_going"]:
                for destination in ["missing", "link"]:
                    write_build()
                    build("//:service")
                    previous = {name: fingerprint(name) for name in ["link", "chain"]}
                    write_build(destination)
                    # Serial execution exercises cancellation before all hash actions
                    # run. Old outputs may remain; aspect completion is authoritative.
                    log = build("//:service", succeeds=False,
                                extra_args=("--jobs=1", failure_mode))
                    assert "failed to hash" in log, log
                    for name, old_hash in previous.items():
                        if (out / (name + ".paq")).exists():
                            assert fingerprint(name) == old_hash, log
            print("PASS: broken links and cycles report aspect failure with and without keep-going", flush=True)
        finally:
            invoke(["shutdown"])


if __name__ == "__main__":
    main()
