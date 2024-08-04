//-------------------------------------------------------
// test.v
// Max Yi (byyi@hmc.edu) and David_Harris@hmc.edu 12/9/03
// Model of subset of MIPS processor described in Ch 1
//
// Matsutani: SDF annotation is added
//-------------------------------------------------------
`timescale 1ns/10ps

module test;
  reg clk, rst;
  // 10nsec --> 100MHz
  parameter STEP = 10.0;
  // instantiate devices to be tested
  top top(clk, rst);
  // initialize test
  initial begin
`ifdef __POST_PR__
    $sdf_annotate("mips.sdf", test.top, , "sdf.log", "MAXIMUM");
`endif
    // dump waveform
    $dumpfile("dump.vcd");
    $dumpvars(0, test.top);
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
    if (top.w_en_by_cpu) begin
      $display("Data [%d] is stored in Address [%d]", top.w_en_by_cpu, top.addr_by_cpu);
      if (top.addr_by_cpu == 5 & top.w_by_cpu == 7)
        $display("Simulation completely successful");
      else
      $display("Simulation failed");
      $finish;
    end
  end
endmodule
