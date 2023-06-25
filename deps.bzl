load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def bazel_paq_dependencies():
    http_archive(
        name = "paq",
        urls = [
            "https://github.com/gregl83/paq/releases/download/v1.0.0/paq-ubuntu-x86.zip"
        ],
        sha256 = "ba92a40c033f0dbf47d0f3be787bd61e9ad73022622a7c2f84492f6a0518a1af",
        build_file_content = """
genrule(
    name = "paq_chmod_x",
    srcs = ["paq"],
    outs = ["paq_executable"],
    cmd = "cp $(location paq) $@ && chmod +x $@",
)
filegroup(
    name = "binary",
    srcs = [":paq_executable"],
    visibility = ["//visibility:public"],
)
""",
    )