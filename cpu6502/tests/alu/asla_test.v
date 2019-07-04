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

module rom(address, data, rd);
input [15:0] address;
output [7:0] data;
input rd;
reg [7:0] data;

always @(rd or address)
begin
    case (address)
        0: data = 8'ha9;    // LDA #$ff
        1: data = 8'hff;    // 
        2: data = 8'h0a;    // LSRA
        3: data = 8'h0a;    // LSRA
        4: data = 8'h0a;    // LSRA
        5: data = 8'h0a;    // LSRA
        6: data = 8'h0a;    // LSRA
        7: data = 8'h0a;    // LSRA
        8: data = 8'h0a;    // LSRA
        9: data = 8'h0a;    // LSRA
        10: data = 8'h4a;   // LSRA
        11: data = 8'h85;   // STA $99
        12: data = 8'h99;   // 

        16'hFFFC: data = 8'h00;
        16'hFFFD: data = 8'h00;
        default: data = 8'h00;
    endcase

end
endmodule

module test;

reg reset = 1;
reg clk = 0;
reg [15:0] counter = 0;

wire [15:0] addr;
wire [7:0] idata;
wire [7:0] odata;
wire rw;
wire nmi;
wire irq;
wire clk1;
wire clk2;

cpu6502 cpu(clk, reset, irq, nmi, addr, idata, odata, rw, clk1, clk2);
rom r(addr, idata, rw);


initial begin
    $dumpfile(`VCDOUT);
    $dumpvars(0, test);
    # 1 reset = 0;
    # 192 $finish;
end

always #1
begin
    clk = !clk;
    counter <= counter + 1;

    // Load timestamps are at the end of phi2 (falling edge of clk2)
    // Store timestamps are at the begin of phi2 (rising edge of clk2)

    // Check that we're shifting left.
    `ASSERT_AT(16'h1c, cpu.control0.reg1 == 8'hfe);
    `ASSERT_AT(16'h24, cpu.control0.reg1 == 8'hfc);

    // At t=0x54, A=0, last bit was shifted into C, so ZC should be set.
    `ASSERT_AT(16'h54, cpu.control0.flags == 8'h03);

    // At t=0x5c, A=0, zero was shifted into C, so Z should be set.
    `ASSERT_AT(16'h5c, cpu.control0.flags == 8'h02);
    // STA $99
    `ASSERT_AT(16'h67, addr == 16'h0099);
    `ASSERT_AT(16'h67, odata == 8'h00);
    `ASSERT_AT(16'h67, rw == 0);

end

endmodule
