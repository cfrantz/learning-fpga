module vreg(
    input clk,
    input [5:0] address,
    input [7:0] wdata,
    input [3:0] color,
    input rw,
    input ce,
    output [7:0] rdata,
    output [11:0] cdata,
    output [23:0] vramstart,
    output [23:0] cramstart);

reg [7:0] mem[0:63];
reg [7:0] value;

assign cdata = {
    mem[{2'b01, color}][7:4],
    mem[{2'b10, color}][7:4],
    mem[{2'b11, color}][7:4]};

assign rdata = (ce && rw) ? value : 8'bz;

assign vramstart = {mem[2], mem[1], mem[0]};
assign cramstart = {mem[6], mem[5], mem[4]};

always @(posedge clk)
begin
    if (ce)
        value <= mem[address];
    if (ce && !rw)
    begin
        mem[address] <= wdata;
    end
end

initial
begin
    // VRAM starts at $9000
    mem[0] = 8'h00;
    mem[1] = 8'h90;
    mem[2] = 8'h00;
    mem[3] = 8'h00;

    // CRAM starts at $a800
    mem[4] = 8'h00;
    mem[5] = 8'ha8;
    mem[6] = 8'h00;
    mem[7] = 8'h00;

    // Palette entries
    // Red
    mem[16*1+0] = 8'h00;
    mem[16*1+1] = 8'h80;
    mem[16*1+2] = 8'h00;
    mem[16*1+3] = 8'h80;
    mem[16*1+4] = 8'h00;
    mem[16*1+5] = 8'h80;
    mem[16*1+6] = 8'h00;
    mem[16*1+7] = 8'hc0;
    mem[16*1+8] = 8'h80;
    mem[16*1+9] = 8'hff;
    mem[16*1+10] = 8'h00;
    mem[16*1+11] = 8'hff;
    mem[16*1+12] = 8'h00;
    mem[16*1+13] = 8'hff;
    mem[16*1+14] = 8'h00;
    mem[16*1+15] = 8'hff;

    // Green
    mem[16*2+0] = 8'h00;
    mem[16*2+1] = 8'h00;
    mem[16*2+2] = 8'h80;
    mem[16*2+3] = 8'h80;
    mem[16*2+4] = 8'h00;
    mem[16*2+5] = 8'h00;
    mem[16*2+6] = 8'h80;
    mem[16*2+7] = 8'hc0;
    mem[16*2+8] = 8'h80;
    mem[16*2+9] = 8'h00;
    mem[16*2+10] = 8'hff;
    mem[16*2+11] = 8'hff;
    mem[16*2+12] = 8'h00;
    mem[16*2+13] = 8'h00;
    mem[16*2+14] = 8'hff;
    mem[16*2+15] = 8'hff;

    // Blue
    mem[16*3+0] = 8'h00;
    mem[16*3+1] = 8'h00;
    mem[16*3+2] = 8'h00;
    mem[16*3+3] = 8'h00;
    mem[16*3+4] = 8'h80;
    mem[16*3+5] = 8'h80;
    mem[16*3+6] = 8'h80;
    mem[16*3+7] = 8'hc0;
    mem[16*3+8] = 8'h80;
    mem[16*3+9] = 8'h00;
    mem[16*3+10] = 8'h00;
    mem[16*3+11] = 8'h00;
    mem[16*3+12] = 8'hff;
    mem[16*3+13] = 8'hff;
    mem[16*3+14] = 8'hff;
    mem[16*3+15] = 8'hff;

end
endmodule
