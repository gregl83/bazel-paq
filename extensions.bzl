load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# paq binary operating system and architecture map
PAQ_ARTIFACTS = {
    "linux_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.4.0/paq-ubuntu-x64.zip",
        "sha256": "19030c217b82a3a446411ed66c0eaf5c9ef353bc7583c965bcf56dd5bd3b7271",
        "binary": "paq",
    },
    "linux_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.4.0/paq-ubuntu-x86.zip",
        "sha256": "7be5787d30e97f64db3e5cd1d2d8aa1bc29958e42f4b73a5915340b2dfafd4b4",
        "binary": "paq",
    },
    "macos_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.4.0/paq-macOS-x64.zip",
        "sha256": "fd2e7a03ed939ae0a12f886902eeb81f668a0eee3dfd505f1b3b6e7a03451f64",
        "binary": "paq",
    },
    "macos_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.4.0/paq-macOS-x86.zip",
        "sha256": "fd2e7a03ed939ae0a12f886902eeb81f668a0eee3dfd505f1b3b6e7a03451f64",
        "binary": "paq",
    },
    "windows_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.4.0/paq-windows-x64.zip",
        "sha256": "838e9a9dc33d832a4cc9af13c748f72b95070666c96689e6e77906fb978cc45a",
        "binary": "paq.exe",
    },
    "windows_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.4.0/paq-windows-x86.zip",
        "sha256": "b0c8ee5bf9be780a7f3c5c16f461701774db7d10804ad844c391cf859c3e2e86",
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
    executable = True,
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
