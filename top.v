module top(
    input clk, rst
);
  wire access_is_dmac;
  wire breq_cpu_raw;
  wire breq_cpu, breq_dmac, bgrt_cpu, bgrt_dmac;

  // CPU IO
  // CPU->SRAM/DMAC
  wire [7:0] r_by_cpu;
  wire [7:0] w_by_cpu, addr_by_cpu;
  wire [31:0] i_by_cpu;
  wire [7:0] i_addr_by_cpu;
  wire w_en_by_cpu;

  // DMAC IO
  // CPU->DMAC
  wire [7:0] w_to_dmac;
  wire w_en_to_dmac;
  wire [1:0] addr_to_dmac;
  wire [7:0] r_to_dmac;
  // DMAC->SRAM
  wire [7:0] r_by_dmac;
  wire [7:0] w_by_dmac, addr_by_dmac;
  wire w_en_by_dmac;

  // SRAM IO
  // CPU/DMAC->SRAM
  wire [7:0] w_to_sram;
  wire w_en_to_sram;
  wire [7:0] addr_to_sram;
  wire [7:0] r_to_sram;


  mips mips0(i_addr_by_cpu, i_by_cpu,
            addr_by_cpu, r_by_cpu, w_by_cpu, w_en_by_cpu, breq_cpu_raw,
            clk, rst);
  // 0xfc-0xff is mapped to DMAC's control registers
  assign access_is_dmac = (addr_by_cpu[7:2] == 6'b111111);

  // if cpu is accessing sram (TODO: refactor this)
  assign breq_cpu = breq_cpu_raw && !access_is_dmac;

  // CPU IO
  // CPU->SRAM/DMAC
  assign r_by_cpu = (bgrt_cpu) ? r_to_sram : r_to_dmac;

  // DMAC IO
  // CPU->DMAC
  assign w_to_dmac = w_by_cpu;
  assign w_en_to_dmac = w_en_by_cpu && access_is_dmac;
  assign addr_to_dmac = addr_by_cpu[1:0];
  // DMAC->SRAM
  assign r_by_dmac = (bgrt_dmac) ? r_to_sram : 0;

  // SRAM IO
  // CPU/DMAC->SRAM
  assign w_to_sram = (bgrt_cpu)  ? w_by_cpu :
                         (bgrt_dmac) ? w_by_dmac : 0;
  assign w_en_to_sram = ((bgrt_cpu && w_en_by_cpu) ||
                       (bgrt_dmac && w_en_by_dmac));
  assign addr_to_sram = (bgrt_cpu)  ? addr_by_cpu :
                            (bgrt_dmac) ? addr_by_dmac : 0;

  busarb busarb0(breq_cpu, breq_dmac, bgrt_cpu, bgrt_dmac, clk, rst);

  sram sram0(i_addr_by_cpu, i_by_cpu,
            addr_to_sram, r_to_sram, w_to_sram, w_en_to_sram,
            clk);
  dmac dmac0(addr_by_dmac, r_by_dmac, w_by_dmac, w_en_by_dmac,
            bgrt_dmac, breq_dmac,
            addr_to_dmac, r_to_dmac, w_to_dmac, w_en_to_dmac,
            clk, rst);
endmodule
