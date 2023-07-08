load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def bazel_paq_dependencies():
    http_archive(
        name = "paq",
        urls = [
            "https://github.com/gregl83/paq/releases/download/v1.0.1/paq-ubuntu-x86.zip"
        ],
        sha256 = "7e65423341267b6b3068a11e57a1b184e06cfa6497cb1cf13ca0efdd14270a61",
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