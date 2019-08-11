package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_synth",
                            "verilog_test",
                            "ice40_binary",
                            "iverilog_compile",
)

verilog_library(
    name = "machine3_lib",
    srcs = [
        "machine3.v",
        "mapper.v",
        "base_ram.v",
    ],
    deps = [
        "//cpu6502",
        "//uart",
        "//vdc",
    ],
)

iverilog_compile(
    name = "vmachine3",
    deps = [":machine3_lib"],
)


verilog_synth(
    name = "machine3-sys",
    top = "machine3",
    srcs = [
        "ewoz_ram.v",
        "ewoz_ram.vh",
    ],
    deps = [
        ":machine3_lib",
    ],
)

ice40_binary(
    name = "machine3",
    device = "hx8k",
    package = "ct256",
    src = ":machine3-sys",
    pinmap = "pinmap_ct256.pcf",
    force = True,
)

ice40_binary(
    name = "machine3-basic",
    device = "hx8k",
    package = "ct256",
    src = ":machine3-sys-basic",
    pinmap = "pinmap_ct256.pcf",
    force = True,
)

verilog_test(
    name = "boot_test",
    srcs = [ "boot_test.v" ],
    deps = [ ":machine3_lib" ],
)
