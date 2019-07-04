package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_test",
)

verilog_test(
    name = "dec_zp_test",
    srcs = [ "dec_zp_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "inc_zp_test",
    srcs = [ "inc_zp_test.v" ],
    deps = [ "//cpu6502" ],
)
