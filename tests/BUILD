load(":paq_aspect_graph_test.bzl", "graph_test")
load(":paq_aspect_hash_test.bzl", "hash_test")

genrule(
    name = "single_file",
    outs = ["single-file.json"],
    cmd = "echo '\"single-file-contents\"' > $@",
    testonly = True,
)

# paq single file graph test case
graph_test(
    name = "test_single_file",
    target_under_test = ":single_file",
    expected = [
        "tests/single-file.json.paq"
    ],
)
# paq single file hash test
hash_test(
    name = "test_single_file_hash",
    target_under_test = ":single_file",
    expected = "\\\"3f46fbc8859fe1c9bffb682ddaf95876ee0ef3fca61c5c10d03e2ab640718470\\\"",
)
