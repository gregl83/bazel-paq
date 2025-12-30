load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# paq binary operating system and architecture map
PAQ_ARTIFACTS = {
    "linux_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.4.1/paq-ubuntu-x64.zip",
        "sha256": "7f821196ee70566337a8a0aaca7ded3744f4107998accf2c13214f751214cb47",
        "binary": "paq",
    },
    "linux_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.4.1/paq-ubuntu-x86.zip",
        "sha256": "30aef3732e06013b2112f7d90c089d4650776cfaad105a468a4c2642db4aa59a",
        "binary": "paq",
    },
    "macos_arm64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.4.1/paq-macos-arm64.zip",
        "sha256": "91bd0ae90abe05745de7288e560fbb6fe5ccec8a3a6c8bb99bbac192868ef776",
        "binary": "paq",
    },
    "macos_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.4.1/paq-macos-x64.zip",
        "sha256": "b75e392d5872cf14320cbd7f2d4eb616a191373480bcdd91a08bd15ab675ea2a",
        "binary": "paq",
    },
    "windows_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.4.1/paq-windows-x64.zip",
        "sha256": "4afd0b3b0039c4b819c2bfcd1489f515c323bc2931cbb02ec59ccbe41d498171",
        "binary": "paq.exe",
    },
    "windows_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.4.1/paq-windows-x86.zip",
        "sha256": "0b84aaded70c78c4dc930ba7a88d3acf4966385cba33c5774d00c9d483ef1209",
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
        if os_key == "macos":
            arch_key = "arm64"
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
