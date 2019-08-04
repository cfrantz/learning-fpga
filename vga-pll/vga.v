// Create a simple VGA output
module vga (input CLK12MHz,
            input phi2,
            input reset,
            input ce,
            input rw,
            input [7:0] idata,
            input [11:0] addr,
            output [7:0] odata,
            output reg [3:0] color,
            output reg hsync,
            output reg vsync);

// I've pushed front porch/back porch by 8 pixels so that c_hor will lead
// the beam position by 8-pixels.  This allows easier prefetching of char,
// color and chr-rom data one character cell ahead of time.

parameter h_pulse = 96;     // H-sync pulse = 3.83us
parameter leader = 16;
parameter h_bp = 48-leader; // back porch pulse width
parameter h_pixels = 512;   // Number of horizontal pixels
parameter h_fp = 128+16+leader;      // front porch pulse width
parameter h_pol = 1'b0;     // hsync polarity
parameter h_frame = 800;    // Total horizontal frame (46+48+256+31)

parameter v_pulse = 2;      // v-sync pulse width
parameter v_bp = 31;        // back porch pulse width
parameter v_pixels = 480;   // number of vertical pixels
parameter v_fp = 11;        // front porch width
parameter v_pol = 1'b1;     // vsync polarity
parameter v_frame = 525;    // Total vertical frame (2+33+480+10)

wire vga_clk;
SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(4'b0000),
        .DIVF(7'b1000010),
        .DIVQ(3'b101),
        .FILTER_RANGE(3'b001)
    ) uut (
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(CLK12MHz),
        .PLLOUTCORE(vga_clk));

// Video color and sync registers
reg [9:0] c_hor = 0;            // Complete frame register column
reg [9:0] c_ver = 0;            // Complete frame register row

reg [7:0] next_char;
reg [7:0] next_color;
reg [7:0] next_bitmap;
reg [7:0] cur_char;
reg [7:0] cur_color;
reg [7:0] cur_bitmap = 8'h0f;
reg [11:0] cpuaddr;
reg [7:0] cpudata;
reg [7:0] cpuread;

wire [11:0] vaddr;
wire [7:0] vdata;
reg cpurd;
reg cpuwr;
reg last_ce;
reg last_we;
reg [3:0] vstate;
reg [1:0] cstate;

assign odata = (ce && rw) ? cpuread : 8'bz;

assign vaddr =  (vstate[0] == 0 && (cpurd || cpuwr)) ?  cpuaddr :
                (vstate[3:1] == 3'b000) ?  {2'b00, c_ver[8:4], c_hor[8:4]} :
                (vstate[3:1] == 3'b001) ?  {2'b01, c_ver[8:4], c_hor[8:4]} :
                (vstate[3:1] == 3'b010) ?  {1'b1, next_char, c_ver[3:1]} : 0;

vram vram0(
    .clk(vga_clk),
    .address(vaddr),
    .wdata(cpudata),
    .rw(~cpuwr),
    .rdata(vdata));

always @(posedge vga_clk) begin

    if (cstate == 2'b10) begin
        if (cpurd) begin
            cpuread <= vdata;
            cpurd <= 0;
        end
        if (cpuwr) begin
            cpuwr <= 0;
        end
    end

    if (reset) begin
        c_hor <= 0;
        c_ver <= 0;
        hsync <= ~h_pol;
        vsync <= ~v_pol;
        cpurd <= 0;
        cpuwr <= 0;
        vstate <= 0;
    end
    else begin
        if (ce && ~last_ce) begin
            cpurd <= 1;
            cpuaddr <= addr;
            cstate <= 0;
        end
        last_ce <= ce;
        if (ce && ~rw && ~last_we) begin
            cpuwr <= 1;
            cpuaddr <= addr;
            cpudata <= idata;
            cstate <= 0;
        end
        last_we <= (ce && ~rw);


        // Update beam position 
        if (c_hor < h_frame - 1) begin
            c_hor <= c_hor + 1;
        end
        else begin
            c_hor <= 0;
            vstate <= 0;
            if (c_ver < v_frame - 1) begin
                c_ver <= c_ver + 1;
            end
            else begin
                c_ver <= 0;
            end
        end

        // Generate Hsync
        if (c_hor < h_pixels + h_fp || c_hor > h_pixels + h_fp + h_pulse) begin
            hsync <= ~h_pol;
        end
        else begin
            hsync <= h_pol;
        end

        // Generate Vsync
        if (c_ver < v_pixels + v_fp || c_ver > v_pixels + v_fp + v_pulse) begin
            vsync <= ~v_pol;
        end
        else begin
            vsync <= v_pol;
        end

        if (c_hor <= h_pixels && c_ver < v_pixels) begin
            if (c_hor[3:0] == 4'b1111) begin
                cur_bitmap <= next_bitmap;
                cur_char <= next_char;
                cur_color <= next_color;
                vstate <= 0;
            end
            else if (vstate[0] == 0 && (cpurd || cpuwr)) begin
                cstate <= cstate + 2'b01;
            end
            else begin
                case(vstate)
                    4'b0001: next_char <= vdata;
                    4'b0011: next_color <= vdata;
                    4'b0101: next_bitmap <= vdata;
                endcase
                vstate <= vstate + 4'b0001;
            end
        end
        else begin
            cstate <= cstate + 2'b01;
        end

        if (c_hor >= leader && c_hor < h_pixels+leader && c_ver < v_pixels) begin
            color <= cur_bitmap[3'b111 - c_hor[3:1]] ? cur_color[3:0] : cur_color[7:4];
        end
        else begin
            color <= 0;
        end
    end
end
endmodule
