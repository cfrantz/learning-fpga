package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_test",
)

verilog_test(
    name = "pha_test",
    srcs = [ "pha_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "php_test",
    srcs = [ "php_test.v" ],
    deps = [ "//cpu6502" ],
)
