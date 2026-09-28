"Public API"

load("@bazel_skylib//rules:copy_file.bzl", "copy_file")
load(":defs.bzl", "config_link")

copy_file(
    name = "config",
    src = "config.json",
    out = "config.out.json",
)

config_link(
    name = "config_link",
    src = ":config",
    out = "config.link.json",
)
