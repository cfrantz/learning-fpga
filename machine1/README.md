# A simple computer using cpu6502

`machine1` is a simple computer based around cpu6502.  This machine
can be synthesized into a Lattice HX8K FPGA using about 1500 logic cells
(approximately 20% of the total).

Memory map:

- `$0000` to `$0FFF`: RAM.
- `$C000` to `$C003`: Simple UART fixed at 9600 baud.
- `$F000` to `$FFFF`: More RAM and the EWOZ monitor program at `$FC00`.
