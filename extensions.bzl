load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# paq binary operating system and architecture map
PAQ_ARTIFACTS = {
    "linux_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.2/paq-ubuntu-x64.zip",
        "sha256": "8ec6ef57e6ff04b0f8ba4a85711835584d61f764ff45daa26387a8bf728c455a",
        "binary": "paq",
    },
    "linux_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.2/paq-ubuntu-x86.zip",
        "sha256": "d158f5be42537a94db4acd628fe491bb2d39730b8213778820f24d2147584f4f",
        "binary": "paq",
    },
    "macos_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.2/paq-macOS-x64.zip",
        "sha256": "ddbc46d7e6dd17a18cc78f650a267ba678408cfb558f9d3ca935c6de70d5c393",
        "binary": "paq",
    },
    "macos_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.2/paq-macOS-x86.zip",
        "sha256": "c890b00a7c20682bdc5a1a460369c4af5458b56bec967c380e3298e2c2c813ad",
        "binary": "paq",
    },
    "windows_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.2/paq-windows-x64.zip",
        "sha256": "f56be7b0f614d36042f7f105d400f90c3f57832bb9aa818493d31c7a21e8c6f1",
        "binary": "paq.exe",
    },
    "windows_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.3.2/paq-windows-x86.zip",
        "sha256": "1e661b3153245c77f70434b41aeb0134a352c2dd2e941a2b4a971ce83a951849",
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
