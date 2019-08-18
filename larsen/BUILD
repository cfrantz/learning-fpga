package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_synth",
                            "verilog_test",
                            "ice40_binary",
                            "ecp5_binary",
)

verilog_synth(
    name = "larsen-ice40",
    top = "top",
    srcs = ["top.v"],
)

ice40_binary(
    name = "larsen",
    device = "hx8k",
    package = "ct256",
    src = ":larsen-ice40",
    pinmap = "pinmap.pcf",
)

verilog_synth(
    name = "larsen-ecp5",
    top = "top",
    srcs = ["top.v"],
    synth = "synth_ecp5",
)

ecp5_binary(
    name = "larsene",
    device = "um5g-85k",
    package = "CABGA381",
    src = ":larsen-ecp5",
    pinmap = "pinmap_ecp5_bga381.lpf",
)
