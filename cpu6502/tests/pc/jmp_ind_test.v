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
        16'h0000: data = 8'h6c;     // JMP ($5597) ; real dest = $6101
        16'h0001: data = 8'h97;
        16'h0002: data = 8'h55;     

        16'h5597: data = 8'h01;
        16'h5598: data = 8'h61;
        16'h6101: data = 8'hea;
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

    // NOP after JMP ($5597) (=> $6101)
    `ASSERT_AT(16'h21, addr == 16'h6101);
    `ASSERT_AT(16'h21, idata == 8'hea);
end

endmodule
