"""Configuration output helpers."""

def _config_link_impl(ctx):
    output = ctx.actions.declare_file(ctx.attr.out)
    ctx.actions.symlink(output = output, target_file = ctx.file.src)
    return [DefaultInfo(files = depset([output]))]

config_link = rule(
    implementation = _config_link_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
        "out": attr.string(mandatory = True),
    },
)
