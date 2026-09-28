"Public API"

load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load(":defs.bzl", "deployment")

pkg_tar(
    name = "templates",
    srcs = glob(["templates/**/*"]),
    strip_prefix = "templates",
)

deployment(
    name = "deployment",
    srcs = glob(["templates/*.yaml"]),
)
