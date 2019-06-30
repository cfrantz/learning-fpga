VerilogFiles = provider("transitive_sources")

def get_transitive_srcs(srcs, deps):
    return depset(
        srcs,
        transitive = [dep[VerilogFiles].transitive_sources for dep in deps],
    )

def _verilog_library_impl(ctx):
    tsrcs = get_transitive_srcs(ctx.files.srcs + ctx.files.hdrs, ctx.attr.deps)
    return [
        VerilogFiles(transitive_sources = tsrcs),
        DefaultInfo(files = tsrcs),
    ]

verilog_library = rule(
    implementation = _verilog_library_impl,
    attrs = {
        "hdrs": attr.label_list(allow_files = True),
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
    },
)

def _iverilog_compile(ctx):
    out = ctx.outputs.out
    tsrcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
    srcs = tsrcs.to_list()

    defines = []
    for d in ctx.attr.defines:
        defines.extend(["-D", d])
    srcpaths = [src.path for src in srcs if src.path.endswith(".v")]

    ctx.actions.run(
            outputs = [ctx.outputs.out],
            inputs = srcs,
            arguments = ["-o", out.path] + defines + srcpaths,
            executable = "iverilog"
    )

    return [DefaultInfo()]


iverilog_compile = rule(
    implementation = _iverilog_compile,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "defines": attr.string_list(),
    },
    outputs = {
        "out": "%{name}.dsn",
    },
    output_to_genfiles = True,
)

def _vvp_test(ctx):
    paths = []
    for src in ctx.files.srcs:
        p = src.path
        if "genfiles" in p:
            p = p.rsplit('genfiles/')[-1]
        paths.append(p)
    script = " ".join(["vvp", "-n"] + paths) + "\n"
    ctx.actions.write(
        output = ctx.outputs.executable,
        content = script
    )
    runfiles = ctx.runfiles(files=ctx.files.srcs)
    return [DefaultInfo(runfiles = runfiles)]

vvp_test = rule(
    implementation = _vvp_test,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
    },
    test = True
)

def verilog_test(
        name,
        srcs,
        deps = []):
    iverilog_compile(
            name = name + "_dsn",
            srcs = srcs,
            deps = deps,
            defines = [
                "DIE_ON_ASSERT",
            ],
    )
    vvp_test(
            name = name,
            srcs = [name + "_dsn.dsn"],
    )

