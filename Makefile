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

MODEL = /home/cad/lib/NANGATE45/cells.v
SCRIPT = nangate45
#MODEL = /home/cad/lib/TSMC16/cells.v
#SCRIPT = tsmc16

ex1:
	ncverilog +access+r test.v mips32.v
ex2:
	ncverilog +access+r fib.v mips32.v
ex3:
	ncverilog +access+r dma.v mips32.v
syn:
	dc_shell -f ${SCRIPT}/syn.tcl | tee syn.log
par:
	innovus -init ${SCRIPT}/par.tcl | tee par.log
sta:
	dc_shell -f ${SCRIPT}/sta.tcl | tee sta.log
dsim:
	ncverilog +define+__POST_PR__ +access+r -v ${MODEL} test/dma.v mips.final.vnet | tee dsim.log
saif:
	vcd2saif -input dump.vcd -output mips.saif
power:
	vcd2saif -input dump.vcd -output mips.saif
	dc_shell -f ${SCRIPT}/power.tcl | tee power.log

clean:
	rm -rf a.out dump.vcd *.dat gate.v
