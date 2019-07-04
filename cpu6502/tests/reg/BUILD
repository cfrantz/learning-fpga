package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_test",
)

verilog_test(
    name = "lda_stxy_test",
    srcs = [ "lda_stxy_test.v" ],
    deps = [ "//cpu6502" ],
)
