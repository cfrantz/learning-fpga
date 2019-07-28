// Create a simple VGA output
module vga (input CLK12MHz,
            input phi2,
            input reset,
            input ce,
            input rw,
            input [7:0] idata,
            input [11:0] addr,
            output reg [7:0] odata,
            output reg [3:0] color,
            output reg hsync,
            output reg vsync);

// The normal dotclock for VGA is 25.175 MHz.  The OLIMEX HX8K board has a
// 100 Mhz oscillator and divides this by 4 to get a 25Mhz clock.
// Since I'm after a more primitive low-res display, I've derived my timing
// numbers based on the 640x480, but I'm only after 256x240.

// I've pushed front porch/back porch by 8 pixels so that c_hor will lead
// the beam position by 8-pixels.  This allows easier prefetching of char,
// color and chr-rom data one character cell ahead of time.

parameter h_pulse = 46;     // H-sync pulse = 3.83us
parameter h_bp = 23+24-8;     // back porch pulse width
parameter h_pixels = 256;   // Number of horizontal pixels
parameter h_fp = 6+24+8;      // front porch pulse width
parameter h_pol = 1'b0;     // hsync polarity
parameter h_frame = 379;    // Total horizontal frame (46+48+256+31)

parameter v_pulse = 2;      // v-sync pulse width
parameter v_bp = 33;        // back porch pulse width
parameter v_pixels = 480;   // number of vertical pixels
parameter v_fp = 10;        // front porch width
parameter v_pol = 1'b1;     // vsync polarity
parameter v_frame = 525;    // Total vertical frame (2+33+480+10)

wire vga_clk = CLK12MHz;

// Video color and sync registers
reg [9:0] c_hor = 0;            // Complete frame register column
reg [9:0] c_ver = 0;            // Complete frame register row
reg [7:0] pix_x = 0;            // visible pixel coordinate
reg [7:0] pix_y = 0;            // visible pixel coordinate

reg [7:0] next_char;
reg [7:0] next_color;
reg [7:0] next_bitmap;
reg [7:0] cur_char;
reg [7:0] cur_color;
reg [7:0] cur_bitmap = 8'h0f;

reg [7:0] vram[0:4095];
initial
begin
`include "vdc/vram_init.vh"
end

always @(posedge vga_clk) begin

    if (reset) begin
        c_hor <= 0;
        c_ver <= 0;
        pix_x <= 0;
        pix_y <= 0;
        hsync <= ~h_pol;
        vsync <= ~v_pol;
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

        // Update pixel position if inside the visible portion of the display
        if (c_hor < h_pixels + 8) begin
            pix_x <= c_hor;
        end
        if (c_ver < v_pixels) begin
            pix_y <= c_ver[8:1];
        end

        if (c_hor <= h_pixels && c_ver < v_pixels) begin
            case(pix_x[2:0])
                3'b000: 
                    next_char <= vram[{2'b00, pix_y[7:3], pix_x[7:3]}];
                3'b001: 
                    ;
                3'b010:
                    ;
                3'b011:
                    ;
                3'b100:
                    next_color <= vram[{2'b01, pix_y[7:3], pix_x[7:3]}];
                3'b101:
                    ;
                3'b110:
                    ;
                3'b111:
                begin
                    cur_bitmap <= vram[{1'b1, next_char, pix_y[2:0]}];
                    cur_char <= next_char;
                    cur_color <= next_color;
                end
            endcase
        end
        if (c_hor >= 8 && c_hor < h_pixels+8 && c_ver < v_pixels) begin
            color <= cur_bitmap[3'b111 - pix_x[2:0]] ? cur_color[3:0] : cur_color[7:4];
            //color <= cur_color[3:0];
        end
        else begin
            color <= 0;
        end
    end
end
endmodule
