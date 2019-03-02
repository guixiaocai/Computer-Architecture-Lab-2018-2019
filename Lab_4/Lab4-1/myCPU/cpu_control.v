`timescale 10 ns / 1 ns

module cpu_control(
  input resetn,
  input [5:0] op,
  input [4:0] rs,
  input [4:0] rt,
  input [4:0] rd,
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
  output [2:0] store_type,
  output [1:0] HI_MemtoReg,
  output [1:0] LO_MemtoReg,
  output [3:0] rf_wen,
  output [1:0] RegDst,	  //lw 00, R-type 01, Jal 10
  output [1:0] ALUSrcB,	  //ReadData2 00, SignExtend 01, ZeroExtend 10
  output [3:0] MemtoReg,  //R-type 0000, lw 0001, jal 0010, lui 0011, lb 0100, lbu 0101, lh 0110, lhu 0111, lwl 1000, lwr 1001, movn 1010
  output [2:0] Branch,	  //beq 001, bne 010, bgez 011, blez 100, bltz 101, bgtz 110
  output [3:0] ALUop,
  output [1:0] Jump,      //j jal 01, jr 10, jalr 11   
  output [3:0] data_sram_wen,

  output inst_SYSCALL,
  output eret_cmt,
  output mtc0_wen_status,
  output mtc0_wen_cause,
  output mtc0_wen_epc
);
  wire inst_J,  inst_LW,  inst_LUI, inst_BNE,  inst_SLLV, inst_MFHI, inst_ADDI,
       inst_SW, inst_NOR, inst_BEQ, inst_AND,  inst_SUBU, inst_MFLO, inst_BLTZ,
       inst_OR, inst_SLL, inst_SRL, inst_SRA,  inst_SLTU, inst_ADDU, inst_BLEZ,
       inst_JR, inst_SLT, inst_DIV, inst_LBU,  inst_SRAV, inst_ANDI, inst_ADDIU,
       inst_LB, inst_ADD, inst_ORI, inst_XOR,  inst_SRLV, inst_MTHI, inst_MULTU,
       inst_LH, inst_SUB, inst_LWL, inst_JAL,  inst_MTLO, inst_JALR, inst_SLTIU,
       inst_SB, inst_LHU, inst_SWL, inst_XORI, inst_DIVU, inst_BGEZ, inst_BLTZAL,
       inst_SH, inst_LWR, inst_SWR, inst_SLTI, inst_MULT, inst_BGTZ, inst_BGEZAL;
       
  wire  inst_MTC0, inst_MFC0, inst_ERET;
       
  assign inst_J       = op ==6'b000010;
  assign inst_LW      = op ==6'b100011;
  assign inst_SW      = op ==6'b101011;
  assign inst_SB      = op ==6'b101000;
  assign inst_SH      = op ==6'b101001;
  assign inst_LB      = op ==6'b100000;
  assign inst_LH      = op ==6'b100001;
  assign inst_LUI     = op ==6'b001111;
  assign inst_BEQ     = op ==6'b000100;
  assign inst_BNE     = op ==6'b000101;
  assign inst_JAL     = op ==6'b000011;
  assign inst_ORI     = op ==6'b001101;
  assign inst_LBU     = op ==6'b100100;
  assign inst_LHU     = op ==6'b100101;
  assign inst_LWL     = op ==6'b100010;
  assign inst_LWR     = op ==6'b100110;
  assign inst_SWL     = op ==6'b101010;
  assign inst_SWR     = op ==6'b101110;
  assign inst_ADDI    = op ==6'b001000;
  assign inst_SLTI    = op ==6'b001010;
  assign inst_ANDI    = op ==6'b001100;
  assign inst_XORI    = op ==6'b001110;
  assign inst_BGTZ    = op ==6'b000111;
  assign inst_BLEZ    = op ==6'b000110;
  assign inst_ADDIU   = op ==6'b001001;
  assign inst_SLTIU   = op ==6'b001011;
  assign inst_OR      = (op==6'b000000) && (func==6'b100101);
  assign inst_JR      = (op==6'b000000) && (func==6'b001000);
  assign inst_JALR    = (op==6'b000000) && (func==6'b001001);
  assign inst_SLT     = (op==6'b000000) && (func==6'b101010);
  assign inst_AND     = (op==6'b000000) && (func==6'b100100);
  assign inst_XOR     = (op==6'b000000) && (func==6'b100110);
  assign inst_NOR     = (op==6'b000000) && (func==6'b100111);
  assign inst_SLL     = (op==6'b000000) && (func==6'b000000);
  assign inst_SRL     = (op==6'b000000) && (func==6'b000010);
  assign inst_SRA     = (op==6'b000000) && (func==6'b000011);
  assign inst_SLTU    = (op==6'b000000) && (func==6'b101011);
  assign inst_ADDU    = (op==6'b000000) && (func==6'b100001);
  assign inst_SUBU    = (op==6'b000000) && (func==6'b100011);
  assign inst_ADD     = (op==6'b000000) && (func==6'b100000); 
  assign inst_SUB     = (op==6'b000000) && (func==6'b100010); 
  assign inst_SLLV    = (op==6'b000000) && (func==6'b000100);
  assign inst_SRAV    = (op==6'b000000) && (func==6'b000111);
  assign inst_SRLV    = (op==6'b000000) && (func==6'b000110);
  assign inst_DIV     = (op==6'b000000) && (func==6'b011010);
  assign inst_DIVU    = (op==6'b000000) && (func==6'b011011);
  assign inst_MULT    = (op==6'b000000) && (func==6'b011000);
  assign inst_MULTU   = (op==6'b000000) && (func==6'b011001);
  assign inst_MFHI    = (op==6'b000000) && (func==6'b010000);
  assign inst_MFLO    = (op==6'b000000) && (func==6'b010010);
  assign inst_MTHI    = (op==6'b000000) && (func==6'b010001);
  assign inst_MTLO    = (op==6'b000000) && (func==6'b010011);
  assign inst_BGEZ    = (op==6'b000001) && (rt  ==5'b00001 );
  assign inst_BLTZ    = (op==6'b000001) && (rt  ==5'b00000 );
  assign inst_BLTZAL  = (op==6'b000001) && (rt  ==5'b10000 );
  assign inst_BGEZAL  = (op==6'b000001) && (rt  ==5'b10001 );
  
  assign inst_SYSCALL = (op==6'b000000) && (func==6'b001100);
	assign inst_MFC0    = (op==6'b010000) && (rs  ==5'b00000 );
  assign inst_MTC0    = (op==6'b010000) && (rs  ==5'b00100 );
  assign inst_ERET    = (op==6'b010000) && (func==6'b011000) && (rs[4] == 1'b1) && (rt == 5'b00000) && (rd == 5'b00000);


  assign mtc0_wen_status = inst_MTC0 && (rd == 5'd12);
  assign mtc0_wen_cause  = inst_MTC0 && (rd == 5'd13);
  assign mtc0_wen_epc    = inst_MTC0 && (rd == 5'd14);

  assign eret_cmt = inst_ERET;
  
  assign MemRead  = inst_LW   | inst_LB    | inst_LBU | inst_LH  | inst_LHU | inst_LWL  | inst_LWR;
  
  assign MemWrite = inst_SW   | inst_SB    | inst_SH  | inst_SWL | inst_SWR ;
  
  assign RegDst   = (inst_LW  | inst_SW    | inst_LUI | inst_BEQ | inst_SH  | inst_SB   |    // rf_waddr_ID
                     inst_BNE | inst_ADDIU | inst_JR  | inst_ADDI| inst_SWL | inst_LWR  |
                     inst_SLTI| inst_SLTIU | inst_ANDI| inst_XORI| inst_SWR | inst_LWL  |
                     inst_ORI | inst_LB    | inst_LBU | inst_LH  | inst_LHU | inst_MFC0)?    2'b00:  // rt
                    (inst_OR  | inst_SLTU  | inst_AND | inst_XOR | inst_JALR| inst_MFLO |
                     inst_NOR | inst_SUBU  | inst_SRL | inst_SRA | inst_MFHI| inst_SRAV |
                     inst_SLT | inst_ADDU  | inst_SLL | inst_ADD | inst_SRLV| inst_SLLV |
                     inst_SUB                                                          )?    2'b01:  // rd
                    (inst_JAL | inst_BLTZAL| inst_BGEZAL)?                                   2'b10:  // 31st reg
                                                                                             2'b11;  // Don't write reg file

  assign ALUSrcA  = (inst_SRA | inst_SRL   | inst_SLL)?                                      1'b1:
                                                                                             1'b0;
  
  assign ALUSrcB  = (inst_LUI | inst_BEQ   | inst_BNE | inst_JAL | inst_SRLV| inst_SLLV |
                     inst_OR  | inst_SUBU  | inst_SLT | inst_AND | inst_SRAV| inst_SUB  |
                     inst_XOR | inst_ADDU  | inst_SLL | inst_SRL | inst_ADD | inst_JR   |
                     inst_SRA | inst_SLTU  | inst_NOR                                  )?    2'b00:  // rt                 
                    (inst_LW  | inst_ADDIU | inst_SW  | inst_ADDI| inst_SWR | inst_SWL  |
                     inst_SLTI| inst_SLTIU | inst_LB  | inst_LBU | inst_SH  | inst_SB   |
                     inst_LH  | inst_LHU   | inst_LWL | inst_LWR                       )?    2'b01:  // signed externed
                    (inst_ANDI| inst_XORI  | inst_ORI)?                                      2'b10:  // Zero Extened
                                                                                             2'b11;
  assign rf_wen   = (inst_LW  | inst_ADDIU | inst_LUI | inst_JAL | inst_LWR | inst_LWL  |
                     inst_OR  | inst_SLTU  | inst_AND | inst_XOR | inst_LHU | inst_LH   |
                     inst_NOR | inst_SUBU  | inst_SRL | inst_SRA | inst_LBU | inst_LB   |
                     inst_SLT | inst_ADDU  |(inst_SLL & rt!=5'b0)| inst_JALR| inst_SRAV |
                     inst_ADD | inst_SLTIU | inst_SUB | inst_SLTI| inst_MFLO| inst_ADDI |
                     inst_ANDI| inst_BLTZAL| inst_ANDI| inst_ORI | inst_MFHI| inst_XORI |
                     inst_SLLV| inst_BGEZAL| inst_SRLV| inst_MFC0                      )?    4'b1111:
                                                                                             4'b0000;


  assign MemtoReg = (inst_SW  | inst_ADDIU | inst_BNE | inst_BEQ | inst_SWR | inst_SWL  |
                     inst_OR  | inst_SLT   | inst_JR  | inst_AND | inst_SB  | inst_XORI |
                     inst_XOR | inst_SLTIU | inst_SLL | inst_SRL | inst_SRLV| inst_SRAV |
                     inst_SRA | inst_SLTU  | inst_ADDU| inst_SUBU| inst_SLLV| inst_ORI  |
                     inst_ADD | inst_ADDI  | inst_SUB | inst_SLTI| inst_NOR | inst_ANDI)?    4'b0000: // ALU_result
                    (inst_LW )?                                                              4'b0001:
                    (inst_JAL | inst_BLTZAL| inst_BGEZAL|inst_JALR)?                         4'b0010: // PC + 32'd8:
                    (inst_LUI )?                                                             4'b0011:
                    (inst_LB  )?                                                             4'b0100:
                    (inst_LBU )?                                                             4'b0101:
                    (inst_LH  )?                                                             4'b0110:
                    (inst_LHU )?                                                             4'b0111:
                    (inst_LWL )?                                                             4'b1000:
                    (inst_LWR )?                                                             4'b1001:
                    (inst_MFHI)?                                                             4'b1011:
                    (inst_MFLO)?                                                             4'b1100:
                    (inst_MFC0)?                                                             4'b1101:
                                                                                             4'b0000;

  assign ALUop    = (inst_AND | inst_ANDI )?                                                 4'b0000:
                    (inst_OR  | inst_ORI  )?                                                 4'b0001:
                    (inst_SW  | inst_ADDIU | inst_ADDU | inst_LW  |
                    inst_ADD  | inst_ADDI  | inst_LB   | inst_LBU |
                    inst_LH   | inst_LHU   | inst_LWL  | inst_LWR |
                    inst_SB   | inst_SH    | inst_SWL  | inst_SWR)?                          4'b0010: // add
                    (inst_SLTU| inst_SLTIU)?                                                 4'b0011:
                    (inst_SLL | inst_SLLV )?                                                 4'b0100:
                    (inst_NOR             )?                                                 4'b0101:
                    (inst_BEQ | inst_SUBU  | inst_BNE  | inst_SUB)?                          4'b0110:                  
                    (inst_SLT | inst_SLTI )?                                                 4'b0111:
                    (inst_SRA | inst_SRAV )?                                                 4'b1000:
                    (inst_SRL | inst_SRLV )?                                                 4'b1001:
                    (inst_XOR | inst_XORI )?                                                 4'b1010:
                                                                                             4'b0001;

  assign Jump     = (inst_JAL  | inst_J   )?                                                 2'b01:
                    (inst_JR   | inst_JALR)?                                                 2'b10:
                    (inst_JALR            )?                                                 2'b11:
                                                                                             2'b00;

  assign Branch   = (inst_BEQ )?                                                             3'b001:
                    (inst_BNE )?                                                             3'b010:
                    (inst_BGEZ | inst_BGEZAL)?                                               3'b011:
                    (inst_BLEZ)?                                                             3'b100:
                    (inst_BLTZ | inst_BLTZAL)?                                               3'b101:
                    (inst_BGTZ)?                                                             3'b110:
                                                                                             3'b000;

  assign data_sram_wen = (inst_SW  )?                                                        4'b1111:
                                                                                             4'b0000;

  assign store_type    = (inst_SB  )?                                                        3'b001:
                         (inst_SH  )?                                                        3'b010:
                         (inst_SWL )?                                                        3'b011:
                         (inst_SWR )?                                                        3'b100:
                                                                                             3'b000;  // sw & non-store

  assign mul_signed    = (inst_MULT)?                                                        1'b1:
                                                                                             1'b0;
  
  assign div_signed    = (inst_DIV )?                                                        1'b1:
                                                                                             1'b0;

  assign mul           = (inst_MULT| inst_MULTU)?                                            1'b1:
                                                                                             1'b0;
  assign div           = (inst_DIV | inst_DIVU )?                                            1'b1:
                                                                                             1'b0;

  assign HI_write      = (inst_MULT| inst_MULTU | inst_DIV | inst_DIVU | inst_MTHI)?         1'b1:
                                                                                             1'b0;
  assign LO_write      = (inst_MULT| inst_MULTU | inst_DIV | inst_DIVU | inst_MTLO)?         1'b1:
                                                                                             1'b0;

  assign HI_MemtoReg   = (inst_MULT| inst_MULTU)?                                            2'b00:
                         (inst_DIV | inst_DIVU )?                                            2'b01:
                         (inst_MTHI            )?                                            2'b10:
                                                                                             2'b11;

  assign LO_MemtoReg   = (inst_MULT| inst_MULTU)?                                            2'b00:
                         (inst_DIV | inst_DIVU )?                                            2'b01:
                         (inst_MTLO            )?                                            2'b10:
                                                                                             2'b11;

endmodule