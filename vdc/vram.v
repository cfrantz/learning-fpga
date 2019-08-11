// Fake dual port RAM.
// Run at 2x the clock speed and switch between the two sides.
module vram(
    input clk2x,
    input [11:0] addr_a,
    input [7:0] wdata_a,
    input cs_a,
    input rw_a,
    output [7:0] rdata_a,

    input [11:0] addr_b,
    input [7:0] wdata_b,
    input cs_b,
    input rw_b,
    output [7:0] rdata_b);

wire [11:0] address;
reg [7:0] mem[0:4095];
reg [7:0] data;
reg [7:0] data_a;
reg [7:0] data_b;
reg side = 0;

assign address = side ? addr_a : addr_b;
assign rdata_a = (cs_a && rw_a) ? data_a : 8'bz;
assign rdata_b = (cs_b && rw_b) ? data_b : 8'bz;

always @(posedge clk2x)
begin
    side <= ~side;
    data <= mem[address];
    if (~side)
        data_a <= data;
    else
        data_b <= data;

    if ((side==1 && cs_a && !rw_a) || (side==0 && cs_b && !rw_b))
        mem[address] <= side ? wdata_a : wdata_b;
end

initial
begin
`include "vdc/vram_init.vh"

end

endmodule
