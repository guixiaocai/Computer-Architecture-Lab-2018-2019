`timescale 10 ns / 1 ns

module cpu_control(
  input resetn,
  input [5:0] op,
  input [4:0] rt,
  input [5:0] func,

  output MemRead,
  output MemWrite,
  output ALUSrcA,
  output [3:0] rf_wen,
  output [1:0] RegDst,	  //lw 00, R-type 01, Jal 10
  output [1:0] ALUSrcB,	  //ReadData2 00, SignExtend 01, ZeroExtend 10
  output [3:0] MemtoReg,	//R-type 0000, lw 0001, jal 0010, lui 0011, lb 0100, lbu 0101, lh 0110, lhu 0111, lwl 1000, lwr 1001, movn 1010
  output [2:0] Branch,	  //beq 001, bne 010, bgez 011, blez 100, bltz 101, bgtz 110
  output [3:0] ALUop,
  output [1:0] Jump,      //j jal 01, jr 10, jalr 11
  output [3:0] data_sram_wen
);
  wire inst_LW, inst_JAL, inst_LUI, inst_BNE, inst_JALR,  inst_ADDIU,
       inst_SW, inst_NOR, inst_BEQ, inst_AND, inst_SUBU,  inst_XOR, 
       inst_OR, inst_SLL, inst_SRL, inst_SRA, inst_SLTU,  inst_ADDU,
       inst_JR, inst_SLT, inst_J ;
  
  
  assign inst_LW    = op == 6'b100011;
  assign inst_SW    = op == 6'b101011;
  assign inst_LUI   = op == 6'b001111;
  assign inst_BEQ   = op == 6'b000100;
  assign inst_BNE   = op == 6'b000101;
  assign inst_JAL   = op == 6'b000011;
  assign inst_ADDIU = op == 6'b001001;
  assign inst_J     = op == 6'b000010;  //**** uncompleted*****
  assign inst_OR    = (op==6'b0) && (func==6'b100101);
  assign inst_JR    = (op==6'b0) && (func==6'b001000);
  assign inst_JALR  = (op==6'b0) && (func==6'b001001);  //**** uncompleted*****
  assign inst_SLT   = (op==6'b0) && (func==6'b101010);
  assign inst_AND   = (op==6'b0) && (func==6'b100100);
  assign inst_XOR   = (op==6'b0) && (func==6'b100110);
  assign inst_NOR   = (op==6'b0) && (func==6'b100111);
  assign inst_SLL   = (op==6'b0) && (func==6'b000000);
  assign inst_SRL   = (op==6'b0) && (func==6'b000010);
  assign inst_SRA   = (op==6'b0) && (func==6'b000011);
  assign inst_SLTU  = (op==6'b0) && (func==6'b101011);
  assign inst_ADDU  = (op==6'b0) && (func==6'b100001);
  assign inst_SUBU  = (op==6'b0) && (func==6'b100011);
         
  assign MemRead  = inst_LW;
  
  assign MemWrite = inst_SW;
  
  assign RegDst   = (inst_LW  | inst_SW    | inst_LUI | inst_BEQ |
                     inst_BNE | inst_ADDIU | inst_JR )?             2'b00:
                    (inst_OR  | inst_SLTU  | inst_AND | inst_XOR |
                     inst_NOR | inst_SUBU  | inst_SRL | inst_SRA |
                     inst_SLT | inst_ADDU  | inst_SLL )?            2'b01:
                    (inst_JAL)?                                     2'b10:
                                                                    2'b11;  

  assign ALUSrcA  = (inst_SRA | inst_SRL   | inst_SLL)?             1'b1:
                                                                    1'b0;
  
  assign ALUSrcB  = (inst_LUI | inst_BEQ   | inst_BNE | inst_JAL |
                     inst_OR  | inst_SUBU  | inst_SLT | inst_AND |
                     inst_XOR | inst_ADDU  | inst_SLL | inst_SRL |
                     inst_SRA | inst_SLTU  | inst_NOR | inst_JR )?  2'b00:
                    (inst_LW  | inst_ADDIU | inst_SW   )?           2'b01:
                                                                    2'b10;
   
  assign rf_wen   = (inst_LW  | inst_ADDIU | inst_LUI | inst_JAL |
                     inst_OR  | inst_SLTU  | inst_AND | inst_XOR |
                     inst_NOR | inst_SUBU  | inst_SRL | inst_SRA |
                     inst_SLT | inst_ADDU  |(inst_SLL & rt!=5'b0))? 4'b1111:
                                                                    4'b0000;

  assign MemtoReg = (inst_SW  | inst_ADDIU | inst_BNE | inst_BEQ |
                     inst_OR  | inst_SLT   | inst_JR  | inst_AND |
                     inst_XOR | inst_NOR   | inst_SLL | inst_SRL |
                     inst_SRA | inst_SLTU  | inst_ADDU| inst_SUBU)? 4'b0000:
                    (inst_LW )?                                     4'b0001:
                    (inst_JAL)?                                     4'b0010:
                    (inst_LUI)?                                     4'b0011:
                                                                    4'b0100;

  assign ALUop    = (inst_AND  )?                                   4'b0000:
                    (inst_OR   )?                                   4'b0001:
                    (inst_SW  | inst_ADDIU | inst_ADDU | inst_LW )? 4'b0010:
                    (inst_SLTU)?                                    4'b0011:
                    (inst_SLL )?                                    4'b0100:
                    (inst_NOR )?                                    4'b0101:
                    (inst_BEQ | inst_SUBU  | inst_BNE )?            4'b0110:                  
                    (inst_SLT )?                                    4'b0111:
                    (inst_SRA )?                                    4'b1000:
                    (inst_SRL )?                                    4'b1001:
                    (inst_XOR )?                                    4'b1010:
                                                                    4'b0001;

  assign Jump     = (inst_JAL  | inst_J)? 2'b01:
                    (inst_JR           )? 2'b10:
                    (inst_JALR         )? 2'b11:
                                          2'b00;

  assign Branch   = (inst_BEQ )? 3'b001:
                    (inst_BNE )? 3'b010:
                                 3'b000;

  assign data_sram_wen = (inst_SW)? 4'b1111:
                                    4'b0000;
endmodule