`timescale 1ns/10ps

`define RAW_OP_CAL  6'b000000
`define RAW_OP_ADDI 6'b001000
`define RAW_OP_BEQ  6'b000100
`define RAW_OP_J    6'b000010
`define RAW_OP_LB   6'b100000
`define RAW_OP_SB   6'b101000

// Shortened ops
`define OP_NOP   3'b000
`define OP_CAL   3'b001
`define OP_ADDI  3'b010
`define OP_BEQ   3'b011
`define OP_J     3'b100
`define OP_LB    3'b101
`define OP_SB    3'b110

`define FUNCT_ADD 6'b100000
`define FUNCT_SUB 6'b100010
`define FUNCT_AND 6'b100100
`define FUNCT_OR  6'b100101
`define FUNCT_SLT 6'b101010

`define ALU_OP_NOP 3'b000
`define ALU_OP_ADD 3'b001
`define ALU_OP_SUB 3'b010
`define ALU_OP_AND 3'b011
`define ALU_OP_OR  3'b100
`define ALU_OP_SLT 3'b101

module alu(
    input [7:0] a, b,
    input [2:0] alu_op,
    output reg [7:0] result
);
  always @(*)
    case (alu_op) // synthesis parallel_case,full_case
    `ALU_OP_ADD: result <= a + b;
    `ALU_OP_SUB: result <= a - b;
    `ALU_OP_AND: result <= a & b;
    `ALU_OP_OR:  result <= a | b;
    `ALU_OP_SLT: result <= a < b;
    `ALU_OP_NOP:;
    endcase
endmodule

module regs(
    input [2:0] r_id_1, r_id_2, w_id,
    input w_en,
    input [7:0] w,
    output [7:0] r_1, r_2,
    input clk, rst
);
  reg [7:0] regfile[7:0];
  always @(posedge clk)
    if (w_en) regfile[w_id] <= w;
  assign r_1 = r_id_1 ? regfile[r_id_1] : 0;
  assign r_2 = r_id_2 ? regfile[r_id_2] : 0;
endmodule

module mips (
    output [7:0] mem_i_addr,
    input [31:0] mem_i,

    output [7:0] mem_rw_addr,
    input [7:0] mem_r,
    output [7:0] mem_w,
    output mem_w_en, breq,

    input clk, rst
);
  // stall/nop control
  wire beq_in_ma, j_in_id, lb_in_ex, if_nop, if_stall, id_nop, ex_nop;
  reg id_if_nop;
  reg [7:0] pc;
  // ID (instruction decode) stage
  wire [2:0] op;
  wire [4:0] rd, rt, rs;
  wire [5:0] funct;
  wire [7:0] imm;
  reg [7:0] id_pc;
  wire [2:0] alu_op;
  wire [2:0] w_id;
  // register IO
  wire [2:0] regs_w_id;
  wire regs_w_en;
  wire [7:0] regs_r_1, regs_r_2, regs_w;
  wire [2:0] regs_r_id_1;
  wire [2:0] regs_r_id_2;
  // EX (execute) stage
  reg [7:0] ex_regs_r_1, ex_regs_r_2, ex_pc, ex_imm;
  reg [2:0] ex_r_id_1, ex_r_id_2, ex_w_id;
  reg [2:0] ex_alu_op, ex_op;
  wire [7:0] ex_regs_r_1_fw, ex_regs_r_2_fw;
  wire [7:0] alu_in_1, alu_in_2, alu_out;
  // MA (memory access) stage
  reg [7:0] ma_alu_out, ma_pc, ma_imm, ma_regs_r_2;
  reg [2:0] ma_op;
  reg [2:0] ma_w_id;
  // WB (write back) stage
  reg [7:0] wb_alu_out;
  reg [2:0] wb_op;
  reg [2:0] wb_w_id;
  // RT (retire) stage
  reg [2:0] rt_w_id;
  reg [7:0] rt_w;

  // BEQ that updates PC in MA
  assign beq_in_ma = (ma_op == `OP_BEQ && ma_alu_out == 0);
  // J in ID
  assign j_in_id = (op == `OP_J);
  // LB whose dest in EX is src in ID
  assign lb_in_ex = (ex_op == `OP_LB && ex_w_id && (ex_w_id == regs_r_id_1 || ex_w_id == regs_r_id_2));

  // BEQ taken in MA stage: pc->updated, IF->nop, ID->nop, EX->nop
  // J in ID stage:         pc->updated, IF->nop
  // LB in EX stage:        pc->stall, IF->stall, ID->nop
  assign if_nop = beq_in_ma || j_in_id;
  assign if_stall = lb_in_ex;
  assign id_nop = beq_in_ma || lb_in_ex;
  assign ex_nop = beq_in_ma;

  always @(posedge clk) begin
    if (rst)
      pc <= 0;
    else if (beq_in_ma)
      pc <= ma_pc + {ma_imm, 2'b00} + 4;
    else if (j_in_id)
      pc <= {imm, 2'b00};
    else if (lb_in_ex)
      /* stall */;
    else
      pc <= pc + 4;
  end

  // IF stage
  assign mem_i_addr = (if_stall) ? id_pc : pc;

  always @(posedge clk) begin
    if (rst) begin
      id_pc <= 0;
      id_if_nop <= 1;
    end else begin
      if(!if_stall)
        id_pc <= pc;
      id_if_nop <= if_nop;
    end
  end

  // ID stage
  function [2:0] decode_op(input [5:0] op);
    case(op) // synthesis parallel_case,full_case
    `RAW_OP_CAL:  decode_op = `OP_CAL;
    `RAW_OP_ADDI: decode_op = `OP_ADDI;
    `RAW_OP_BEQ:  decode_op = `OP_BEQ;
    `RAW_OP_J:    decode_op = `OP_J;
    `RAW_OP_LB:   decode_op = `OP_LB;
    `RAW_OP_SB:   decode_op = `OP_SB;
    default:      decode_op = `OP_NOP;
    endcase
  endfunction

  function [2:0] decode_funct(input [5:0] funct);
    case(funct) // synthesis parallel_case,full_case
    `FUNCT_ADD: decode_funct = `ALU_OP_ADD;
    `FUNCT_SUB: decode_funct = `ALU_OP_SUB;
    `FUNCT_AND: decode_funct = `ALU_OP_AND;
    `FUNCT_OR:  decode_funct = `ALU_OP_OR;
    `FUNCT_SLT: decode_funct = `ALU_OP_SLT;
    default:    decode_funct = `ALU_OP_NOP;
    endcase
  endfunction

  assign op = decode_op(mem_i[31:26]);
  assign rd = mem_i[15:11];
  assign rt = mem_i[20:16];
  assign rs = mem_i[25:21];
  assign funct = mem_i[5:0];
  assign imm = mem_i[7:0];

  assign alu_op = (op == `OP_CAL) ? decode_funct(funct) :
                  (op == `OP_BEQ) ? `ALU_OP_SUB :
                  /* else */        `ALU_OP_ADD;

  // Register input/output
  assign regs_r_id_1 = rs;
  assign regs_r_id_2 = (op == `OP_CAL || op == `OP_BEQ || op == `OP_SB) ? rt : 0;
  assign w_id = (op == `OP_ADDI || op == `OP_LB) ? rt :
                (op == `OP_CAL)                  ? rd : 0;

  regs regs(regs_r_id_1, regs_r_id_2,
            regs_w_id, regs_w_en, regs_w,
            regs_r_1, regs_r_2,
            clk, rst);

  // ID->EX
  always @(posedge clk) begin
    if (rst || op == `OP_NOP || id_if_nop || id_nop) begin
      ex_regs_r_1 <= 0;
      ex_regs_r_2 <= 0;
      ex_imm <= 0;
      ex_alu_op <= 0;
      ex_op <= `OP_NOP;
      ex_r_id_1 <= 0;
      ex_r_id_2 <= 0;
      ex_w_id <= 0;
      ex_pc <= 0;
    end else begin
      ex_regs_r_1 <= regs_r_1;
      ex_regs_r_2 <= regs_r_2;
      ex_imm <= imm;
      ex_alu_op <= alu_op;
      ex_op <= op;
      ex_r_id_1 <= regs_r_id_1;
      ex_r_id_2 <= regs_r_id_2;
      ex_w_id <= w_id;
      ex_pc <= id_pc;
    end
  end

  // EX stage
  assign ex_regs_r_1_fw = (ma_w_id && (ex_r_id_1 == ma_w_id)) ?
                            /* forward MA->EX for CAL instructions (not LB as it's delay from MA by stall) */
                            ma_alu_out :
                          (wb_w_id && (ex_r_id_1 == wb_w_id)) ?
                            /* forward WB->EX for CAL/LB instruction */
                            regs_w :
                          (rt_w_id && (ex_r_id_1 == rt_w_id)) ?
                            /* forward EP->EX for CAL/LB instruction */
                            rt_w :
                          /* else */
                            ex_regs_r_1;
  assign ex_regs_r_2_fw = (ma_w_id && (ex_r_id_2 == ma_w_id)) ?
                            /* forward MA->EX for CAL instructions (not LB as it's delay from MA by stall) */
                            ma_alu_out :
                          (wb_w_id && (ex_r_id_2 == wb_w_id)) ?
                            /* forward WB->EX for CAL/LB instruction */
                            regs_w :
                          (rt_w_id && (ex_r_id_2 == rt_w_id)) ?
                            /* forward EP->EX for CAL/LB instruction */
                            rt_w :
                          /* else */
                            ex_regs_r_2;

  assign alu_in_1 = ex_regs_r_1_fw;
  assign alu_in_2 = (ex_op == `OP_ADDI || ex_op == `OP_LB || ex_op == `OP_SB) ?
                          ex_imm : ex_regs_r_2_fw;
  alu alu(alu_in_1, alu_in_2, ex_alu_op, alu_out);

  // EX->MA
  always @(posedge clk) begin
    if (rst || ex_op == `OP_NOP || ex_nop) begin
      ma_alu_out <= 0;
      ma_op <= `OP_NOP;
      ma_w_id <= 0;
      ma_pc <= 0;
      ma_imm <= 0;
      ma_regs_r_2 <= 0;
    end else begin
      ma_alu_out <= alu_out;
      ma_op <= ex_op;
      ma_w_id <= ex_w_id;
      ma_pc <= ex_pc;
      ma_imm <= ex_imm;
      ma_regs_r_2 <= ex_regs_r_2_fw; // for SB
    end
  end

  // MA (memory access) stage
  assign breq = ma_op == `OP_SB || ma_op == `OP_LB;
  assign mem_w_en = (ma_op == `OP_SB);
  assign mem_rw_addr = breq ? ma_alu_out : 0;
  assign mem_w = ma_regs_r_2;

  // MA->WB
  always @(posedge clk) begin
    if (rst || ma_op == `OP_NOP) begin
      wb_alu_out <= 0;
      wb_op <= `OP_NOP;
      wb_w_id <= 0;
    end else begin
      wb_alu_out <= ma_alu_out;
      wb_op <= ma_op;
      wb_w_id <= ma_w_id;
    end
  end

  // WB stage
  assign regs_w = (wb_op == `OP_CAL || wb_op == `OP_ADDI) ?
                    wb_alu_out :
                  (wb_op == `OP_LB) ?
                    mem_r : 0;
  assign regs_w_en = (wb_w_id != 0);
  assign regs_w_id = wb_w_id;

  // WB->RT
  always @(posedge clk) begin
    // This is required to forward the result from WB to EX stage
    if (rst || wb_op == `OP_NOP) begin
      rt_w_id <= 0;
      rt_w <= 0;
    end else begin
      rt_w_id <= wb_w_id;
      rt_w <= regs_w;
    end
  end
endmodule
