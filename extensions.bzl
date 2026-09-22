load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# paq binary operating system and architecture map
PAQ_ARTIFACTS = {
    "linux_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.5.0/paq-ubuntu-x64.zip",
        "sha256": "b9cf1796e4a35c5e32a70f9b0940226aba039a910a89ed7fd538ae1f47efa8bf",
        "binary": "paq",
    },
    "linux_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.5.0/paq-ubuntu-x86.zip",
        "sha256": "6b7762f5b2fed1aaa3c2c30f4aa43d4cc05dd0198481b8752bb1ccd10c442b39",
        "binary": "paq",
    },
    "macos_arm64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.5.0/paq-macos-arm64.zip",
        "sha256": "236dc3d01f873037533f56df6f8abc83d3c2318a0450184d10435148ed310fc0",
        "binary": "paq",
    },
    "macos_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.5.0/paq-macos-x64.zip",
        "sha256": "c407d222dd9ef74ac0623cb08f845a77bf5eb8c618b642fec01c8f417148b8a7",
        "binary": "paq",
    },
    "windows_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.5.0/paq-windows-x64.zip",
        "sha256": "1313a6fdf384a5f94e04638892a1d1310018497e8c6cbfb7fcf007159572f1fd",
        "binary": "paq.exe",
    },
    "windows_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v1.5.0/paq-windows-x86.zip",
        "sha256": "8b0b91e285c46747b8a937e3f6ed1a9cf6d2f27e2b7f1cac72f59ce9724bc9f0",
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
