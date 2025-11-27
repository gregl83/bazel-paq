load(":paq_aspect_graph_test.bzl", "graph_test")
load(":paq_aspect_hash_test.bzl", "hash_test")

genrule(
    name = "single_file",
    outs = ["single-file.json"],
    cmd = "echo '\"single-file-contents\"' > $@",
    testonly = True,
)

genrule(
    name = "directory",
    outs = [
        "directory/config.json",
        "directory/child_directory_alpha/alpha.json",
        "directory/child_directory_bravo/bravo.json",
    ],
    cmd = """
        mkdir -p $(RULEDIR)/directory/child_directory_alpha
        mkdir -p $(RULEDIR)/directory/child_directory_bravo
        echo '\"config-file-contents\"' > $(RULEDIR)/directory/config.json
        echo '\"alpha-file-contents\"' > $(RULEDIR)/directory/child_directory_alpha/alpha.json
        echo '\"bravo-file-contents\"' > $(RULEDIR)/directory/child_directory_bravo/bravo.json
    """,
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

# paq directory graph test case
graph_test(
    name = "test_directory",
    target_under_test = ":directory",
    expected = [
        "tests/directory/.paq"
    ],
)
# paq directory hash test
hash_test(
    name = "test_directory_hash",
    target_under_test = ":directory",
    expected = "\\\"625cf35b57cf55b0a35124f551f91adbc2d370f70ba268e6933a8bf9844af7e2\\\"",
)
