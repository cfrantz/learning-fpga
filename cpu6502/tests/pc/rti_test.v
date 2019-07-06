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
        16'h2200: data = 8'ha2;     // LDX #$FF
        16'h2201: data = 8'hfc;
        16'h2202: data = 8'h9a;     // TXS
        16'h2203: data = 8'h40;     // RTS

        16'h01FD: data = 8'h81;     // cpu flags
        16'h01FE: data = 8'h96;     // Return address = $4496
        16'h01FF: data = 8'h44;

        16'h4496: data = 8'hEA;     // NOP
        16'hFFFC: data = 8'h00;
        16'hFFFD: data = 8'h22;
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

    // RTI with $4496 on the stack
    `ASSERT_AT(16'h35, addr == 16'h4496);
    `ASSERT_AT(16'h35, cpu.control0.flags == 8'h81);
    `ASSERT_AT(16'h35, idata == 8'hea);
end

endmodule
