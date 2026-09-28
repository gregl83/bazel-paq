def _directory_impl(ctx):
    output = ctx.actions.declare_directory(ctx.label.name)

    # create one directory artifact containing nested files
    ctx.actions.run_shell(
        outputs = [output],
        arguments = [output.path],
        command = """
            mkdir -p "$1/child_directory_alpha"
            mkdir -p "$1/child_directory_bravo"
            echo '\"config-file-contents\"' > "$1/config.json"
            echo '\"alpha-file-contents\"' > "$1/child_directory_alpha/alpha.json"
            echo '\"bravo-file-contents\"' > "$1/child_directory_bravo/bravo.json"
        """,
    )

    return [DefaultInfo(files = depset([output]))]

directory = rule(
    implementation = _directory_impl,
)

def _symlink_impl(ctx):
    output = ctx.actions.declare_symlink(ctx.attr.out)

    # preserve the relative link destination as an explicit symlink artifact
    ctx.actions.symlink(
        output = output,
        target_path = ctx.attr.target_path,
    )

    files = []
    for src in ctx.attr.srcs:
        files.extend(src[DefaultInfo].files.to_list())
    files.append(output)
    return [DefaultInfo(files = depset(files))]

symlink = rule(
    implementation = _symlink_impl,
    attrs = {
        "out": attr.string(mandatory = True),
        "target_path": attr.string(mandatory = True),
        "srcs": attr.label_list(),
    },
)

def _mixed_outputs_impl(ctx):
    tree = ctx.actions.declare_directory(ctx.label.name + "/nested")
    file = ctx.actions.declare_file(ctx.label.name + "/alpha.txt")
    ctx.actions.run_shell(
        outputs = [tree, file],
        arguments = [tree.path, file.path],
        command = """
            mkdir -p "$1"
            printf 'beta\\n' > "$1/beta.txt"
            printf 'alpha\\n' > "$2"
        """,
    )
    return [DefaultInfo(files = depset([tree, file]))]

mixed_outputs = rule(
    implementation = _mixed_outputs_impl,
)

def _edge_outputs_impl(ctx):
    empty_file = ctx.actions.declare_file(ctx.label.name + "/empty")
    executable = ctx.actions.declare_file(ctx.label.name + "/executable")
    empty_directory = ctx.actions.declare_directory(ctx.label.name + "/empty_directory")
    directory = ctx.actions.declare_directory(ctx.label.name + "/tree")
    ctx.actions.write(empty_file, "")
    ctx.actions.write(executable, "#!/bin/sh\necho hello\n", is_executable = True)
    ctx.actions.run_shell(
        outputs = [empty_directory, directory],
        arguments = [empty_directory.path, directory.path],
        command = """
            mkdir -p "$1" "$2/nested"
            printf 'visible\\n' > "$2/nested/file"
            printf 'hidden\\n' > "$2/.hidden"
        """,
    )
    return [DefaultInfo(files = depset([empty_file, executable, empty_directory, directory]))]

edge_outputs = rule(implementation = _edge_outputs_impl)

def _forward_impl(ctx):
    return [DefaultInfo(files = ctx.attr.artifacts[DefaultInfo].files)]

forward = rule(
    implementation = _forward_impl,
    attrs = {"artifacts": attr.label(mandatory = True)},
)
