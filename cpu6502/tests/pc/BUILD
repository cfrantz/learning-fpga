package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_test",
)

verilog_test(
    name = "jmp_abs_test",
    srcs = [ "jmp_abs_test.v" ],
    deps = [ "//cpu6502" ],
)

verilog_test(
    name = "jmp_ind_test",
    srcs = [ "jmp_ind_test.v" ],
    deps = [ "//cpu6502" ],
)

verilog_test(
    name = "jsr_test",
    srcs = [ "jsr_test.v" ],
    deps = [ "//cpu6502" ],
)





