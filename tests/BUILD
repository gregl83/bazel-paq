load(":paq_aspect_graph_test.bzl", "graph_test")
load(":paq_aspect_hash_test.bzl", "hash_test")
load(":paq_test_targets.bzl", "directory", "symlink")

genrule(
    name = "single_file",
    outs = ["single-file.json"],
    cmd = "echo '\"single-file-contents\"' > $@",
    testonly = True,
)

directory(
    name = "directory",
    testonly = True,
)

filegroup(
    name = "source_symlink",
    srcs = ["fixtures/single-symlink.json"],
    testonly = True,
)

genrule(
    name = "single_symlink",
    srcs = [":single_file"],
    outs = ["single-symlink.json"],
    cmd = "ln -s single-file.json $@",
    testonly = True,
)

genrule(
    name = "multiple_files_contents",
    outs = [
        "multiple-files/config.json",
        "multiple-files/child_directory_alpha/alpha.json",
        "multiple-files/child_directory_bravo/bravo.json",
    ],
    cmd = """
        mkdir -p $(RULEDIR)/multiple-files/child_directory_alpha
        mkdir -p $(RULEDIR)/multiple-files/child_directory_bravo
        echo '\"config-file-contents\"' > $(RULEDIR)/multiple-files/config.json
        echo '\"alpha-file-contents\"' > $(RULEDIR)/multiple-files/child_directory_alpha/alpha.json
        echo '\"bravo-file-contents\"' > $(RULEDIR)/multiple-files/child_directory_bravo/bravo.json
    """,
    testonly = True,
)

symlink(
    name = "multiple_files",
    out = "multiple-files/config-link.json",
    target_path = "config.json",
    srcs = [":multiple_files_contents"],
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
        "tests/directory.paq"
    ],
)
# paq directory hash test
hash_test(
    name = "test_directory_hash",
    target_under_test = ":directory",
    expected = "\\\"ef23d096a9ceaaeff9ec4be5b07f0f9cca20b79437fab24f559397ea4bca1ce8\\\"",
)

# paq multiple files graph test case
graph_test(
    name = "test_multiple_files",
    target_under_test = ":multiple_files",
    expected = [
        "tests/multiple-files/.paq"
    ],
)
# paq multiple files hash test
hash_test(
    name = "test_multiple_files_hash",
    target_under_test = ":multiple_files",
    expected = "\\\"74a48192bf9baaef2449b1ef1dc8354c276a75f85681360bc2209d8233c0bd82\\\"",
)

# paq source symlink graph test case (source files are skipped)
graph_test(
    name = "test_source_symlink",
    target_under_test = ":source_symlink",
    expected = [],
)

# paq single symlink graph test case
graph_test(
    name = "test_single_symlink",
    target_under_test = ":single_symlink",
    expected = [
        "tests/single-symlink.json.paq"
    ],
)
# paq single symlink hash test
hash_test(
    name = "test_single_symlink_hash",
    target_under_test = ":single_symlink",
    expected = "\\\"2d06ee3fe6d3d4628d4449e962f0c43dcba46bcc9ab90a0c671a465a4026d7a7\\\"",
)
