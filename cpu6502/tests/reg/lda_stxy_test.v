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
        0: data = 8'ha9;    // LDA #0
        1: data = 8'h00;    // 
        2: data = 8'haa;    // TAX
        3: data = 8'ha8;    // TAY
        4: data = 8'he8;    // INX
        5: data = 8'h88;    // DEY
        6: data = 8'h86;    // STX $80
        7: data = 8'h80;
        8: data = 8'h84;    // STY $80
        9: data = 8'h81;

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

    // INX, STX
    `ASSERT_AT(16'h45, addr == 16'h0080);
    `ASSERT_AT(16'h45, odata == 8'h01);
    `ASSERT_AT(16'h45, rw == 0);

    // DEY, STY
    `ASSERT_AT(16'h51, addr == 16'h0081);
    `ASSERT_AT(16'h51, odata == 8'hFF);
    `ASSERT_AT(16'h51, rw == 0);

end

endmodule
