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
        "hdrs": attr.label_list(allow_files=True),
        "srcs": attr.label_list(allow_files=True),
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
        "srcs": attr.label_list(allow_files=True),
        "deps": attr.label_list(),
        "defines": attr.string_list(),
    },
    outputs = {
        "out": "%{name}.dsn",
    },
    output_to_genfiles=True,
)

def _verilog_synth(ctx):
    out = ctx.outputs.out
    tsrcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
    srcs = tsrcs.to_list()

    defines = []
    for d in ctx.attr.defines:
        defines.extend(["-D", d])
    srcpaths = [src.path for src in srcs if src.path.endswith(".v")]
    cmd = ctx.attr.synth + " -top " + ctx.attr.top + " -json " + out.path

    ctx.actions.run(
        outputs = [ctx.outputs.out],
        inputs = srcs,
        arguments = ["-p", cmd] + defines + srcpaths,
        executable = ctx.attr._yosys,
    )
    return [DefaultInfo()]

verilog_synth = rule(
    implementation = _verilog_synth,
    attrs = {
        "top": attr.string(mandatory=True),
        "synth": attr.string(default="synth_ice40"),
        "srcs": attr.label_list(allow_files=True),
        "deps": attr.label_list(),
        "defines": attr.string_list(),
        "_yosys": attr.string(default="/opt/icestorm/bin/yosys"),
    },
    outputs = {
        "out": "%{name}.json",
    },
)

def _ice40_binary(ctx):
    asc = ctx.outputs.asc
    binary = ctx.outputs.bin
    srcs = ctx.files.src + ctx.files.pinmap

    args = [
        "--" + ctx.attr.device,
        "--package", ctx.attr.package,
        "--json", ctx.files.src[0].path,
        "--pcf", ctx.files.pinmap[0].path,
        "--asc", asc.path,
    ]
    if ctx.attr.force:
        args.append("--force")


    ctx.actions.run(
        outputs = [ctx.outputs.asc],
        inputs = srcs,
        arguments = args,
        executable = ctx.attr._pnr,
    )
    ctx.actions.run(
        outputs = [ctx.outputs.bin],
        inputs = [ctx.outputs.asc],
        arguments = [asc.path, binary.path],
        executable = ctx.attr._pack,
    )

    return [DefaultInfo()]

ice40_binary = rule(
    implementation = _ice40_binary,
    attrs = {
        "device": attr.string(mandatory=True),
        "package": attr.string(mandatory=True),
        "src": attr.label(mandatory=True, allow_files=True),
        "pinmap": attr.label(mandatory=True, allow_files=True),
        "force": attr.bool(default=False),
        "_pnr": attr.string(default="/opt/icestorm/bin/nextpnr-ice40"),
        "_pack": attr.string(default="/opt/icestorm/bin/icepack"),

    },
    outputs = {
        "asc": "%{name}.asc",
        "bin": "%{name}.bin",
    },
)

def _ecp5_binary(ctx):
    asc = ctx.outputs.asc
    binary = ctx.outputs.bit
    svf = ctx.outputs.svf
    srcs = ctx.files.src + ctx.files.pinmap

    args = [
        "--" + ctx.attr.device,
        "--package", ctx.attr.package,
        "--json", ctx.files.src[0].path,
        "--lpf", ctx.files.pinmap[0].path,
        "--textcfg", asc.path,
    ]
    if ctx.attr.force:
        args.append("--force")


    ctx.actions.run(
        outputs = [ctx.outputs.asc],
        inputs = srcs,
        arguments = args,
        executable = ctx.attr._pnr,
    )
    ctx.actions.run(
        outputs = [ctx.outputs.bit, ctx.outputs.svf],
        inputs = [ctx.outputs.asc],
        arguments = ['--svf', svf.path, asc.path, binary.path],
        executable = ctx.attr._pack,
    )

    return [DefaultInfo()]

ecp5_binary = rule(
    implementation = _ecp5_binary,
    attrs = {
        "device": attr.string(mandatory=True),
        "package": attr.string(mandatory=True),
        "src": attr.label(mandatory=True, allow_files=True),
        "pinmap": attr.label(mandatory=True, allow_files=True),
        "force": attr.bool(default=False),
        "_pnr": attr.string(default="/opt/icestorm/bin/nextpnr-ecp5"),
        "_pack": attr.string(default="/opt/icestorm/bin/ecppack"),

    },
    outputs = {
        "asc": "%{name}.asc",
        "bit": "%{name}.bit",
        "svf": "%{name}.svf",
    },
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
        "srcs": attr.label_list(allow_files=True),
    },
    test=True
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
    iverilog_compile(
        name = name + "_nodie",
        srcs = srcs,
        deps = deps,
        defines = [],
    )
    native.genrule(
        name = name + "_vcd",
        srcs = [name + "_nodie.dsn"],
        outs = [srcs[0] + "cd"],
        cmd = """
            FILE="$<"
            DIR="$${FILE%%genfiles/*}genfiles"
            INFILE="$${FILE##*genfiles/}"
            cd "$$DIR"
            vvp -n "$$INFILE"
        """,
    )
    vvp_test(
        name = name,
        srcs = [name + "_dsn.dsn"],
    )

