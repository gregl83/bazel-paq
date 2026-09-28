load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# paq binary operating system and architecture map
PAQ_ARTIFACTS = {
    "linux_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v2.0.0/paq-ubuntu-x64.zip",
        "sha256": "2b8e16f4fba98e449366b42c5012024bcfa743695b49045cb7d91331fbef70b7",
        "binary": "paq",
    },
    "linux_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v2.0.0/paq-ubuntu-x86.zip",
        "sha256": "ccda5bab7e13851f0e87112e3e6afd3058c25d63ae869952b3fae3a3c91553ff",
        "binary": "paq",
    },
    "macos_arm64": {
        "url": "https://github.com/gregl83/paq/releases/download/v2.0.0/paq-macos-arm64.zip",
        "sha256": "167904e40820a2947f105e74ec062687ec7c6f11f9772640d484634db51bb6ad",
        "binary": "paq",
    },
    "macos_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v2.0.0/paq-macos-x64.zip",
        "sha256": "70415692a8dde8ba2e1eef570e73e5fb2e5d0693533651ca6d96d6ac9337c1a1",
        "binary": "paq",
    },
    "windows_x64": {
        "url": "https://github.com/gregl83/paq/releases/download/v2.0.0/paq-windows-x64.zip",
        "sha256": "efef07a4cf1db10a46823c757404aebfa9a33eb7f175c8d37681ff906fb65fc8",
        "binary": "paq.exe",
    },
    "windows_x86": {
        "url": "https://github.com/gregl83/paq/releases/download/v2.0.0/paq-windows-x86.zip",
        "sha256": "b6744c0bf6e0fb6a947d4fc77daec88229f769f5a4f58401c9afe4ea5fcc227e",
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
    outs = ["{executable_filename}"],
    cmd = "cp $< $@ && chmod +x $@",
    executable = True,
)

filegroup(
    name = "binary",
    srcs = [":paq_chmod_x"],
    visibility = ["//visibility:public"],
)
""".format(
            binary_filename = artifact["binary"],
            executable_filename = "paq_executable.exe" if artifact["binary"].endswith(".exe") else "paq_executable",
        ),
    )

paq_extension = module_extension(
    implementation = _paq_extension_impl,
    os_dependent = True,
    arch_dependent = True,
)
