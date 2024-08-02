//-------------------------------------------------------
// test.v
// Max Yi (byyi@hmc.edu) and David_Harris@hmc.edu 12/9/03
// Model of subset of MIPS processor described in Ch 1
//
// Matsutani: SDF annotation is added
//-------------------------------------------------------
`timescale 1ns/10ps

`define MEM_FILE_NAME "test/test.dat"
`include "test/exmemory.v"

/* top level design for testing */
module top;
  reg clk, rst;
  wire w_en, i_en;
  wire [31:0] i;
  wire [7:0] r, w, i_addr, rw_addr;
  // 10nsec --> 100MHz
  parameter STEP = 10.0;
  // instantiate devices to be tested
  mips dut(i_addr, i,
           rw_addr, r, w, w_en,
           clk, rst);
  // external memory for code and data
  exmemory exmem(i_addr, i,
                 rw_addr, r, w, w_en,
                 clk);
  // initialize test
  initial begin
`ifdef __POST_PR__
    $sdf_annotate("mips.sdf", top.dut, , "sdf.log", "MAXIMUM");
`endif
    // dump waveform
    $dumpfile("dump.vcd");
    $dumpvars(0, top.dut);
    // reset
    clk <= 0; rst <= 1; #(STEP*10); rst <= 0;
    // stop at 1,000 cycles
    #(STEP*1000);
    $display("Simulation failed");
    $finish;
  end
  // generate clock to sequence tests
  always #(STEP / 2)
    clk <= ~clk;
  always @(negedge clk) begin
    if (w_en) begin
      $display("Data [%d] is stored in Address [%d]", w, rw_addr);
      if (rw_addr == 5 & w == 7)
        $display("Simulation completely successful");
      else
      $display("Simulation failed");
      $finish;
    end
  end
endmodule
