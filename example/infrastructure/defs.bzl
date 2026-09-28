"""Prepare a small infrastructure deployment with several output types."""

def _deployment_impl(ctx):
    templates = ctx.actions.declare_directory("templates.out")
    pending = ctx.actions.declare_directory("pending")
    log = ctx.actions.declare_file("deployment.log")
    link = ctx.actions.declare_symlink("templates.link")

    arguments = [templates.path, pending.path]
    for src in ctx.files.srcs:
        arguments.extend([src.path, src.basename])
    ctx.actions.run_shell(
        inputs = ctx.files.srcs,
        outputs = [templates, pending],
        arguments = arguments,
        command = """
            set -eu
            templates="$1"
            mkdir -p "$templates" "$2"
            shift 2
            while [ "$#" -gt 0 ]; do
                cp "$1" "$templates/$2"
                shift 2
            done
        """,
    )
    ctx.actions.write(log, "")
    # Windows needs the directory type even before templates has been built.
    ctx.actions.symlink(output = link, target_path = templates.basename, target_type = "directory")
    return [DefaultInfo(files = depset([templates, pending, log, link]))]

deployment = rule(
    implementation = _deployment_impl,
    attrs = {"srcs": attr.label_list(allow_files = [".yaml"])},
)
