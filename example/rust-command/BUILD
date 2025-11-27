"Public API"

load("@rules_rust//rust:defs.bzl", "rust_binary")
load("@crates//:defs.bzl", "all_crate_deps")

rust_binary(
    name = "command",
    srcs = ["src/main.rs"],
    edition = "2021",
    deps = all_crate_deps(),
)