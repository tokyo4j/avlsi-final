module top(
    input clk, rst
);
  mips mips(i_addr_by_cpu, i_by_cpu,
            addr_by_cpu, r_by_cpu, w_by_cpu, w_en_by_cpu,
            clk, rst);
  // 0xfc-0xff is mapped to DMAC's control registers
  wire access_is_dmac = (addr_by_cpu[7:2] == 6'b111111);

  // if cpu is accessing sram (TODO: refactor this)
  wire breq_cpu = (mips.ma_op == 3'b101 || mips.ma_op == 3'b110)
                  && !access_is_dmac;
  wire breq_dmac;

  // CPU IO
  // CPU->SRAM/DMAC
  wire [7:0] r_by_cpu = (bgrt_cpu) ? r_to_sram : r_to_dmac;
  wire [7:0] w_by_cpu, addr_by_cpu;
  wire [31:0] i_by_cpu;
  wire [7:0] i_addr_by_cpu;
  wire w_en_by_cpu;

  // DMAC IO
  // CPU->DMAC
  wire [7:0] w_to_dmac = w_by_cpu;
  wire w_en_to_dmac = w_en_by_cpu && access_is_dmac;
  wire [1:0] addr_to_dmac = addr_by_cpu[1:0];
  wire [7:0] r_to_dmac;
  // DMAC->SRAM
  wire [7:0] r_by_dmac = (bgrt_dmac) ? r_to_sram : 0;
  wire [7:0] w_by_dmac, addr_by_dmac;
  wire w_en_by_dmac;

  // SRAM IO
  // CPU/DMAC->SRAM
  wire [7:0] w_to_sram = (bgrt_cpu)  ? w_by_cpu :
                         (bgrt_dmac) ? w_by_dmac : 0;
  wire w_en_to_sram = ((bgrt_cpu && w_en_by_cpu) ||
                       (bgrt_dmac && w_en_by_dmac));
  wire [7:0] addr_to_sram = (bgrt_cpu)  ? addr_by_cpu :
                            (bgrt_dmac) ? addr_by_dmac : 0;
  wire [7:0] r_to_sram;

  busarb busarb(breq_cpu, breq_dmac, bgrt_cpu, bgrt_dmac, clk, rst);

  sram sram(i_addr_by_cpu, i_by_cpu,
            addr_to_sram, r_to_sram, w_to_sram, w_en_to_sram,
            clk);
  dmac dmac(addr_by_dmac, r_by_dmac, w_by_dmac, w_en_by_dmac,
            bgrt_dmac, breq_dmac,
            addr_to_dmac, r_to_dmac, w_to_dmac, w_en_to_dmac,
            clk, rst);
endmodule
