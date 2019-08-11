# A simple computer using cpu6502

`machine3` is a simple computer based around cpu6502.  Unlike machine1 and 2,
machine3 expects to interface with an external 128K SRAM and implements a
simple memory mapper to provide bank switching.

Memory map:

- `$00000` to `$1FFFF`: RAM.
- `$FA000` to `$FAFFF`: Character mapped framebuffer and CHAR ram.
- `$FC000` to `$FC003`: Simple UART fixed at 9600 baud.
- `$FC100` to `$FC13F`: Registers for the VDC.
- `$FF000` to `$FFFFF`: More RAM and the EWOZ monitor program at `$FC00`.

