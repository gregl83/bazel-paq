def _src_files_impl(ctx):
    output_dir = ctx.actions.declare_directory(ctx.attr.output)

    commands = []
    for file in ctx.files.source:
        file_path = file.path
        target_path = "{}/{}".format(output_dir.path, file_path)

        commands += [
            "mkdir -p $(dirname {}) && cp {} {}".format(
                target_path,
                file.path,
                target_path,
            )
        ]

    command = " && ".join([c for c in commands])

    ctx.actions.run_shell(
        inputs=ctx.files.source,
        outputs=[output_dir],
        command=command,
        mnemonic="CopyFiles",
    )

    return [DefaultInfo(files=depset([output_dir]))]

src_files = rule(
    implementation=_src_files_impl,
    attrs={
        "source": attr.label_list(
            doc = "Source dependency files.",
            allow_files = True,
        ),
        "output": attr.string(
            doc = "Name of the output directory.",
            mandatory=True,
        ),
    },
)