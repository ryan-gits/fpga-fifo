all:
	rm -rf wave.vcd
	iverilog -s fifo_tb -g2012 -o fifo.icarus tb/fifo_tb.sv src/fifo.sv src/bram.sv
	vvp fifo.icarus

waves:
	gtkwave dump.vcd -a waves.gtkw
