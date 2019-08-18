package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_synth",
                            "verilog_test",
                            "ice40_binary",
)

verilog_library(
    name = "vdc",
    hdrs = [
        "vram_init.vh",
    ],
    srcs = [
        "vdc.v",
        "vga.v",
        "vram.v",
        "vreg.v",
        "pll.v",
    ],
)

verilog_test(
    name = "func_test",
    srcs = [
        "func_test.v",
    ],
    deps = [
        ":vdc",
    ],
)

verilog_synth(
    name = "fpga-sys",
    top = "fpga",
    srcs = ["fpga.v"],
    deps = [
        ":vdc",
    ],
)

ice40_binary(
    name = "fpga",
    device = "hx8k",
    package = "ct256",
    src = ":fpga-sys",
    pinmap = "pinmap.pcf",
)
