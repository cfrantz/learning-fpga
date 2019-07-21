`define STRINGIFY(x) `"x`"
`ifdef DIE_ON_ASSERT
`define DIE $finish_and_return(1);
`else
`define DIE
`endif
`define VCDOUT {`__FILE__, "cd"}
`define ASSERT_AT(count_, cond_) \
    if (count_ == counter && (cond_) != 1) \
    begin \
        $display("[%s, %d] Assertion failed: %s", \
                 `__FILE__, `__LINE__, `STRINGIFY(cond_)); \
        `DIE \
    end

module test;

reg clk = 0;
reg rx = 1;
wire tx;
wire [7:0] leds;

machine1 m(clk, rx, tx,
    leds[0],
    leds[1],
    leds[2],
    leds[3],
    leds[4],
    leds[5],
    leds[6],
    leds[7]);

initial begin
    $dumpfile(`VCDOUT);
    $dumpvars(0, test);
    # 2000 $finish;
end

always #1
begin
    clk = !clk;

    // Load timestamps are at the end of phi2 (falling edge of clk2)
    // Store timestamps are at the begin of phi2 (rising edge of clk2)


end
endmodule
