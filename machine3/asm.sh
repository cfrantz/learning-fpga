#!/bin/bash

#/usr/local/cc65/bin/ca65 --listing tinybasic.lst tinybasic.asm
#/usr/local/cc65/bin/ld65 -C machine3.cfg -vm --mapfile tinybasic.map -o tinybasic.bin tinybasic.o
#python ../cpu6502/tests/functional/t.py tinybasic.bin >basic_ram.vh


/usr/local/cc65/bin/ca65 --listing ewoz.lst ewoz.asm
/usr/local/cc65/bin/ld65 -C machine3.cfg -vm --mapfile ewoz.map -o ewoz.bin ewoz.o
python ../cpu6502/tests/functional/t.py ewoz.bin >ewoz_ram.vh

