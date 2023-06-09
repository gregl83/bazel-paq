"Public API"

load("//:defs.bzl", "paq")

filegroup(
    name = "input_file",
    srcs = ["input.json"],
)

paq(
    name = "example_file",
    source = ":input_file",
)