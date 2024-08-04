module sram (
    input [7:0] i_addr,
    output reg [31:0] ins,

    input [7:0] rw_addr,
    output reg [7:0] r,
    input [7:0] w,

    input w_en,
    input clk
);
  reg [31:0] RAM [(1<<6)-1:0];
  wire [31:0] word;
  integer i;
`ifdef MEM_FILE_NAME
  initial begin
    for (i = 0; i < (1<<6); i = i + 1)
      RAM[i] = 0;
    $readmemh(`MEM_FILE_NAME, RAM);
  end
`endif
  // read and write bytes from 32-bit word
  assign word = RAM[rw_addr>>2];
  always @(posedge clk) begin
    if (w_en)
      case (rw_addr[1:0])
      2'b00: RAM[rw_addr>>2][31:24] <= w;
      2'b01: RAM[rw_addr>>2][23:16] <= w;
      2'b10: RAM[rw_addr>>2][15:8]  <= w;
      2'b11: RAM[rw_addr>>2][7:0]   <= w;
      endcase
    ins <= RAM[i_addr >> 2];
    case (rw_addr[1:0])
    2'b00: r <= word[31:24];
    2'b01: r <= word[23:16];
    2'b10: r <= word[15:8];
    2'b11: r <= word[7:0];
    endcase
  end
endmodule
