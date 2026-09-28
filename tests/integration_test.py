#!/usr/bin/env python3
"""Exercise incremental hashes and failed link following in a fresh consumer.

Run directly with Python, outside a Bazel test sandbox.
"""
import json
import os
from pathlib import Path
import subprocess
import tempfile

REPO = Path(__file__).resolve().parents[1]


def main():
    with tempfile.TemporaryDirectory(prefix="bazel-paq-contract-") as tmp:
        workspace = Path(tmp)
        (workspace / "MODULE.bazel").write_text(
            'module(name = "paq_contract_test")\n'
            'bazel_dep(name = "bazel_paq", version = "1.5.0")\n'
            f'local_path_override(module_name = "bazel_paq", path = {json.dumps(str(REPO))})\n'
        )
        (workspace / "BUILD.bazel").write_text('''
load(":outputs.bzl", "outputs", "bad_link")
outputs(name = "service", srcs = ["first.txt", "second.txt"])
bad_link(name = "broken", destination = "missing")
bad_link(name = "cycle", destination = "cycle")
''')
        (workspace / "outputs.bzl").write_text('''
def _outputs(ctx):
    files = []
    for i, src in enumerate(ctx.files.srcs):
        out = ctx.actions.declare_file("first" if i == 0 else "second")
        ctx.actions.run_shell(inputs = [src], outputs = [out],
            arguments = [src.path, out.path], command = 'cp "$1" "$2"')
        files.append(out)
    link = ctx.actions.declare_symlink("link")
    ctx.actions.symlink(output = link, target_path = "first")
    files.append(link)
    return [DefaultInfo(files = depset(files))]
outputs = rule(implementation = _outputs, attrs = {"srcs": attr.label_list(allow_files = True)})

def _bad_link(ctx):
    link = ctx.actions.declare_symlink(ctx.label.name)
    ctx.actions.symlink(output = link, target_path = ctx.attr.destination)
    return [DefaultInfo(files = depset([link]))]
bad_link = rule(implementation = _bad_link, attrs = {"destination": attr.string()})
''')
        (workspace / "first.txt").write_text("first version\n")
        (workspace / "second.txt").write_text("unchanged\n")
        env = dict(os.environ, USE_BAZEL_VERSION="9.2.0")
        bazel = ["bazel", "--output_base=" + str(workspace / "bazel-state")]

        def build(target, strategy="sandboxed", succeeds=True):
            result = subprocess.run(
                bazel + ["build", target,
                         "--aspects=@bazel_paq//:defs.bzl%paq_aspect",
                         "--output_groups=paq_files", "--strategy=PaqAspect=" + strategy],
                cwd=workspace, env=env, text=True, capture_output=True,
            )
            if (result.returncode == 0) != succeeds:
                raise AssertionError(result.stdout + result.stderr)
            return result.stdout + result.stderr

        def hashes():
            return {name: json.loads((workspace / "bazel-bin" / (name + ".paq")).read_text())
                    for name in ["first", "second", "link"]}

        try:
            build("//:service")
            before = hashes()
            assert before["first"] == before["link"]
            (workspace / "first.txt").write_text("second version\n")
            build("//:service")
            after = hashes()
            assert after["first"] != before["first"]
            assert after["second"] == before["second"]
            assert after["link"] == after["first"]

            # Force new actions without sandboxing, with unrelated files and
            # an old aggregate hash present in the same output directory.
            (workspace / "bazel-bin" / "unrelated").write_text("noise")
            (workspace / "bazel-bin" / ".paq").write_text("old hash")
            for name in after:
                (workspace / "bazel-bin" / (name + ".paq")).unlink()
            build("//:service", strategy="local")
            assert hashes() == after
            for target in ["broken", "cycle"]:
                log = build("//:" + target, succeeds=False)
                assert "failed to hash" in log, log
                assert not (workspace / "bazel-bin" / (target + ".paq")).exists()
            print("PASS: independent artifact changes, followed-link changes, local isolation, broken links, cycles")
        finally:
            subprocess.run(bazel + ["shutdown"], cwd=workspace, env=env, capture_output=True)


if __name__ == "__main__":
    main()
