# A simple computer using cpu6502

`machine3` is a simple computer based around cpu6502.  Unlike machine1 and 2,
machine3 expects to interface with an external 128K SRAM and implements a
simple memory mapper to provide bank switching.

Memory map:

- `$FFE0` to `$FFEF`: Memory mapper bank controls.
- `$00000` to `$1FFFF`: RAM.
- `$FC000` to `$FCFFF`: Character mapped framebuffer and CHAR ram.
- `$FB000` to `$FB003`: Simple UART fixed at 9600 baud.
- `$FB100` to `$FB13F`: Registers for the VDC.
- `$FF000` to `$FFFFF`: More RAM and the EWOZ monitor program at `$FC00`.

## Mapper

The memory mapper has 16 one-byte registers which control the mapping of
each 4KB page in cpu address space to pages in the 1MB absolute address space.
Regardless of the memory mapping, the mapper registers always appear at
`$FFE0`.

CPU addresses are expanded by selecting a register based on cpuaddr[15:12]
and driving the register content onto the address bus in bits 19-12, thus
creating a mapping of 4KB pages into a 1MB address space.

