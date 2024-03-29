// Register file for 6502-alike

module regfile(
    input clk,
    input reset,
    input [3:0] rdsel1,
    input [3:0] rdsel2,
    input wrenable,
    input [3:0] wrsel,
    input [7:0] data,
    input [7:0] dbus,
    input tpcl,
    input incr_pc,
    output [7:0] read1,
    output [7:0] read2,
    output [15:0] pc,
    output [15:0] iaddr);

`include "cpu6502/regfile.vh"

reg [7:0] register[0:15];
integer i;

assign read1 = rdsel1 == REG_DB ? dbus : register[rdsel1];
assign read2 = rdsel2 == REG_DB ? dbus : register[rdsel2];
assign pc = {register[REG_PCH], register[REG_PCL]};
assign iaddr = {register[REG_IH], register[REG_IL]};

always @(negedge clk)
begin
    if (wrenable)
        register[wrsel] <= data;
    if (incr_pc)
        {register[REG_PCH], register[REG_PCL]} <=
            {register[REG_PCH], register[REG_PCL]} + 16'h0001;
    if (tpcl)
        register[REG_PCL] <= register[REG_T];
    if (reset)
    begin
        for(i=0; i<REG_NUM; i=i+1)
        begin
            register[i] <= (i==REG_SP) ? 8'hFF : 0;
        end
    end
end

/*
always @(negedge wrenable)
begin
    register[wrsel] <= data;
end

always @(negedge tpcl)
begin
    register[REG_PCL] <= register[REG_T];
end

always @(posedge incr_pc)
    {register[REG_PCH], register[REG_PCL]} <=
        {register[REG_PCH], register[REG_PCL]} + 16'h0001;

always @(posedge reset)
begin
    for(i=0; i<REG_NUM; i=i+1)
    begin
        register[i] <= 0;
    end
end
*/
endmodule
