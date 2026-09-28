"""Published platform selection and intentional unsupported-platform errors."""
load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts", "unittest")
load("//:extensions.bzl", "PAQ_ARTIFACTS", "paq_platform_key")

def _supported_impl(ctx):
    env = unittest.begin(ctx)
    for os_name, prefix in [("Linux", "linux"), ("Windows", "windows"), ("Mac OS X", "macos")]:
        for arch in ["x86_64", "amd64", "AMD64"]:
            key = paq_platform_key(os_name, arch)
            asserts.equals(env, prefix + "_x64", key)
            asserts.equals(env, "paq.exe" if prefix == "windows" else "paq", PAQ_ARTIFACTS[key]["binary"])
    for os_name in ["linux", "windows"]:
        for arch in ["x86", "i386", "i686"]:
            asserts.equals(env, os_name + "_x86", paq_platform_key(os_name, arch))
    for arch in ["aarch64", "arm64"]:
        asserts.equals(env, "macos_arm64", paq_platform_key("mac os x", arch))
    return unittest.end(env)

supported_platforms_test = unittest.make(_supported_impl)

def _probe_impl(ctx):
    paq_platform_key(ctx.attr.os_name, ctx.attr.arch)
    return []

_platform_probe = rule(
    implementation = _probe_impl,
    attrs = {"os_name": attr.string(), "arch": attr.string()},
)

def _unsupported_impl(ctx):
    env = analysistest.begin(ctx)
    asserts.expect_failure(env, ctx.attr.message)
    return analysistest.end(env)

_unsupported_test = analysistest.make(
    _unsupported_impl,
    expect_failure = True,
    attrs = {"message": attr.string()},
)

def unsupported_platform_test(name, os_name, arch, message):
    _platform_probe(name = name + "_probe", os_name = os_name, arch = arch, tags = ["manual"])
    _unsupported_test(name = name, target_under_test = ":" + name + "_probe", message = message)
