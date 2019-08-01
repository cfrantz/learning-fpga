module vram(
    input clk,
    input wire [11:0] address,
    input wire [7:0] wdata,
    input wire rw,
    output reg [7:0] rdata);

reg [7:0] mem[0:4095];
reg [7:0] ldata;

always @(posedge clk)
begin
    rdata <= mem[address];
    if (!rw)
        mem[address] <= wdata;
end

initial
begin
`include "vga-pll/vram_init.vh"

end

endmodule
