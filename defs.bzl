"""Hash each generated output artifact beside its filesystem path."""

_PaqInfo = provider(fields = {"hashes": "Map from output artifacts to their hash artifacts."})

def _dependencies(ctx):
    dependencies = []
    for name in dir(ctx.rule.attr):
        value = getattr(ctx.rule.attr, name)
        if type(value) == "Target":
            dependencies.append(value)
        elif type(value) == "list":
            dependencies.extend([dep for dep in value if type(dep) == "Target"])
        elif type(value) == "dict":
            dependencies.extend([dep for dep in value.keys() if type(dep) == "Target"])
            dependencies.extend([dep for dep in value.values() if type(dep) == "Target"])
    return dependencies

def _paq_aspect_impl(target, ctx):
    generated = [f for f in target[DefaultInfo].files.to_list() if not f.is_source]
    inherited = {}
    dependencies = _dependencies(ctx)
    for dep in dependencies:
        if _PaqInfo in dep:
            inherited.update(dep[_PaqInfo].hashes)

    # Link referents must be declared outputs or dependency artifacts so that
    # --follow can read them in a sandbox and changes invalidate the hash.
    inputs = depset(
        generated,
        transitive = [dep[DefaultInfo].files for dep in dependencies if DefaultInfo in dep],
    )
    hashes = {}
    for artifact in generated:
        if artifact in inherited:
            hashes[artifact] = inherited[artifact]
            continue
        output = ctx.actions.declare_file(artifact.basename + ".paq", sibling = artifact)
        ctx.actions.run(
            executable = ctx.executable._paq_tool,
            inputs = inputs,
            outputs = [output],
            arguments = ["--follow", artifact.path, "--out=" + output.path],
            mnemonic = "PaqAspect",
            progress_message = "Paq hashing " + artifact.short_path,
        )
        hashes[artifact] = output

    return [
        _PaqInfo(hashes = hashes),
        OutputGroupInfo(paq_files = depset(hashes.values())),
    ]

paq_aspect = aspect(
    implementation = _paq_aspect_impl,
    # Forwarders may expose outputs through srcs, deps, or custom attributes.
    attr_aspects = ["*"],
    apply_to_generating_rules = True,
    attrs = {
        "_paq_tool": attr.label(
            doc = "The paq binary",
            executable = True,
            cfg = "exec",
            default = "@paq//:binary",
        ),
    },
)
