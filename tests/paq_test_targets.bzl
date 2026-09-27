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
