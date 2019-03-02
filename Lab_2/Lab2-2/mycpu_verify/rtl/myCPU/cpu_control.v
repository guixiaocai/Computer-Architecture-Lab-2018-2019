`timescale 10 ns / 1 ns

module cpu_control(
  input resetn,
  input [5:0] op,
  input [4:0] rt,
  input [5:0] func,

  output mul,
  output div,
  output HI_write,
  output LO_write,
  output MemRead,
  output MemWrite,
  output ALUSrcA,
  output mul_signed,
  output div_signed,
  output [1:0] HI_MemtoReg,
  output [1:0] LO_MemtoReg,
  output [3:0] rf_wen,
  output [1:0] RegDst,	  //lw 00, R-type 01, Jal 10
  output [1:0] ALUSrcB,	  //ReadData2 00, SignExtend 01, ZeroExtend 10
  output [3:0] MemtoReg,  //R-type 0000, lw 0001, jal 0010, lui 0011, lb 0100, lbu 0101, lh 0110, lhu 0111, lwl 1000, lwr 1001, movn 1010
  output [2:0] Branch,	  //beq 001, bne 010, bgez 011, blez 100, bltz 101, bgtz 110
  output [3:0] ALUop,
  output [1:0] Jump,      //j jal 01, jr 10, jalr 11
  output [3:0] data_sram_wen
);
  wire inst_LW, inst_JAL, inst_LUI, inst_BNE, inst_JALR, inst_ADDIU,
       inst_SW, inst_NOR, inst_BEQ, inst_AND, inst_SUBU, inst_XOR, 
       inst_OR, inst_SLL, inst_SRL, inst_SRA, inst_SLTU, inst_ADDU,
       inst_JR, inst_SLT, inst_J ;
       
  wire inst_ADD, inst_ADDI, inst_ANDI, inst_SLTIU, inst_ORI, inst_XORI,
       inst_SUB, inst_SLTI, inst_SLLV, inst_SRAV,  inst_SRLV, inst_MTLO,
       inst_DIV, inst_DIVU, inst_MULT, inst_MULTU, inst_MFHI, inst_MFLO,
       inst_MTHI;
       
       
       
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
  
  
  assign inst_ADD   = (op==6'b0) && (func==6'b100000);
  assign inst_ADDI  = op==6'b001000;
  assign inst_SUB   = (op==6'b0) && (func==6'b100010);
  assign inst_SLTI  = op == 6'b001010;
  assign inst_SLTIU = op == 6'b001011;
  assign inst_ANDI  = op == 6'b001100;
  assign inst_ORI   = op == 6'b001101;
  assign inst_XORI  = op == 6'b001110;
  assign inst_SLLV  = (op==6'b0) && (func==6'b000100);
  assign inst_SRAV  = (op==6'b0) && (func==6'b000111);
  assign inst_SRLV  = (op==6'b0) && (func==6'b000110);
  assign inst_DIV   = (op==6'b0) && (func==6'b011010);
  assign inst_DIVU  = (op==6'b0) && (func==6'b011011);
  assign inst_MULT  = (op==6'b0) && (func==6'b011000);
  assign inst_MULTU = (op==6'b0) && (func==6'b011001);
  assign inst_MFHI  = (op==6'b0) && (func==6'b010000);
  assign inst_MFLO  = (op==6'b0) && (func==6'b010010);
  assign inst_MTHI  = (op==6'b0) && (func==6'b010001);
  assign inst_MTLO  = (op==6'b0) && (func==6'b010011);
  
         
  assign MemRead  = inst_LW;
  
  assign MemWrite = inst_SW;
  
  assign RegDst   = (inst_LW  | inst_SW    | inst_LUI | inst_BEQ |
                     inst_BNE | inst_ADDIU | inst_JR  | inst_ADDI|
                     inst_SLTI| inst_SLTIU | inst_ANDI| inst_XORI|
                     inst_ORI )? 2'b00:  //rt
                    (inst_OR  | inst_SLTU  | inst_AND | inst_XOR |
                     inst_NOR | inst_SUBU  | inst_SRL | inst_SRA |
                     inst_SLT | inst_ADDU  | inst_SLL | inst_ADD |
                     inst_SUB | inst_SLLV  | inst_SRAV| inst_SRLV|
                     inst_MFHI| inst_MFLO)? 2'b01:  //rd
                    (inst_JAL)?                                     2'b10:  //31
                                                                    2'b11;  //don't write reg file

  assign ALUSrcA  = (inst_SRA | inst_SRL   | inst_SLL)?             1'b1:
                                                                    1'b0;
  
  assign ALUSrcB  = (inst_LUI | inst_BEQ   | inst_BNE | inst_JAL |
                     inst_OR  | inst_SUBU  | inst_SLT | inst_AND |
                     inst_XOR | inst_ADDU  | inst_SLL | inst_SRL |
                     inst_SRA | inst_SLTU  | inst_NOR | inst_JR  |
                     inst_ADD | inst_SUB   | inst_SLLV| inst_SRAV|
                     inst_SRLV)?  2'b00:  //rt                 
                    (inst_LW  | inst_ADDIU | inst_SW  | inst_ADDI|
                     inst_SLTI| inst_SLTIU )? 2'b01:  //signed externed
                    (inst_ANDI| inst_XORI  | inst_ORI)?              2'b10:   //zero extened
                                                                     2'b11;
  assign rf_wen   = (inst_LW  | inst_ADDIU | inst_LUI | inst_JAL |
                     inst_OR  | inst_SLTU  | inst_AND | inst_XOR |
                     inst_NOR | inst_SUBU  | inst_SRL | inst_SRA |
                     inst_SLT | inst_ADDU  |(inst_SLL & rt!=5'b0)|
                     inst_ADD | inst_ADDI  | inst_SUB | inst_SLTI|
                     inst_ANDI| inst_SLTIU | inst_ANDI| inst_ORI |
                     inst_SLLV| inst_SRAV  | inst_SRLV| inst_XORI|
                     inst_MFHI| inst_MFLO)? 4'b1111:
                                                                    4'b0000;

  assign MemtoReg = (inst_SW  | inst_ADDIU | inst_BNE | inst_BEQ |
                     inst_OR  | inst_SLT   | inst_JR  | inst_AND |
                     inst_XOR | inst_NOR   | inst_SLL | inst_SRL |
                     inst_SRA | inst_SLTU  | inst_ADDU| inst_SUBU|
                     inst_ADD | inst_ADDI  | inst_SUB | inst_SLTI|
                     inst_ANDI| inst_SLTIU | inst_ORI | inst_SLLV|
                     inst_SRAV| inst_SRLV  | inst_XORI)? 4'b0000:
                    (inst_LW )?                                     4'b0001:
                    (inst_JAL)?                                     4'b0010:
                    (inst_LUI)?                                     4'b0011:
                    (inst_MFHI)?                                    4'b1011:
                    (inst_MFLO)?                                    4'b1100:
                                                                    4'b0100;

  assign ALUop    = (inst_AND | inst_ANDI  )?                       4'b0000:
                    (inst_OR  | inst_ORI   )?                       4'b0001:
                    (inst_SW  | inst_ADDIU | inst_ADDU | inst_LW |
                    inst_ADD  | inst_ADDI  )?                       4'b0010:
                    (inst_SLTU| inst_SLTIU )?                       4'b0011:
                    (inst_SLL | inst_SLLV  )?                       4'b0100:
                    (inst_NOR )?                                    4'b0101:
                    (inst_BEQ | inst_SUBU  | inst_BNE  | inst_SUB)? 4'b0110:                  
                    (inst_SLT | inst_SLTI  )?                       4'b0111:
                    (inst_SRA | inst_SRAV  )?                       4'b1000:
                    (inst_SRL | inst_SRLV  )?                       4'b1001:
                    (inst_XOR | inst_XORI  )?                       4'b1010:
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
                                    
  assign mul_signed = (inst_MULT)? 1'b1 : 1'b0;
  
  assign div_signed = (inst_DIV )? 1'b1 : 1'b0;
  
  assign mul = (inst_MULT| inst_MULTU)? 1'b1 : 1'b0;
  assign div = (inst_DIV | inst_DIVU )? 1'b1 : 1'b0;

  assign HI_write = (inst_MULT| inst_MULTU | inst_DIV | inst_DIVU | inst_MTHI)? 1'b1 : 1'b0;
  assign LO_write = (inst_MULT| inst_MULTU | inst_DIV | inst_DIVU | inst_MTLO)? 1'b1 : 1'b0;
  
  assign HI_MemtoReg = (inst_MULT| inst_MULTU)?  2'b00:
                       (inst_DIV | inst_DIVU )?  2'b01:
                       (inst_MTHI            )?  2'b10:
                                                 2'b11;
  
  assign LO_MemtoReg = (inst_MULT| inst_MULTU)?  2'b00:
                       (inst_DIV | inst_DIVU )?  2'b01:
                       (inst_MTLO            )?  2'b10:
                                                 2'b11;
endmodule