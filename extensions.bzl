load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# paq binary operating system and architecture map
PAQ_ARTIFACTS = {
    "linux_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.3/paq-ubuntu-x64.zip",
        "sha256": "a99739e918611def507a78f2ac8d615a41a54b20372e949bc1c0fd1ad8128347",
        "binary": "paq",
    },
    "linux_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.3/paq-ubuntu-x86.zip",
        "sha256": "1c076d41b132edb0254673de4d0e661016a7d176db60d396de2e4b529e99bd78",
        "binary": "paq",
    },
    "macos_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.3/paq-macOS-x64.zip",
        "sha256": "2a19987b1527f60a66f108e9f3bdef93680f23e7b0647e35e56588a42fff3d3b",
        "binary": "paq",
    },
    "macos_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.3/paq-macOS-x86.zip",
        "sha256": "26f0af0fa5f2c73ea93a3ba86aab3f4685ec3e3ee83e43e9d94a2f197d151da2",
        "binary": "paq",
    },
    "windows_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.3/paq-windows-x64.zip",
        "sha256": "1fc39ab17ea06e30d7812afba88e4d5f86898e6510a5748648f2b48eec265cf1",
        "binary": "paq.exe",
    },
    "windows_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.3/paq-windows-x86.zip",
        "sha256": "a87bb7128d8d47cd3290e932a40cabd2133ae33228ece094ac41c214033cc3ec",
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
