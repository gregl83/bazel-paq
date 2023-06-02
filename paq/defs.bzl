"""Rules for creating paq hash target deps
"""

def _custom_tool_action_impl(ctx):
    # Get the Rust tool binary
    paq_binary = ctx.executable.paq_binary

    # The input file to process
    input_file = ctx.file.src

    # The output file to generate
    output_file = ctx.actions.declare_file(ctx.label.name + "_processed.txt")

    # Run the Rust tool binary with the input and output files as arguments
    ctx.actions.run(
        executable = paq_binary,
        arguments = [
            input_file.path,
            output_file.path,
        ],
        inputs = [input_file],
        outputs = [output_file],
    )

    # Return the output file as a DefaultInfo provider
    return [DefaultInfo(files = depset([output_file]))]

custom_tool_action = rule(
    implementation = _custom_tool_action_impl,
    attrs = {
        "src": attr.label(allow_single_file = True),
        "paq_binary": attr.label(
            default = "paq",  # Use the alias
            executable = True,
            cfg = "host",
        ),
    },
)