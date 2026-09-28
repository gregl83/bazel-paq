"""Build both executable layouts on every host without running foreign binaries."""
load("//:extensions.bzl", "paq_build_file")

def _layout_impl(ctx):
    ctx.file(ctx.attr.binary, '"fixture"', executable = True)
    ctx.file("BUILD.bazel", paq_build_file(ctx.attr.binary))

paq_layout_repository = repository_rule(
    implementation = _layout_impl,
    attrs = {"binary": attr.string(mandatory = True)},
)
