package(default_visibility=["//visibility:public"])
load("//rules:verilog.bzl", "verilog_library",
                            "verilog_test",
)

# Tests for instructions which use the ALU

# The ORA tests exercise all of the address modes
# The logic for ORA, AND, EOR, ADC, SBC and CMP all use the same states,
# so the tests for the other operations only have to test op-result and flags.
verilog_test(
    name = "ora_imm_test",
    srcs = [ "ora_imm_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "ora_zp_test",
    srcs = [ "ora_zp_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "ora_zpx_test",
    srcs = [ "ora_zpx_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "ora_abs_test",
    srcs = [ "ora_abs_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "ora_absx_test",
    srcs = [ "ora_absx_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "ora_absy_test",
    srcs = [ "ora_absy_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "ora_ix_test",
    srcs = [ "ora_ix_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "ora_iy_test",
    srcs = [ "ora_iy_test.v" ],
    deps = [ "//cpu6502" ],
)


verilog_test(
    name = "and_nflag_test",
    srcs = [ "and_nflag_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "and_zflag_test",
    srcs = [ "and_zflag_test.v" ],
    deps = [ "//cpu6502" ],
)

verilog_test(
    name = "eor_nflag_test",
    srcs = [ "eor_nflag_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "eor_zflag_test",
    srcs = [ "eor_zflag_test.v" ],
    deps = [ "//cpu6502" ],
)

verilog_test(
    name = "adc_zcflag_test",
    srcs = [ "adc_zcflag_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "adc_nvflag_test",
    srcs = [ "adc_nvflag_test.v" ],
    deps = [ "//cpu6502" ],
)

verilog_test(
    name = "sbc_nvflag_test",
    srcs = [ "sbc_nvflag_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "sbc_cflag_test",
    srcs = [ "sbc_cflag_test.v" ],
    deps = [ "//cpu6502" ],
)

verilog_test(
    name = "cmp_lt_test",
    srcs = [ "cmp_lt_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "cmp_eq_test",
    srcs = [ "cmp_eq_test.v" ],
    deps = [ "//cpu6502" ],
)
verilog_test(
    name = "cmp_gt_test",
    srcs = [ "cmp_gt_test.v" ],
    deps = [ "//cpu6502" ],
)




