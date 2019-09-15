module mapper(
    input clk,
    input [15:0] cpuaddr,
    input [7:0] wdata,
    input rw,
    input cs,
    output [7:0] rdata,
    output [19:0] address);

reg [7:0] mmap[0:15];
reg [7:0] value;

assign address = {mmap[cpuaddr[15:12]], cpuaddr[11:0]};
assign rdata = (cs && rw) ? value : 8'bz;

always @(posedge clk)
begin
    if (cs)
        value <= mmap[cpuaddr[3:0]];
    if (cs && !rw)
    begin
        mmap[cpuaddr[3:0]] <= wdata;
    end
end

initial
begin
mmap[0] = 8'h00;
mmap[1] = 8'h01;
mmap[2] = 8'h02;
mmap[3] = 8'h03;

mmap[4] = 8'h04;
mmap[5] = 8'h05;
mmap[6] = 8'h06;
mmap[7] = 8'h07;

mmap[8] = 8'h08;
mmap[9] = 8'h09;
mmap[10] = 8'h0a;
mmap[11] = 8'hfb;

mmap[12] = 8'hfc;
mmap[13] = 8'hfd;
mmap[14] = 8'hfe;
mmap[15] = 8'hff;

end
endmodule
