package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_synth",
                            "verilog_test",
                            "ice40_binary",
                            "iverilog_compile",
)

verilog_library(
    name = "machine2_lib",
    srcs = [
        "machine2.v",
        "base_ram.v",
    ],
    deps = [
        "//cpu6502",
        "//uart",
        "//vga-pll:vdc",
    ],
)

iverilog_compile(
    name = "vmachine2",
    srcs = [ "ewoz_ram.v" ],
    deps = [":machine2_lib"],
)


verilog_synth(
    name = "machine2-sys",
    top = "machine2",
    srcs = [ "ewoz_ram.v" ],
    deps = [
        ":machine2_lib",
    ],
)

ice40_binary(
    name = "machine2",
    device = "hx8k",
    package = "ct256",
    src = ":machine2-sys",
    pinmap = "pinmap_ct256.pcf",
    force = True,
)

verilog_synth(
    name = "machine2-sys-basic",
    top = "machine2",
    srcs = [ "basic_ram.v" ],
    deps = [
        ":machine2_lib",
    ],
)

ice40_binary(
    name = "machine2-basic",
    device = "hx8k",
    package = "ct256",
    src = ":machine2-sys-basic",
    pinmap = "pinmap_ct256.pcf",
    force = True,
)

verilog_test(
    name = "boot_test",
    srcs = [ "boot_test.v" ],
    deps = [ ":machine2_lib" ],
)
