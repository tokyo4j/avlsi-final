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
    $dumpvars(0, top.top);
    // reset
    clk <= 0; rst <= 1; #(STEP*10); rst <= 0;
    // stop at 1,000 cycles
    #(STEP*1000);
    $display("Simulation failed");
    $finish;
  end
  reg [7:0] prev_addr;
  always #(STEP / 2)
    clk <= ~clk;
  always @(negedge clk) begin
    prev_addr <= top.addr_by_cpu;
    if (prev_addr == 255 && top.r_by_cpu == 1) begin
      $display("%d %d %d %d %d %d %d %d",
               top.sram0.RAM[(128/4)+0][31:24], top.sram0.RAM[(128/4)+0][23:16],
               top.sram0.RAM[(128/4)+0][15:8],  top.sram0.RAM[(128/4)+0][7:0],
               top.sram0.RAM[(128/4)+1][31:24], top.sram0.RAM[(128/4)+1][23:16],
               top.sram0.RAM[(128/4)+1][15:8],  top.sram0.RAM[(128/4)+1][7:0]);
      $display("%d %d %d %d %d %d %d %d",
               top.sram0.RAM[(192/4)+0][31:24], top.sram0.RAM[(192/4)+0][23:16],
               top.sram0.RAM[(192/4)+0][15:8],  top.sram0.RAM[(192/4)+0][7:0],
               top.sram0.RAM[(192/4)+1][31:24], top.sram0.RAM[(192/4)+1][23:16],
               top.sram0.RAM[(192/4)+1][15:8],  top.sram0.RAM[(192/4)+1][7:0]);
      $display("eop is asserted");
      $finish;
    end
  end
endmodule
