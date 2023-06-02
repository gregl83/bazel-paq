workspace(name = "bazel-paq")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "rules_rust",
    sha256 = "aaaa4b9591a5dad8d8907ae2dbe6e0eb49e6314946ce4c7149241648e56a1277",
    urls = ["https://github.com/bazelbuild/rules_rust/releases/download/0.16.1/rules_rust-v0.16.1.tar.gz"],
)

load("@rules_rust//rust:repositories.bzl", "rules_rust_dependencies", "rust_register_toolchains")

rules_rust_dependencies()

rust_register_toolchains()

http_archive(
    name = "paq",
    sha256 = "204b301333d3de7555ea5659f40bc8d282a1f25e2e4ad21bfff170612c82b406",
    urls = ["https://github.com/gregl83/paq/archive/refs/tags/v1.0.0.tar.gz"],
)