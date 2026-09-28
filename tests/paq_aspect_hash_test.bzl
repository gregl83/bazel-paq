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

def _hash_manifest_impl(ctx):
    artifacts = depset(transitive = [src[DefaultInfo].files for src in ctx.attr.srcs]).to_list()
    manifest = ctx.actions.declare_file(ctx.label.name + ".manifest")
    records = [str(len(ctx.attr.expected)), str(len(artifacts))]
    for path in sorted(ctx.attr.expected):
        records.extend([path, ctx.attr.expected[path]])
    records.extend([artifact.short_path for artifact in artifacts])
    # NUL-delimited data avoids Make expansion, shell quoting, and the Windows
    # shell launcher's extra command-line parsing of artifact names.
    ctx.actions.write(manifest, "\000".join(records) + "\000")
    return [DefaultInfo(
        files = depset([manifest]),
        runfiles = ctx.runfiles(files = artifacts),
    )]

_hash_manifest = rule(
    implementation = _hash_manifest_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "expected": attr.string_dict(),
    },
)

def artifact_hash_test(name, artifacts, expected):
    """Check artifact contents without passing their names through the launcher."""
    _hash_manifest(
        name = name + "_manifest",
        srcs = artifacts,
        expected = expected,
        testonly = True,
    )
    sh_test(
        name = name,
        srcs = ["//tests:assert_paq.sh"],
        data = [":" + name + "_manifest"],
        args = ["$(location :" + name + "_manifest)"],
    )

def hash_test(name, target_under_test, expected):
    """Compare every output hash by artifact path, including output count."""
    paq_applier(
        name = name + "_paq",
        deps = [target_under_test],
        testonly = True,
    )
    artifact_hash_test(name, [":" + name + "_paq"], expected)
