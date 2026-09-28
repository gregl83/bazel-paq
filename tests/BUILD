load(":paq_platform_test.bzl", "supported_platforms_test", "unsupported_platform_test")
load(":paq_aspect_graph_test.bzl", "graph_test")
load(":paq_aspect_hash_test.bzl", "artifact_hash_test", "hash_test")
load(":paq_test_targets.bzl", "dictionary_forward", "directory", "edge_outputs", "forward", "mixed_outputs", "named_files", "symlink")

genrule(
    name = "single_file",
    visibility = ["//tests/forwarded:__pkg__"],
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

# These outputs share a directory with files that must not enter either hash.
genrule(
    name = "shared_outputs",
    outs = [
        "shared/alpha.txt",
        "shared/nested/beta.txt",
        "shared/unrelated.txt",
    ],
    cmd = """
        mkdir -p $(RULEDIR)/shared/nested
        printf 'alpha\\n' > $(RULEDIR)/shared/alpha.txt
        printf 'beta\\n' > $(RULEDIR)/shared/nested/beta.txt
        printf 'unrelated\\n' > $(RULEDIR)/shared/unrelated.txt
    """,
    testonly = True,
)

filegroup(
    name = "selected_outputs",
    srcs = ["shared/alpha.txt", "shared/nested/beta.txt"],
    testonly = True,
)

filegroup(
    name = "selected_outputs_reversed",
    srcs = ["shared/nested/beta.txt", "shared/alpha.txt"],
    testonly = True,
)

mixed_outputs(
    name = "mixed_outputs",
    testonly = True,
)


edge_outputs(name = "edge_outputs", testonly = True)

symlink(
    name = "directory_symlink",
    out = "directory-link",
    target_path = "directory",
    target_type = "directory",
    srcs = [":directory"],
    testonly = True,
)

filegroup(name = "single_file_wrapper", srcs = [":single_file"], testonly = True)
filegroup(name = "source_file", srcs = ["fixtures/single-file.json"], testonly = True)
filegroup(name = "no_outputs", testonly = True)
forward(name = "custom_wrapper", artifacts = ":single_file", testonly = True)

# References computed independently with paq 2.0.0 --follow.

graph_test(
    name = "test_single_file",
    target_under_test = ":single_file",
    expected = ["tests/single-file.json.paq"],
)

hash_test(
    name = "test_single_file_hash",
    target_under_test = ":single_file",
    expected = {
        "tests/single-file.json.paq": "5bc94c0d67b5edf91b228a6efd7ef2743d00ab1cd7daea74c0a019f205eb281f",
    },
)

graph_test(
    name = "test_single_file_wrapper",
    target_under_test = ":single_file_wrapper",
    expected = ["tests/single-file.json.paq"],
)

hash_test(
    name = "test_single_file_wrapper_hash",
    target_under_test = ":single_file_wrapper",
    expected = {
        "tests/single-file.json.paq": "5bc94c0d67b5edf91b228a6efd7ef2743d00ab1cd7daea74c0a019f205eb281f",
    },
)

graph_test(
    name = "test_custom_wrapper",
    target_under_test = ":custom_wrapper",
    expected = ["tests/single-file.json.paq"],
)

hash_test(
    name = "test_custom_wrapper_hash",
    target_under_test = ":custom_wrapper",
    expected = {
        "tests/single-file.json.paq": "5bc94c0d67b5edf91b228a6efd7ef2743d00ab1cd7daea74c0a019f205eb281f",
    },
)

graph_test(
    name = "test_single_symlink",
    target_under_test = ":single_symlink",
    expected = ["tests/single-symlink.json.paq"],
)

hash_test(
    name = "test_single_symlink_hash",
    target_under_test = ":single_symlink",
    expected = {
        "tests/single-symlink.json.paq": "5bc94c0d67b5edf91b228a6efd7ef2743d00ab1cd7daea74c0a019f205eb281f",
    },
)

graph_test(
    name = "test_directory",
    target_under_test = ":directory",
    expected = ["tests/directory.paq"],
)

hash_test(
    name = "test_directory_hash",
    target_under_test = ":directory",
    expected = {
        "tests/directory.paq": "e3a126c863b0191feefd5157581a475daf3f521537f6f0e92c453c679d6cd22e",
    },
)

graph_test(
    name = "test_directory_symlink",
    target_under_test = ":directory_symlink",
    expected = ["tests/directory.paq", "tests/directory-link.paq"],
)

hash_test(
    name = "test_directory_symlink_hash",
    target_under_test = ":directory_symlink",
    expected = {
        "tests/directory.paq": "e3a126c863b0191feefd5157581a475daf3f521537f6f0e92c453c679d6cd22e",
        "tests/directory-link.paq": "e3a126c863b0191feefd5157581a475daf3f521537f6f0e92c453c679d6cd22e",
    },
)

graph_test(
    name = "test_multiple_files",
    target_under_test = ":multiple_files",
    expected = ["tests/multiple-files/config.json.paq", "tests/multiple-files/child_directory_alpha/alpha.json.paq", "tests/multiple-files/child_directory_bravo/bravo.json.paq", "tests/multiple-files/config-link.json.paq"],
)

hash_test(
    name = "test_multiple_files_hash",
    target_under_test = ":multiple_files",
    expected = {
        "tests/multiple-files/config.json.paq": "ad7cfccde551ac8a9edf8a9c064cda79b4cec4ec85d8cd125d442b7a8575e884",
        "tests/multiple-files/child_directory_alpha/alpha.json.paq": "14ff61ee3168f0b1ba1d9953c5caf8470a807d4639080da915b927107a7a25e1",
        "tests/multiple-files/child_directory_bravo/bravo.json.paq": "328f78a954b9f4297b88d03846669c943ae070e28f2c9d1a81437e704e3d3d21",
        "tests/multiple-files/config-link.json.paq": "ad7cfccde551ac8a9edf8a9c064cda79b4cec4ec85d8cd125d442b7a8575e884",
    },
)

graph_test(
    name = "test_selected_outputs",
    target_under_test = ":selected_outputs",
    expected = ["tests/shared/alpha.txt.paq", "tests/shared/nested/beta.txt.paq"],
)

hash_test(
    name = "test_selected_outputs_hash",
    target_under_test = ":selected_outputs",
    expected = {
        "tests/shared/alpha.txt.paq": "ebf8fd661bef31689e3cc559e5119b134a2e9f12e893b5cb61b005f83dfe01b1",
        "tests/shared/nested/beta.txt.paq": "58c66d883e45d649e99f6311f0e3d859358480b8417357f10a28d7e9ad140625",
    },
)

graph_test(
    name = "test_selected_outputs_reversed",
    target_under_test = ":selected_outputs_reversed",
    expected = ["tests/shared/alpha.txt.paq", "tests/shared/nested/beta.txt.paq"],
)

hash_test(
    name = "test_selected_outputs_reversed_hash",
    target_under_test = ":selected_outputs_reversed",
    expected = {
        "tests/shared/alpha.txt.paq": "ebf8fd661bef31689e3cc559e5119b134a2e9f12e893b5cb61b005f83dfe01b1",
        "tests/shared/nested/beta.txt.paq": "58c66d883e45d649e99f6311f0e3d859358480b8417357f10a28d7e9ad140625",
    },
)

graph_test(
    name = "test_mixed_outputs",
    target_under_test = ":mixed_outputs",
    expected = ["tests/mixed_outputs/alpha.txt.paq", "tests/mixed_outputs/nested.paq"],
)

hash_test(
    name = "test_mixed_outputs_hash",
    target_under_test = ":mixed_outputs",
    expected = {
        "tests/mixed_outputs/alpha.txt.paq": "ebf8fd661bef31689e3cc559e5119b134a2e9f12e893b5cb61b005f83dfe01b1",
        "tests/mixed_outputs/nested.paq": "f8389e077d1afbcac87b5b6c4c73a77b695bff3348515bbc57cf48d1f6b4aa98",
    },
)

graph_test(
    name = "test_edge_outputs",
    target_under_test = ":edge_outputs",
    expected = ["tests/edge_outputs/empty.paq", "tests/edge_outputs/executable.paq", "tests/edge_outputs/empty_directory.paq", "tests/edge_outputs/tree.paq"],
)

hash_test(
    name = "test_edge_outputs_hash",
    target_under_test = ":edge_outputs",
    expected = {
        "tests/edge_outputs/empty.paq": "cb0f2cb5ed6579912b1825a5b85e39c457d19b633190f7c85ea2df9637f986d0",
        "tests/edge_outputs/executable.paq": "6c6c3479ab3b810d2adbe2e8131e1702abb497814775f3204600275efc28a899",
        "tests/edge_outputs/empty_directory.paq": "7887758062e01b93b78eedf93fcfa49c3d0952ee3a278ace176e3dab4d50084e",
        "tests/edge_outputs/tree.paq": "f5aa156e414a26e9b623d2f2e665880e1561d9bb4fc077761a75c25460c8fbee",
    },
)

graph_test(
    name = "test_source_file",
    target_under_test = ":source_file",
    expected = [],
)

graph_test(
    name = "test_source_symlink",
    target_under_test = ":source_symlink",
    expected = [],
)

graph_test(
    name = "test_no_outputs",
    target_under_test = ":no_outputs",
    expected = [],
)

exports_files(["assert_paq.sh"], visibility = ["//tests/forwarded:__pkg__"])

supported_platforms_test(name = "test_supported_platforms")

unsupported_platform_test(
    name = "test_unknown_os",
    os_name = "freebsd",
    arch = "amd64",
    message = "unsupported operating system: freebsd",
)
unsupported_platform_test(
    name = "test_unknown_arch",
    os_name = "linux",
    arch = "riscv64",
    message = "unsupported architecture: riscv64",
)
unsupported_platform_test(
    name = "test_unpublished_macos_x86",
    os_name = "mac os x",
    arch = "i686",
    message = "no paq binary found for platform: macos_x86",
)
[
    unsupported_platform_test(
        name = "test_unpublished_" + os_name + "_" + arch,
        os_name = os_name,
        arch = arch,
        message = "no paq binary found for platform: " + os_name + "_arm64",
    )
    for os_name in ["linux", "windows"]
    for arch in ["arm64", "aarch64"]
]

# Building the fixture's public target catches missing executable references.
artifact_hash_test(
    name = "test_windows_executable_layout",
    artifacts = ["@paq_windows_fixture//:binary"],
    expected = {"paq_executable.exe": "fixture"},
)
artifact_hash_test(
    name = "test_unix_executable_layout",
    artifacts = ["@paq_unix_fixture//:binary"],
    expected = {"paq_executable": "fixture"},
)

alias(name = "single_file_alias", actual = ":single_file")
filegroup(name = "nested_wrapper", srcs = [":single_file_wrapper"], testonly = True)
filegroup(
    name = "diamond_wrapper",
    srcs = [":nested_wrapper", ":custom_wrapper", ":single_file_alias"],
    testonly = True,
)
dictionary_forward(
    name = "dictionary_keys",
    by_label = {":single_file": "file"},
    testonly = True,
)
dictionary_forward(
    name = "dictionary_values",
    by_name = {"file": ":single_file"},
    testonly = True,
)
filegroup(
    name = "mixed_sources",
    srcs = [":single_file", "fixtures/single-file.json", "fixtures/single-symlink.json"],
    testonly = True,
)

graph_test(
    name = "test_single_file_alias",
    target_under_test = ":single_file_alias",
    expected = ["tests/single-file.json.paq"],
)
hash_test(
    name = "test_single_file_alias_hash",
    target_under_test = ":single_file_alias",
    expected = {"tests/single-file.json.paq": "5bc94c0d67b5edf91b228a6efd7ef2743d00ab1cd7daea74c0a019f205eb281f"},
)

graph_test(
    name = "test_nested_wrapper",
    target_under_test = ":nested_wrapper",
    expected = ["tests/single-file.json.paq"],
)
hash_test(
    name = "test_nested_wrapper_hash",
    target_under_test = ":nested_wrapper",
    expected = {"tests/single-file.json.paq": "5bc94c0d67b5edf91b228a6efd7ef2743d00ab1cd7daea74c0a019f205eb281f"},
)

graph_test(
    name = "test_diamond_wrapper",
    target_under_test = ":diamond_wrapper",
    expected = ["tests/single-file.json.paq"],
)
hash_test(
    name = "test_diamond_wrapper_hash",
    target_under_test = ":diamond_wrapper",
    expected = {"tests/single-file.json.paq": "5bc94c0d67b5edf91b228a6efd7ef2743d00ab1cd7daea74c0a019f205eb281f"},
)

graph_test(
    name = "test_dictionary_keys",
    target_under_test = ":dictionary_keys",
    expected = ["tests/single-file.json.paq"],
)
hash_test(
    name = "test_dictionary_keys_hash",
    target_under_test = ":dictionary_keys",
    expected = {"tests/single-file.json.paq": "5bc94c0d67b5edf91b228a6efd7ef2743d00ab1cd7daea74c0a019f205eb281f"},
)

graph_test(
    name = "test_dictionary_values",
    target_under_test = ":dictionary_values",
    expected = ["tests/single-file.json.paq"],
)
hash_test(
    name = "test_dictionary_values_hash",
    target_under_test = ":dictionary_values",
    expected = {"tests/single-file.json.paq": "5bc94c0d67b5edf91b228a6efd7ef2743d00ab1cd7daea74c0a019f205eb281f"},
)

graph_test(
    name = "test_mixed_sources",
    target_under_test = ":mixed_sources",
    expected = ["tests/single-file.json.paq"],
)
hash_test(
    name = "test_mixed_sources_hash",
    target_under_test = ":mixed_sources",
    expected = {"tests/single-file.json.paq": "5bc94c0d67b5edf91b228a6efd7ef2743d00ab1cd7daea74c0a019f205eb281f"},
)

named_files(
    name = "unusual_paths",
    names = ["space name", "café", "semi;colon", "quote'name", "dollar$sign", "equals=name"],
    testonly = True,
)

graph_test(
    name = "test_unusual_paths",
    target_under_test = ":unusual_paths",
    expected = [
        "tests/unusual_paths/space name.paq",
        "tests/unusual_paths/café.paq",
        "tests/unusual_paths/semi;colon.paq",
        "tests/unusual_paths/quote'name.paq",
        "tests/unusual_paths/dollar$sign.paq",
        "tests/unusual_paths/equals=name.paq",
    ],
)

hash_test(
    name = "test_unusual_paths_hash",
    target_under_test = ":unusual_paths",
    expected = {
        "tests/unusual_paths/" + name + ".paq": "ebf8fd661bef31689e3cc559e5119b134a2e9f12e893b5cb61b005f83dfe01b1"
        for name in ["space name", "café", "semi;colon", "quote'name", "dollar$sign", "equals=name"]
    },
)
