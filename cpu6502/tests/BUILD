package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_test",
)

verilog_test(
    name = "reset_test",
    srcs = [
        "reset_test.v",
    ],
    deps = [
        "//cpu6502",
    ],
)

verilog_test(
    name = "lda_test",
    srcs = [
        "lda_test.v",
    ],
    deps = [
        "//cpu6502",
    ],
)
