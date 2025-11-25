load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# paq binary operating system and architecture map
PAQ_ARTIFACTS = {
    "linux_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.1/paq-ubuntu-x64.zip",
        "sha256": "df5b9ad53948cf751674367aa8c94acd8d0ff867c9b4ad657feac99dcb5946e6",
        "binary": "paq",
    },
    "linux_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.1/paq-ubuntu-x86.zip",
        "sha256": "0b69f683ef2243747f208beaa88376fa7d0f39586da1abd8a5a3ced13a47b261",
        "binary": "paq",
    },
    "macos_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.1/paq-macOS-x64.zip",
        "sha256": "ec91b218367f0fa7369e3f5e3b8c0b1020b1754aeec0dd559771c397ba6ff3c5",
        "binary": "paq",
    },
    "macos_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.1/paq-macOS-x86.zip",
        "sha256": "ce5d1fd4b6cf0a50830190f8d9a4c671904b90fd3f180f6aed5703d70a7e44d8",
        "binary": "paq",
    },
    "windows_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.1/paq-windows-x64.zip",
        "sha256": "111be9a40197f8e6b561c49a5b25d7e59b15fef2b7caeafbd542c27eefb4ba2b",
        "binary": "paq.exe",
    },
    "windows_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.1/paq-windows-x86.zip",
        "sha256": "acf9c0e19fce7445a3da6aee77d85d34a1b3f5d628bf41c42f39fba2cde2da18",
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
