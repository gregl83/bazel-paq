load("//tests:paq_aspect_graph_test.bzl", "graph_test")
load("//tests:paq_aspect_hash_test.bzl", "hash_test")

filegroup(
    name = "cross_package",
    srcs = ["//tests:single_file"],
    testonly = True,
)

graph_test(
    name = "test_cross_package",
    target_under_test = ":cross_package",
    expected = ["tests/single-file.json.paq"],
)

hash_test(
    name = "test_cross_package_hash",
    target_under_test = ":cross_package",
    expected = {"tests/single-file.json.paq": "5bc94c0d67b5edf91b228a6efd7ef2743d00ab1cd7daea74c0a019f205eb281f"},
)
