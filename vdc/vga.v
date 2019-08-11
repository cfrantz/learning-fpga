// Create a simple VGA output
module vga (input CLK12MHz,
            input phi2,
            input reset,
            input ce,
            input rw,
            input [7:0] idata,
            input [13:0] addr,
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

wire vga_clk2x;
reg vga_clk = 0;
SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"),
        .DIVR(4'b0000),
        .DIVF(7'b1000010),
        .DIVQ(3'b100),
        .FILTER_RANGE(3'b001)
    ) uut (
        .RESETB(1'b1),
        .BYPASS(1'b0),
        .REFERENCECLK(CLK12MHz),
        .PLLOUTCORE(vga_clk2x));

// Video color and sync registers
reg [9:0] c_hor = 0;            // Complete frame register column
reg [9:0] c_ver = 0;            // Complete frame register row

reg [7:0] next_char;
reg [7:0] next_color;
reg [7:0] next_bitmap;
reg [7:0] cur_char;
reg [7:0] cur_color;
reg [7:0] cur_bitmap = 8'h0f;

wire [13:0] vaddr;
wire [7:0] vdata;
reg [3:0] vstate;

assign vaddr =  (vstate[3:1] == 3'b000) ?  {4'b0000, c_ver[8:4], c_hor[8:4]} :
                (vstate[3:1] == 3'b001) ?  {4'b0001, c_ver[8:4], c_hor[8:4]} :
                (vstate[3:1] == 3'b010) ?  {3'b001, next_char, c_ver[3:1]} : 0;

vram vram0(
    .clk2x(vga_clk2x),
    .addr_a(addr),
    .wdata_a(idata),
    .cs_a(ce),
    .rw_a(rw),
    .rdata_a(odata),

    .addr_b(vaddr),
    .wdata_b(8'b0),
    .cs_b(1'b1),
    .rw_b(1'b1),
    .rdata_b(vdata));

always @(posedge vga_clk2x) begin
    vga_clk = ~vga_clk;
end

always @(posedge vga_clk) begin

    if (reset) begin
        c_hor <= 0;
        c_ver <= 0;
        hsync <= ~h_pol;
        vsync <= ~v_pol;
        vstate <= 0;
    end
    else begin
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
            else begin
                case(vstate)
                    4'b0001: next_char <= vdata;
                    4'b0011: next_color <= vdata;
                    4'b0101: next_bitmap <= vdata;
                endcase
                vstate <= vstate + 4'b0001;
            end
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
