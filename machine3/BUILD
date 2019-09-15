package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_synth",
                            "verilog_test",
                            "ecp5_binary",
                            "iverilog_compile",
)

verilog_library(
    name = "machine3_lib",
    srcs = [
        "pll.v",
        "machine3.v",
        "mapper.v",
        "main_memory.v",
        "basic_rom.v",
        "ehbasic/basic.hex",
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
    defines = [
        "IVERILOG=1",
    ],
    srcs = [
        "ewoz_ram.v",
        "ewoz_ram.vh",
    ],
)


verilog_synth(
    name = "machine3-sys",
    top = "machine3",
    defines = [
        "ECP5=1",
    ],
    srcs = [
        "ewoz_ram.v",
        "ewoz_ram.vh",
    ],
    deps = [
        ":machine3_lib",
    ],
    synth = "synth_ecp5",
)

ecp5_binary(
    name = "machine3",
    device = "um5g-85k",
    package = "CABGA381",
    src = ":machine3-sys",
    pinmap = "pinmap_ecp5_bga381.lpf",
    force = True,
)


verilog_test(
    name = "boot_test",
    srcs = [ "boot_test.v" ],
    deps = [ ":machine3_lib" ],
)
