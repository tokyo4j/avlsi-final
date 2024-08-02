test:	top.v mips.v sram.v dmac.v busarb.v test/test.v test/test.dat
	iverilog -DMEM_FILE_NAME=\"test/test.dat\" test/test.v mips.v sram.v dmac.v busarb.v top.v
	vvp a.out

dma: top.v mips.v sram.v dmac.v busarb.v test/dma.v test/dma.dat
	iverilog -DMEM_FILE_NAME=\"test/dma.dat\" test/dma.v mips.v sram.v dmac.v busarb.v top.v
	vvp a.out

fib: mips.v test/fib.v test/fib.dat
	iverilog test/fib.v mips.v
	vvp a.out

byte: mips.v test/byte.v test/byte.dat
	iverilog test/byte.v mips.v
	vvp a.out

yosys:
	yosys mips.ys

sim:
	iverilog -gspecify -T max test/test.v gate.v lib/osu018_stdcells.v

test/%.dat: test/%.asm
	test/asm.pl $<

clean:
	rm -f a.out dump.vcd *.dat
