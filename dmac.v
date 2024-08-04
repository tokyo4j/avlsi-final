`define DSTATE_WAIT  2'b00
`define DSTATE_READ  2'b01
`define DSTATE_WRITE 2'b10
`define DSTATE_END   2'b11

module dmac(
    // RAM access
    output [7:0] ram_rw_addr,
    input [7:0] ram_r,
    output [7:0] ram_w,
    output ram_w_en,

    // Bus access
    input bus_grant,
    output bus_req,

    // MMIO
    input [1:0] rw_addr,
    output reg [7:0] r,
    input [7:0] w,
    input w_en,

    input clk, rst
);
  reg [7:0] size, src_addr, dst_addr;
  reg [1:0] state;
  wire eop, dma_off;
  reg dma_en;
  reg [7:0] count;
  wire [7:0] count_inc;

  always @(posedge clk) begin
    if (w_en)
      case(rw_addr)
      2'b00: src_addr <= w;
      2'b01: dst_addr <= w;
      2'b10: size <= w;
      endcase
    if (w_en && rw_addr == 2'b11)
      dma_en <= w;
    else if (state == `DSTATE_END)
      dma_en <= 0;
    case(rw_addr)
    2'b00: r <= src_addr;
    2'b01: r <= dst_addr;
    2'b10: r <= size;
    2'b11: r <= eop;
    endcase
  end

  assign count_inc = count + 1;

  assign ram_rw_addr = (state == `DSTATE_READ) ? (src_addr + count) :
                       (state == `DSTATE_WRITE) ? (dst_addr + count) : 0;
  assign bus_req = (state == `DSTATE_READ || state == `DSTATE_WRITE);
  assign eop = (state == `DSTATE_END);
  assign ram_w_en = (state == `DSTATE_WRITE);
  assign ram_w = ram_r;

  always @(posedge clk) begin
    if (rst) begin
      state <= `DSTATE_WAIT;
    end else
      case(state)
        `DSTATE_WAIT: begin
          count <= 0;
          if (dma_en) begin
            state <= `DSTATE_READ;
          end
        end
        `DSTATE_READ:
          if (bus_grant) begin
            state <= `DSTATE_WRITE;
          end
        `DSTATE_WRITE: begin
          if (count_inc == size)
            state <= `DSTATE_END;
          else
            state <= `DSTATE_READ;
          count <= count_inc;
        end
        `DSTATE_END: begin
          state <= `DSTATE_WAIT;
        end
      endcase
  end
endmodule
