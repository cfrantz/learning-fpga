# A simple computer using cpu6502

`machine1` is a simple computer based around cpu6502.  This machine
can be synthesized into a Lattice HX8K FPGA using about 1500 logic cells
(approximately 20% of the total).

Memory map:

- `$0000` to `$0FFF`: RAM.
- `$C000` to `$C003`: Simple UART fixed at 9600 baud.
- `$C004`: Demo board LEDs.
- `$F000` to `$FFFF`: More RAM and the EWOZ monitor program at `$FC00`.

## Tiny Basic

You can build the `:machine1-basic` target which will boot into a TinyBasic
interpreter.

TinyBasic doesn't have built-in `PEEK` and `POKE`.  You can access the
peek and poke assembly routines at `$F017` and `$F01B` respectively (e.g.
decimal 61463 and 61467).

The following will write the value 2 to the LED bank on the HX8K demo board:

```
A = USR(61467,49156,2)
```
