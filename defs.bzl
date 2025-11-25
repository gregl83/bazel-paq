def _get_common_root(files):
    """Calculates the common directory prefix for a list of files."""
    if not files:
        return ""

    common_segments = files[0].dirname.split("/")

    for f in files[1:]:
        current_segments = f.dirname.split("/")
        limit = min(len(common_segments), len(current_segments))
        match_len = 0

        for i in range(limit):
            if common_segments[i] == current_segments[i]:
                match_len += 1
            else:
                break

        common_segments = common_segments[:match_len]
        if not common_segments:
            return ""

    return "/".join(common_segments)

def _paq_aspect_impl(target, ctx):
    paq_binary = ctx.executable._paq_tool
    all_inputs = target[DefaultInfo].files.to_list()
    # only keep files that are NOT source files
    generated_inputs = [f for f in all_inputs if not f.is_source]
    # skip if target has no generated inputs (i.e., only source files)
    if not generated_inputs:
        return []

    # determine source file/dir path and output file (e.g., .paq)
    if len(generated_inputs) > 1:
        source_path = _get_common_root(generated_inputs)
        if source_path == "":
            source_path = "."
        output_file = ctx.actions.declare_file(
            ".paq",
            sibling=generated_inputs[0]
        )
    else:
        source_path = generated_inputs[0].path
        output_file = ctx.actions.declare_file(
            generated_inputs[0].basename + ".paq",
            sibling=generated_inputs[0]
        )

    # paq hash target output
    command = (
        "{paq} $(readlink -f \"{src}\") | awk '{{printf \"\\\"%s\\\"\", $0}}' > {out}"
    ).format(
        paq = paq_binary.path,
        src = source_path,
        out = output_file.path
    )
    ctx.actions.run_shell(
        inputs = [paq_binary] + generated_inputs,
        outputs = [output_file],
        command = command,
        mnemonic = "PaqAspect",
        progress_message = "Paq hashing generated artifacts for {}".format(target.label)
    )

    return [
        OutputGroupInfo(
            paq_files = depset([output_file])
        )
    ]

paq_aspect = aspect(
    implementation = _paq_aspect_impl,
    attr_aspects = ["deps"],
    attrs = {
        "_paq_tool": attr.label(
            doc = "The paq binary",
            executable = True,
            cfg = "exec",
            default = "@paq//:binary"
        )
    }
)