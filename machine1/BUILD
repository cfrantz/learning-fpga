package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_synth",
                            "verilog_test",
                            "ice40_binary",
                            "iverilog_compile",
)

verilog_library(
    name = "machine1_lib",
    srcs = [
        "machine1.v",
        "base_ram.v",
        "ewoz_ram.v",
    ],
    deps = [
        "//cpu6502",
        "//uart",
    ],
)

iverilog_compile(
    name = "vmachine1",
    deps = [":machine1_lib"],
)


verilog_synth(
    name = "machine1-sys",
    top = "machine1",
    srcs = [
    ],
    deps = [
        ":machine1_lib",
    ],
)

ice40_binary(
    name = "machine1",
    device = "hx8k",
    package = "ct256",
    src = ":machine1-sys",
    pinmap = "pinmap_ct256.pcf",
    force = True,
)

verilog_test(
    name = "boot_test",
    srcs = [ "boot_test.v" ],
    deps = [ ":machine1_lib" ],
)
