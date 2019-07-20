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
        16'h0000: data = 8'ha2;     // LDX #$FF
        16'h0001: data = 8'hff;
        16'h0002: data = 8'h38;     // SEC
        16'h0003: data = 8'h78;     // SEI
        16'h0004: data = 8'h9a;     // TXS
        16'h0005: data = 8'h08;     // PHP
        16'h0006: data = 8'h08;     // PHP
        16'h0007: data = 8'h28;     // PLP
        16'h0008: data = 8'hea;     // NOP

        16'h01fe: data = 8'hAA;
        16'h01ff: data = 8'hAA;
        16'hFFFC: data = 8'h00;
        16'hFFFD: data = 8'h00;
        default: data = 8'hff;
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
wire nmi = 1;
wire irq = 1;
wire clk1;
wire clk2;

cpu6502 cpu(clk, reset, irq, nmi, addr, idata, odata, rw, clk1, clk2);
rom r(addr, idata, rw);


initial begin
    $dumpfile(`VCDOUT);
    $dumpvars(0, test);
    # 4 reset = 0;
    # 192 $finish;
end

always #1
begin
    clk = !clk;
    if (clk)
        counter <= counter + 1;

    // Load timestamps are at the end of phi2 (falling edge of clk2)
    // Store timestamps are at the begin of phi2 (rising edge of clk2)

    // PHA
    `ASSERT_AT(16'h39, addr == 16'h01ff);
    `ASSERT_AT(16'h39, odata == 8'hb5);
    `ASSERT_AT(16'h39, rw == 0);
    // PHA
    `ASSERT_AT(16'h45, addr == 16'h01fe);
    `ASSERT_AT(16'h45, odata == 8'hb5);
    `ASSERT_AT(16'h45, rw == 0);
    // PLA
    `ASSERT_AT(16'h53, addr == 16'h01fe);
    `ASSERT_AT(16'h53, idata == 8'haa);
    `ASSERT_AT(16'h53, rw == 1);
    `ASSERT_AT(16'h55, cpu.control0.flags == 8'h8a);


end

endmodule
