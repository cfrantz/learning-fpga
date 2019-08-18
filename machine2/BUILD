package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_synth",
                            "verilog_test",
                            "ice40_binary",
                            "ecp5_binary",
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
    name = "machine2-ice40",
    top = "machine2",
    defines = [
        "ICE40=1",
    ],
    srcs = [ "ewoz_ram.v" ],
    deps = [
        ":machine2_lib",
    ],
)

ice40_binary(
    name = "machine2",
    device = "hx8k",
    package = "ct256",
    src = ":machine2-ice40",
    pinmap = "pinmap_ct256.pcf",
    force = True,
)

verilog_synth(
    name = "machine2-ice40-basic",
    top = "machine2",
    defines = [
        "ICE40=1",
    ],
    srcs = [
        "basic_ram.v",
        "basic_ram.vh",
    ],
    deps = [
        ":machine2_lib",
    ],
)

ice40_binary(
    name = "machine2-basic",
    device = "hx8k",
    package = "ct256",
    src = ":machine2-ice40-basic",
    pinmap = "pinmap_ct256.pcf",
    force = True,
)

verilog_synth(
    name = "machine2-ecp5",
    top = "machine2",
    defines = [
        "ECP5=1",
    ],
    srcs = [ "ewoz_ram.v" ],
    deps = [
        ":machine2_lib",
    ],
    synth = "synth_ecp5",
)

ecp5_binary(
    name = "machine2e",
    device = "um5g-85k",
    package = "CABGA381",
    src = ":machine2-ecp5",
    pinmap = "pinmap_ecp5_bga381.lpf",
    force = True,
)

verilog_test(
    name = "boot_test",
    srcs = [ "boot_test.v" ],
    deps = [ ":machine2_lib" ],
)
