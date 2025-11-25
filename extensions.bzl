load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# paq binary operating system and architecture map
PAQ_ARTIFACTS = {
    "linux_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.0/paq-ubuntu-x64.zip",
        "sha256": "4ef23a686e5ef1f092157fa43b7a47b654e1858f529f9d4701fc007d511d1899",
        "binary": "paq",
    },
    "linux_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.0/paq-ubuntu-x86.zip",
        "sha256": "d3c7295410d9dd6f9368c5f98e6f19dd261f4030ab931b3b0c797927f7ef5c3b",
        "binary": "paq",
    },
    "macos_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.0/paq-macOS-x64.zip",
        "sha256": "c7c7ecdeabf8d59644bb7ad7c6dda3eee0bb8d66607936e33741ae8b993c46d3",
        "binary": "paq",
    },
    "macos_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.0/paq-macOS-x86.zip",
        "sha256": "c7c7ecdeabf8d59644bb7ad7c6dda3eee0bb8d66607936e33741ae8b993c46d3",
        "binary": "paq",
    },
    "windows_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.0/paq-windows-x64.zip",
        "sha256": "fb5ffe98f28b63c3571bc891ecc9e6c189f30610bb46763b9031fba94ac808f3",
        "binary": "paq.exe",
    },
    "windows_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.0/paq-windows-x86.zip",
        "sha256": "903a22046603198625c89180a9e59184478c71efd0e4ed5e7c56a5cf2f38ae1f",
        "binary": "paq.exe",
    },
}

def _paq_extension_impl(ctx):
    # detect operating system
    os_name = ctx.os.name.lower()
    if os_name.startswith("windows"):
        os_key = "windows"
    elif os_name.startswith("mac"):
        os_key = "macos"
    elif os_name.startswith("linux"):
        os_key = "linux"
    else:
        fail("unsupported operating system: " + os_name)

    # detect architecture and map to x64/x86
    raw_arch = ctx.os.arch.lower()
    if raw_arch in ["x86_64", "amd64"]:
        arch_key = "x64"
    elif raw_arch in ["aarch64", "arm64"]:
        arch_key = "x64"
    elif raw_arch in ["x86", "i386", "i686"]:
        arch_key = "x86"
    else:
        fail("unsupported architecture: " + raw_arch)

    # get paq artifact from binary map
    platform_key = "{}_{}".format(os_key, arch_key)
    if platform_key not in PAQ_ARTIFACTS:
        fail("no paq binary found for platform: " + platform_key)
    artifact = PAQ_ARTIFACTS[platform_key]

    # download and expose paq binary
    http_archive(
        name = "paq",
        urls = [artifact["url"]],
        sha256 = artifact["sha256"],
        build_file_content = """
genrule(
    name = "paq_chmod_x",
    srcs = ["{binary_filename}"],
    outs = ["paq_executable"],
    cmd = "cp $< $@ && chmod +x $@",
)

filegroup(
    name = "binary",
    srcs = [":paq_executable"],
    visibility = ["//visibility:public"],
)
""".format(binary_filename = artifact["binary"]),
    )

paq_extension = module_extension(
    implementation = _paq_extension_impl,
)
