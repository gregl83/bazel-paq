load("@rules_shell//shell:sh_test.bzl", "sh_test")
load("//:defs.bzl", "paq_aspect")

def _paq_applier_impl(ctx):
    paq_files = []
    for dep in ctx.attr.deps:
        if OutputGroupInfo in dep and hasattr(dep[OutputGroupInfo], "paq_files"):
            paq_files.extend(dep[OutputGroupInfo].paq_files.to_list())
    return [DefaultInfo(files = depset(paq_files))]

paq_applier = rule(
    implementation = _paq_applier_impl,
    attrs = {
        "deps": attr.label_list(aspects = [paq_aspect]),
    },
)

def hash_test(name, target_under_test, expected):
    """Compare every output hash by artifact path, including output count."""
    paq_applier(
        name = name + "_paq",
        deps = [target_under_test],
        testonly = True,
    )
    sh_test(
        name = name,
        srcs = ["//tests:assert_paq.sh"],
        data = [":" + name + "_paq"],
        args = [path + "=" + expected[path] for path in sorted(expected)] + ["--", "$(locations :" + name + "_paq)"],
    )
