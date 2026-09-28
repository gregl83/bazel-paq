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
    for name, destination in [("link", ctx.attr.link_target), ("chain", "link"), ("tree.link", "tree.out")]:
        link = ctx.actions.declare_symlink(name)
        # The tree may not exist yet; Windows must not infer a file symlink.
        ctx.actions.symlink(
            output = link,
            target_path = destination,
            target_type = "directory" if name == "tree.link" else "file",
        )
        files.append(link)
    return [DefaultInfo(files = depset(files))]

outputs = rule(
    implementation = _outputs,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "tree_srcs": attr.label_list(allow_files = True),
        "link_target": attr.string(default = "first"),
    },
)

def _link(ctx):
    link = ctx.actions.declare_symlink(ctx.attr.out)
    ctx.actions.symlink(output = link, target_path = ctx.attr.destination)
    return [DefaultInfo(files = depset([link]))]

link_output = rule(
    implementation = _link,
    attrs = {
        "out": attr.string(),
        "destination": attr.string(),
        "srcs": attr.label_list(allow_files = True),
    },
)
