def _paq_builder(ctx):
    name = ctx.label.name
    build_file_path = ctx.build_file_path
    paq_binary = ctx.executable.paq
    source = ctx.files.source
    output_file = ctx.actions.declare_file("{}.paq".format(name))

    source_path = source[0].path
    if len(source) > 1:
        build_path_parts = build_file_path.split("/")[:-1]
        source_path = '/'.join(source_path.split("/")[0:-len(build_path_parts)+1])

    command = (
        "{} {} | awk '{{printf \"\\\"%s\\\"\", $0}}' > {}"
    ).format(
        paq_binary.path,
        source_path,
        output_file.path,
    )

    ctx.actions.run_shell(
        inputs=[paq_binary] + source,
        outputs=[output_file],
        command=command,
        mnemonic="CreatePaqFile",
    )

    return [DefaultInfo(files = depset([output_file]))]

paq = rule(
    _paq_builder,
    attrs = {
        "paq": attr.label(
            doc = "The paq binary",
            executable = True,
            cfg = "host",
            default = "@crate_index//:paq__paq",
        ),
        "source": attr.label(
            doc = "File or Directory to be hashed by paq",
            allow_files = True,
        ),
    },
)