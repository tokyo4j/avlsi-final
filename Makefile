test:	mips.v test.v test.dat
	iverilog test.v mips.v
	vvp a.out

fib: mips.v fib.v fib.dat
	iverilog fib.v mips.v
	vvp a.out

sum: mips.v sum.v sum.dat
	iverilog sum.v mips.v
	vvp a.out

byte: mips.v byte.v byte.dat
	iverilog byte.v mips.v
	vvp a.out

yosys:
	yosys mips.ys

sim:
	iverilog -gspecify -T max test.v gate.v lib/osu018_stdcells.v

%.dat: %.asm
	./asm.pl $<

clean:
	rm -f a.out dump.vcd *.dat
