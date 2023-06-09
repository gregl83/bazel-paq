"Public API"

load("//:defs.bzl", "paq")

filegroup(
    name = "input_dir",
    srcs = glob(["src/**/*"]),
)

paq(
    name = "example_directory",
    source = ":input_dir",
)