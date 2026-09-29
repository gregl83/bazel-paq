"""Fixtures copied into the integration test's temporary consumer workspace."""

def _outputs(ctx):
    files = []
    for i, src in enumerate(ctx.files.srcs):
        out = ctx.actions.declare_file("first" if i == 0 else "second")
        ctx.actions.run_shell(
            inputs = [src],
            outputs = [out],
            arguments = [src.path, out.path],
            command = 'cp "$1" "$2"',
        )
        files.append(out)
    tree = ctx.actions.declare_directory("tree.out")
    arguments = [tree.path]
    for src in ctx.files.tree_srcs:
        arguments.extend([src.path, src.short_path[len("tree/"):]])
    ctx.actions.run_shell(
        inputs = ctx.files.tree_srcs,
        outputs = [tree],
        arguments = arguments,
        command = """
            set -eu
            tree="$1"
            mkdir -p "$tree"
            shift
            while [ "$#" -gt 0 ]; do
                mkdir -p "$(dirname "$tree/$2")"
                cp "$1" "$tree/$2"
                shift 2
            done
        """,
    )
    files.append(tree)
    hard_original = ctx.actions.declare_file("hard.original")
    hardlink = ctx.actions.declare_file("hard.link")
    ctx.actions.run_shell(
        inputs = [files[0]],
        outputs = [hard_original, hardlink],
        arguments = [files[0].path, hard_original.path, hardlink.path],
        command = 'cp "$1" "$2" && ln "$2" "$3"',
    )
    files.extend([hard_original, hardlink])
    empty_tree = ctx.actions.declare_directory("empty.directory")
    ctx.actions.run_shell(outputs = [empty_tree], arguments = [empty_tree.path], command = 'mkdir -p "$1"')
    files.append(empty_tree)
    for name, content in [
        ("empty.file", ""),
        ("executable", "#!/bin/sh\necho hello\n"),
        ("binary", "\000\001\002\377\n"),
    ] + [("names/" + name, "unusual path\n") for name in ctx.attr.names]:
        out = ctx.actions.declare_file(name)
        ctx.actions.write(out, content, is_executable = name == "executable")
        files.append(out)
    for name, destination in [
        ("link", ctx.attr.link_target), ("chain", "link"), ("tree.link", "tree.out"),
        ("empty.file.link", "empty.file"), ("empty.directory.link", "empty.directory"),
        ("directory.chain", "tree.link"), ("executable.link", "executable"),
    ]:
        link = ctx.actions.declare_symlink(name)
        # The tree may not exist yet; Windows must not infer a file symlink.
        ctx.actions.symlink(
            output = link,
            target_path = destination,
            target_type = "directory" if name in ["tree.link", "empty.directory.link", "directory.chain"] else "file",
        )
        files.append(link)
    return [DefaultInfo(files = depset(files))]

outputs = rule(
    implementation = _outputs,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "tree_srcs": attr.label_list(allow_files = True),
        "link_target": attr.string(default = "first"),
        "names": attr.string_list(),
    },
)

def _link(ctx):
    link = ctx.actions.declare_symlink(ctx.attr.out)
    ctx.actions.symlink(output = link, target_path = ctx.attr.destination, target_type = ctx.attr.target_type)
    return [DefaultInfo(files = depset([link]))]

link_output = rule(
    implementation = _link,
    attrs = {
        "out": attr.string(),
        "destination": attr.string(),
        "target_type": attr.string(default = "file", values = ["file", "directory"]),
        "srcs": attr.label_list(allow_files = True),
    },
)

def _cycle_pair(ctx):
    files = [ctx.actions.declare_symlink(name) for name in ["pair.first", "pair.second"]]
    for index in [0, 1]:
        ctx.actions.symlink(output = files[index], target_path = files[1 - index].basename, target_type = "file")
    return [DefaultInfo(files = depset(files))]

cycle_pair = rule(implementation = _cycle_pair)

def _special_tree(ctx):
    tree = ctx.actions.declare_directory("special-output")
    command = 'mkdir -p "$1"; '
    if ctx.attr.kind == "fifo":
        command += 'mkfifo "$1/entry"'
    elif ctx.attr.kind == "device":
        command += 'ln -s /dev/null "$1/entry"'
    else:
        command += "python3 -c 'import socket,sys; socket.socket(socket.AF_UNIX).bind(sys.argv[1])' \"$1/entry\""
    ctx.actions.run_shell(outputs = [tree], arguments = [tree.path], command = command)
    return [DefaultInfo(files = depset([tree]))]

special_tree = rule(implementation = _special_tree, attrs = {"kind": attr.string(values = ["fifo", "socket", "device"])})

def _linked_tree(ctx):
    tree = ctx.actions.declare_directory(ctx.label.name)
    ctx.actions.run_shell(
        outputs = [tree],
        arguments = [tree.path, ctx.attr.mode],
        command = """python - "$1" "$2" <<'PY'
import os
from pathlib import Path
import sys
root = Path(sys.argv[1])
(root / "nested").mkdir(parents=True)
(root / "nested/value").write_bytes(b"nested content\\n")
destination = {"valid": "nested/value", "broken": "missing", "cycle": "file.link"}[sys.argv[2]]
os.symlink(destination, root / "file.link")
os.symlink("nested", root / "directory.link", target_is_directory=True)
PY
""",
    )
    return [DefaultInfo(files = depset([tree]))]

linked_tree = rule(
    implementation = _linked_tree,
    attrs = {"mode": attr.string(default = "valid", values = ["valid", "broken", "cycle"])},
)
