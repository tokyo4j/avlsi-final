`define BGRT0 0
`define BGRT1 1

module busarb (
    input breq0, input breq1,
    output bgrt0, output bgrt1,
    input clk, rst
);
  reg state;
  assign bgrt0 = (breq0 && state == `BGRT0);
  assign bgrt1 = (breq1 && state == `BGRT1);
  always @(posedge clk)
    if (rst) begin
      state <= `BGRT0;
    end else begin
      case (state)
      `BGRT0:
        if (!breq0 && breq1)
          state <= `BGRT1;
      `BGRT1:
        if (!breq1 && breq0)
          state <= `BGRT0;
      endcase
    end
endmodule
