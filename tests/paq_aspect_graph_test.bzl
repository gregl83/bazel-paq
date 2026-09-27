load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//:defs.bzl", "paq_aspect")

def _paq_aspect_test_impl(ctx):
    env = analysistest.begin(ctx)

    # get test target
    target = analysistest.target_under_test(env)

    # assert OutputGroupInfo exists
    if OutputGroupInfo not in target:
        asserts.equals(env, [], ctx.attr.expected, "OutputGroupInfo provider not found on target")
        return analysistest.end(env)
    output_info = target[OutputGroupInfo]

    # assert 'paq_files' output group exists from paq aspect execution
    if not hasattr(output_info, "paq_files"):
        asserts.equals(env, [], ctx.attr.expected, "'paq_files' output group not found")
        return analysistest.end(env)
    paq_files = output_info.paq_files.to_list()

    # assert file output paths
    expected = ctx.attr.expected
    actual = [paq_file.short_path for paq_file in paq_files]
    asserts.equals(env, sorted(expected), sorted(actual))

    return analysistest.end(env)

paq_aspect_test = analysistest.make(
    _paq_aspect_test_impl,
    extra_target_under_test_aspects = [paq_aspect],
    attrs = {
        "expected": attr.string_list(
            doc = "Expected output .paq filepaths.",
        ),
    },
)

def graph_test(name, target_under_test, expected):
    paq_aspect_test(
        name = name,
        target_under_test = target_under_test,
        expected = expected,
        testonly = True,
    )
