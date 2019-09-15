# Adjust the run address to match the .org in the source code
all: basic.hex

basic.hex: basic.bin
	hexdump -vC basic.bin | cut -c11-58 >basic.hex

basic.bin: basic.o
	ld65 -C machine3.cfg -vm -m basic.map -o basic.bin basic.o

basic.o: basic.asm min_mon.asm chrset.asm video.asm
	ca65 -g -l min_mon.lst --feature labels_without_colons -o basic.o \
		min_mon.asm

clean:
	$(RM) *.o *.lst *.map *.bin

distclean: clean
