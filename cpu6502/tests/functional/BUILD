package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_test",
)

#genrule(
#    name = "hexdump",
#    srcs = ["test.bin"],
#    outs = ["test.hexdump"],
#    cmd = "hexdump -vC $< | cut -c11-58 > $@",
#)

verilog_library(
    name = "ram",
    hdrs = [ ],
    srcs = [
        "ram.v",
        "test.hexdump",
    ],
)

verilog_test(
    name = "func_test",
    srcs = [ "func_test.v" ],
    deps = [
        ":ram",
        "//cpu6502",
    ],
)

