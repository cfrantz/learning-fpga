// Create a simple VGA output
/* module */
module fpga(
            input CLK12MHz,
            output [2:0] vga_r,
            output [2:0] vga_g,
            output [2:0] vga_b,
            output vga_hs,
            output vga_vs,
            output [7:0] led);

wire xr, xg, xb;

vdc vdc0(
    .clk(CLK12MHz),
    .phi2(1'b0),
    .reset(1'b0),
    .vram_cs(1'b0),
    .vreg_cs(1'b0),
    .addr(12'b0),
    .rw(1'b1),
    .idata(8'b0),
    .vga_r({vga_r, xr}),
    .vga_g({vga_g, xg}),
    .vga_b({vga_b, xb}),
    .vga_hs(vga_hs),
    .vga_vs(vga_vs));

endmodule
