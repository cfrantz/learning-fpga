// Simple UART
// Based on https://opencores.org/projects/osdvu
//

module uart(
    input clk,
    input rst,
    input rx_line,
    output reg tx_line,
    input cs,
    input [1:0] addr,
    input rw,
    input [7:0] idata,
    output wire [7:0] odata);

parameter CLOCK_DIVIDE = 312;
//parameter CLOCK_DIVIDE = 1;

parameter RX_IDLE          = 0;
parameter RX_CHECK_START   = 1;
parameter RX_READ_BITS     = 2;
parameter RX_CHECK_STOP    = 3;
parameter RX_DELAY_RESTART = 4;
parameter RX_ERROR         = 5;
parameter RX_RECEIVED      = 6;

parameter TX_IDLE          = 0;
parameter TX_SENDING       = 1;
parameter TX_DELAY_RESTART = 2;

reg [10:0] rx_clk_divider = CLOCK_DIVIDE;
reg [10:0] tx_clk_divider = CLOCK_DIVIDE;

reg [2:0] rx_state = RX_IDLE;
reg [5:0] rx_countdown;
reg [3:0] rx_bits_remaining;
reg [7:0] rx_data = 0;
reg rx_ready = 0;

reg [2:0] tx_state = TX_IDLE;
reg [5:0] tx_countdown;
reg [3:0] tx_bits_remaining;
reg [7:0] tx_data = 0;
reg [7:0] tx_data_reg = 0;
reg tx_data_ready = 0;
reg tx_busy = 0;

// The register interace has four 8-bit registers:
// addr | name      | read              | write
// -----|-----------|-------------------|-------------------------
//    0 | tx data   | transmitter state | data to transmit
//    1 | tx status | b7 = busy         | n/a
//    2 | rx data   | received data     | n/a
//    3 | rx status | b7 = ready        | clear (write any value)
assign odata = ~cs ? 8'bz :
    addr == 2'b00 ? tx_data :
    addr == 2'b01 ? {tx_busy, 7'b0} :
    addr == 2'b10 ? rx_data :
                    {rx_ready, 7'b0} ;

always @(posedge clk)
begin
    if (rst)
    begin
        rx_state = RX_IDLE;
        tx_state = TX_IDLE;
        tx_busy <= 0;
        rx_ready <= 0;
    end


    if (cs && !rw)
    begin
        case (addr)
            2'b00:
                if (!tx_busy)
                begin
                    tx_data_reg = idata;
                    tx_data_ready = 1;
                end
            2'b11:
                rx_ready <= 0;
        endcase
    end

    rx_clk_divider = rx_clk_divider - 1;
    if (rx_clk_divider == 0)
    begin
        rx_clk_divider = CLOCK_DIVIDE;
        rx_countdown = rx_countdown - 1;
    end
    tx_clk_divider = tx_clk_divider - 1;
    if (tx_clk_divider == 0)
    begin
        tx_clk_divider = CLOCK_DIVIDE;
        tx_countdown = tx_countdown - 1;
    end

    case(rx_state)
        RX_IDLE:
        begin
            if (!rx_line)
            begin
                rx_clk_divider = CLOCK_DIVIDE;
                rx_countdown = 2;
                rx_state = RX_CHECK_START;
            end
        end
        RX_CHECK_START:
        begin
            if (!rx_countdown)
            begin
                if (!rx_line)
                begin
                    rx_countdown = 4;
                    rx_bits_remaining = 8;
                    rx_state = RX_READ_BITS;
                end
                else
                begin
                    rx_state = RX_ERROR;
                end
            end
        end
        RX_READ_BITS:
        begin
            if (!rx_countdown)
            begin
                rx_data = {rx_line, rx_data[7:1]};
                rx_countdown = 4;
                rx_bits_remaining = rx_bits_remaining - 1;
                rx_state = rx_bits_remaining ? RX_READ_BITS : RX_CHECK_STOP;
            end
        end
        RX_CHECK_STOP:
        begin
            if (!rx_countdown)
            begin
                rx_state = rx_line ? RX_RECEIVED : RX_ERROR;
            end
        end
        RX_ERROR:
        begin
            rx_countdown = 8;
            rx_state = RX_DELAY_RESTART;
        end
        RX_DELAY_RESTART:
        begin
            if (!rx_countdown)
                rx_state = RX_IDLE;
        end
        RX_RECEIVED:
        begin
            rx_state = RX_IDLE;
            rx_ready <= 1'b1;
        end
    endcase

    case (tx_state)
        TX_IDLE:
        begin
            if (tx_data_ready)
            begin
                tx_clk_divider = CLOCK_DIVIDE;
                tx_countdown = 4;
                tx_line = 0;
                tx_bits_remaining = 8;
                tx_state = TX_SENDING;
                tx_busy = 1;
                tx_data = tx_data_reg;
            end
        end
        TX_SENDING:
        begin
            if (!tx_countdown)
            begin
                if (tx_bits_remaining)
                begin
                    tx_bits_remaining = tx_bits_remaining - 1;
                    tx_line = tx_data[0];
                    tx_data = {1'b0, tx_data[7:1]};
                    tx_countdown = 4;
                end
                else
                begin
                    tx_line = 1'b1;
                    tx_countdown = 8;
                    tx_state = TX_DELAY_RESTART;
                end
            end
        end
        TX_DELAY_RESTART:
        begin
            tx_data_ready = 0;
            if (!tx_countdown)
            begin
                tx_busy = 0;
                tx_state = TX_IDLE;
            end
        end
    endcase
end
endmodule
