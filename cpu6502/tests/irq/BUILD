package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_test",
)

verilog_test(
    name = "reset_test",
    srcs = [ "reset_test.v" ],
    deps = [ "//cpu6502" ],
)

verilog_test(
    name = "brk_test",
    srcs = [ "brk_test.v" ],
    deps = [ "//cpu6502" ],
)

verilog_test(
    name = "irq_test",
    srcs = [ "irq_test.v" ],
    deps = [ "//cpu6502" ],
)

verilog_test(
    name = "nmi_test",
    srcs = [ "nmi_test.v" ],
    deps = [ "//cpu6502" ],
)
