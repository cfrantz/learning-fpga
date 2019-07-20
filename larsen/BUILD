package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_synth",
                            "verilog_test",
                            "ice40_binary",
)

verilog_synth(
    name = "larsen-sys",
    top = "top",
    srcs = ["top.v"],
)

ice40_binary(
    name = "larsen",
    device = "hx8k",
    package = "ct256",
    src = ":larsen-sys",
    pinmap = "pinmap.pcf",
)
