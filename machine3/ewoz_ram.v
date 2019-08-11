// ram holding the EWOZ monitor program
module ewoz_ram(
    input clk,
    input wire [11:0] address,
    input wire [7:0] wdata,
    input wire rw,
    input wire ce,
    output wire [7:0] rdata);

reg [7:0] mem[0:4095];
reg [7:0] ldata;

assign rdata = (ce && rw) ? ldata : 8'bz;

always @(posedge clk)
begin
    ldata <= mem[address];
//    if (ce && !rw)
//        mem[address] <= wdata;
end

initial begin
`include "machine3/ewoz_ram.vh"
end
endmodule
