`define STRINGIFY(x) `"x`"
`ifdef DIE_ON_ASSERT
`define DIE $finish_and_return(1);
`else
`define DIE
`endif
`define VCDOUT {`__FILE__, "cd"}
`define ASSERT_AT(count_, cond_) \
    if (count_ == counter && (cond_) != 1) \
    begin \
        $display("[%s, %d] Assertion failed: %s", \
                 `__FILE__, `__LINE__, `STRINGIFY(cond_)); \
        `DIE \
    end


module test;

reg reset = 1;
reg clk = 0;
reg [31:0] counter = 32'hffff_fffe;

wire [15:0] addr;
wire [7:0] idata;
wire [7:0] odata;
wire rw;
wire clk1;
wire clk2;

wire [3:0] vga_r;
wire [3:0] vga_g;
wire [3:0] vga_b;
wire vga_hs, vga_vs;


vdc vdc(
    .clk(clk),
    .phi2(1'b0),
    .reset(reset),
    .vram_cs(1'b0),
    .vreg_cs(1'b0),
    .addr(addr),
    .rw(1'b1),
    .idata(idata),
    .odata(odata),
    .vga_r(vga_r),
    .vga_g(vga_b),
    .vga_b(vga_g),
    .vga_hs(vga_hs),
    .vga_vs(vga_vs));

initial begin
    $dumpfile(`VCDOUT);
    $dumpvars(0, test);
    # 2 reset = 0;
    # 1000 $finish;
end

always #1
begin
    clk = !clk;
    if (clk)
        counter <= counter + 1;

    // Load timestamps are at the end of phi2 (falling edge of clk2)
    // Store timestamps are at the begin of phi2 (rising edge of clk2)

end

endmodule
