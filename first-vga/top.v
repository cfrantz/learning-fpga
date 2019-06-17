// Create a simple VGA output
/* module */
module top (CLK12MHz,
            vga_r,
            vga_g,
            vga_b,
            vga_hs,
            vga_vs);

input CLK12MHz;  // The axelsys HX8K board has a 12MHz Oscillator.
output [2:0] vga_r;
output [2:0] vga_g;
output [2:0] vga_b;
output vga_hs;
output vga_vs;

// The normal dotclock for VGA is 25.175 MHz.  The OLIMEX HX8K board has a
// 100 Mhz oscillator and divides this by 4 to get a 25Mhz clock.
// Since I'm after a more primitive low-res display, I've derived my timing
// numbers based on the 640x480, but I'm only after 256x240.

parameter h_pulse = 46;     // H-sync pulse = 3.83us
parameter h_bp = 23+25;     // back porch pulse width
parameter h_pixels = 256;   // Number of horizontal pixels
parameter h_fp = 6+25;      // front porch pulse width
parameter h_pol = 1'b0;     // hsync polarity
parameter h_frame = 381;    // Total horizontal frame (46+48+256+31)

parameter v_pulse = 2;      // v-sync pulse width
parameter v_bp = 33;        // back porch pulse width
parameter v_pixels = 480;   // number of vertical pixels
parameter v_fp = 10;        // front porch width
parameter v_pol = 1'b1;     // vsync polarity
parameter v_frame = 525;    // Total vertical frame (2+33+480+10)

wire vga_clk = CLK12MHz;

// Video color and sync registers
reg [2:0] out_r;
reg [2:0] out_g;
reg [2:0] out_b;
reg       out_hs;
reg       out_vs;

// Assign to the output signals
assign vga_r = out_r;
assign vga_g = out_g;
assign vga_b = out_b;
assign vga_hs = out_hs;
assign vga_vs = out_vs;

reg reset = 1;
reg [7:0] rtimer = 8'b0;
reg [9:0] c_hor;            // Complete frame register column
reg [9:0] c_ver;            // Complete frame register row
reg [9:0] pix_x;            // visible pixel coordinate
reg [9:0] pix_y;            // visible pixel coordinate
reg disp_en;                // display on

always @(posedge vga_clk) begin

    // Generate 10us of reset
    if (rtimer > 120) begin
        reset <= 0;
    end
    else begin
        rtimer <= rtimer + 1;
        reset <= 1;
        disp_en <= 0;
    end

    if (reset == 1) begin
        c_row <= 0;
        c_col <= 0;
        pix_x <= 0;
        pix_y <= 0;
        out_hs <= 1;
        out_vs <= 0;
    end
    else begin
        // Update beam position 
        if (c_hor < h_frame - 1) begin
            c_hor <= c_hor + 1;
        end
        else begin
            c_hor <= 0;
            if (c_ver < v_frame - 1) begin
                c_ver <= c_ver + 1;
            end
            else begin
                c_ver <= 0;
            end
        end

        // Generate Hsync
        if (c_hor < h_pixels + h_fp || c_hor > h_pixels + h_fp + h_pulse) begin
            out_hs <= ~h_pol;
        end
        else begin
            out_hs <= h_pol;
        end

        // Generate Vsync
        if (c_ver < v_pixels + v_fp || c_ver > v_pixels + v_fp + v_pulse) begin
            out_vs <= ~v_pol;
        end
        else begin
            out_vs <= v_pol;
        end

        // Update pixel position if inside the visible portion of the display
        if (c_hor < h_pixels) begin
            pix_x <= c_hor;
        end
        if (c_ver < v_pixels) begin
            pix_y <= c_ver;
        end

        // Display enable
        if (c_hor < h_pixels && c_ver < v_pixels) begin
            disp_en <= 1;
        end
        else begin
            disp_en <= 0;
        end

        if (disp_en) begin
            out_b <= pix_x[5:3];
            out_r <= pix_y[5:3];
            out_g[1:0] <= pix_x[7:6];
            out_g[2] <= pix_y[7];
        end
        else begin
            out_r <= 0;
            out_g <= 0;
            out_b <= 0;
        end
    end
end
endmodule
