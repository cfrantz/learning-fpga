package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_test",
)

verilog_library(
    name = "cpu6502",
    hdrs = [
        "alu.vh",
        "regfile.vh",
    ],
    srcs = [
        "alu.v",
        "control.v",
        "cpu.v",
        "regfile.v",
    ],
)

#verilog_test(
#    name = "reset_test",
#    srcs = [
#        "tests/reset_test.v",
#    ],
#    deps = [
#        ":cpu6502",
#    ],
#)
#
#verilog_test(
#    name = "lda_test",
#    srcs = [
#        "tests/lda_test.v",
#    ],
#    deps = [
#        ":cpu6502",
#    ],
#)
