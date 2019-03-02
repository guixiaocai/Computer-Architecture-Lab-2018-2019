`timescale 10 ns / 1 ns

module cpu_control(
	input resetn,
	input [5:0] op,
	input [4:0] rt,
	input [5:0] func,
	input [1:0] ea,
	input [2:0] state,

	output  MemRead,
	output  RegWrite,
	output  MemWrite,
	output reg [1:0] RegDst,	//lw 00, R-type 01, Jal 10 
	output reg [1:0] ALUSrc,	//ReadData2 00, SignExtend 01, ZeroExtend 10
	output reg [3:0] MemtoReg,	//R-type 0000, lw 0001, jal 0010, lui 0011, lb 0100, lbu 0101, lh 0110, lhu 0111, lwl 1000, lwr 1001, movn 1010
	output reg [2:0] Branch,	//beq 001, bne 010, bgez 011, blez 100, bltz 101, bgtz 110
	output reg [2:0] ALUOp,		//R-type 010, beq bne 001, lw sw 000, slti 011, sltiu 100, ori 101, xori 110, andi 111
	output reg [1:0] Jump,		//j jal 01, jr 10, jlar 11
	output reg [3:0] data_sram_wen,
	output  PCWrite,
	output  inst_sram_en
);

  parameter IF = 3'b000;
  parameter IW = 3'b001;
  parameter ID = 3'b010;
  parameter EX = 3'b011;
  parameter LD = 3'b100;
  parameter RDW = 3'b101;
  parameter WB = 3'b110;
  parameter ST = 3'b111;

	/*always@( * ) begin
    if(!resetn)
        {inst_sram_en,MemRead,MemWrite,RegWrite,PCWrite} = {1'b0,1'b0,1'b0,1'b0,1'b0};
    else begin
      if(state == IF)
        {inst_sram_en,MemRead,MemWrite,RegWrite,PCWrite} = {1'b0,1'b0,1'b0,1'b0,1'b0};
      else if(state == IW)
        {inst_sram_en,MemRead,MemWrite,RegWrite,PCWrite} = {1'b1,1'b0,1'b0,1'b0,1'b0};
      else if(state == LD)
        {inst_sram_en,MemRead,MemWrite,RegWrite,PCWrite} = {1'b0,1'b1,1'b0,1'b0,1'b0};
      else if(state == ST)
        {inst_sram_en,MemRead,MemWrite,RegWrite,PCWrite} = {1'b0,1'b0,1'b1,1'b0,1'b0};
      else if(state == RDW)
        {inst_sram_en,MemRead,MemWrite,RegWrite,PCWrite} = {1'b0,1'b0,1'b0,1'b0,1'b0};
      else if(state == WB)
        {inst_sram_en,MemRead,MemWrite,RegWrite,PCWrite} = {1'b0,1'b0,1'b0,1'b1,1'b0};
      else if(state == EX)
        {inst_sram_en,MemRead,MemWrite,RegWrite,PCWrite} = {1'b0,1'b0,1'b0,1'b0,1'b1};
      else if(state == ID)
        {inst_sram_en,MemRead,MemWrite,RegWrite,PCWrite} = {1'b0,1'b0,1'b0,1'b0,1'b0};
      else
        {inst_sram_en,MemRead,MemWrite,RegWrite,PCWrite} = {1'b0,1'b0,1'b0,1'b0,1'b0};
    end
  end*/
  
  assign {inst_sram_en,MemRead,MemWrite,RegWrite,PCWrite} = (!resetn)?      {1'b0,1'b0,1'b0,1'b0,1'b0}:
                                                            (state == IF)?  {1'b0,1'b0,1'b0,1'b0,1'b0}:
                                                            (state == IW)?  {1'b1,1'b0,1'b0,1'b0,1'b0}:
                                                            (state == LD)?  {1'b0,1'b1,1'b0,1'b0,1'b0}:
                                                            (state == ST)?  {1'b0,1'b0,1'b1,1'b0,1'b0}:
                                                            (state == RDW)? {1'b0,1'b0,1'b0,1'b0,1'b0}:
                                                            (state == WB)?  {1'b0,1'b0,1'b0,1'b1,1'b0}:
                                                            (state == EX)?  {1'b0,1'b0,1'b0,1'b0,1'b1}:
                                                            (state == ID)?  {1'b0,1'b0,1'b0,1'b0,1'b0}:
                                                                            {1'b0,1'b0,1'b0,1'b0,1'b0};
                                                            
                                                            
                                                            
  always@( * ) begin
  if(!resetn)
    {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0000,3'b000,3'b000,2'b00};
  else begin
        case(op)
          6'b001001://addiu 
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b01,4'b0000,3'b000,3'b000,2'b00};
          6'b000100://beq
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0000,3'b001,3'b001,2'b00};
          6'b000101://bne
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0000,3'b010,3'b001,2'b00};
          6'b000110://blez
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0000,3'b100,3'b001,2'b00};
          6'b000111://bgtz
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0000,3'b110,3'b001,2'b00};
          6'b000010://j
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0000,3'b000,3'b000,2'b01};
          6'b000011://jal
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b10,2'b00,4'b0010,3'b000,3'b000,2'b01};
          6'b001111://lui
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0011,3'b000,3'b000,2'b00};
          6'b001010://slti
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b01,4'b0000,3'b000,3'b011,2'b00};
          6'b001011://sltiu
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b01,4'b0000,3'b000,3'b100,2'b00};
          6'b001100://andi
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b10,4'b0000,3'b000,3'b111,2'b00};
          6'b100100://lbu
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b01,4'b0101,3'b000,3'b000,2'b00};
          6'b100001://lh
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b01,4'b0110,3'b000,3'b000,2'b00};
          6'b100101://lhu
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b01,4'b0111,3'b000,3'b000,2'b00};
          6'b100010://lwl
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b01,4'b1000,3'b000,3'b000,2'b00};
          6'b100110://lwr
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b01,4'b1001,3'b000,3'b000,2'b00};
          6'b100011://lw
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b01,4'b0001,3'b000,3'b000,2'b00};
          6'b100000://lb
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b01,4'b0100,3'b000,3'b000,2'b00};
          6'b001101://ori
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b10,4'b0000,3'b000,3'b101,2'b00};
          6'b001110://xori
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b10,4'b0000,3'b000,3'b110,2'b00};
          6'b000001: begin
            if(rt==5'b00001) //bgez
              {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0000,3'b011,3'b001,2'b00};
            else if(rt==5'b00000) //bltz
              {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0000,3'b101,3'b001,2'b00};
            else
              {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0000,3'b000,3'b000,2'b00};
          end
          6'b000000: begin
            if(func==6'b001000) //jr
              {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0000,3'b000,3'b000,2'b10};
            else if(func==6'b001001) //jalr
              {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b10,2'b00,4'b0010,3'b000,3'b000,2'b10};
            else if(func==6'b100110 ||	//xor
              func==6'b100111 ||	//nor
              func==6'b100100 ||	//and
              func==6'b100011 ||	//subu
              func==6'b101011 ||	//sltu
              func==6'b101010 ||	//slt
              func==6'b100001 ||	//addu
              func==6'b000011 ||	//sra
              func==6'b000010 ||	//srl
              func==6'b000000 ||	//sll
              func==6'b000110 ||	//srlv
              func==6'b000111 ||	//srav
              func==6'b000100 ||	//sllv
              func==6'b100101)	//or
              {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b01,2'b00,4'b0000,3'b000,3'b010,2'b00};
            else if(func==6'b001011 || func==6'b001010) //movn (ReadData2 == 0)? 1'b0:1'b1		//movz (ReadData2 == 0)? 1'b1:1'b0  
              {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b01,2'b00,4'b1010,3'b000,3'b000,2'b00};
            else
              {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0000,3'b000,3'b000,2'b00};
          end
          6'b101011,//sw
          6'b101000,//sb
          6'b101001,//sh
          6'b101010,//swl
          6'b101110://swr
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b01,4'b0000,3'b000,3'b000,2'b00};
          default:
            {RegDst,ALUSrc,MemtoReg,Branch,ALUOp,Jump} = {2'b00,2'b00,4'b0000,3'b000,3'b000,2'b00};
        endcase
    //  end
   // end
   end
  end


	//data_sram_wen
	always @( * )
	begin
		if(op==6'b101000) //sb
		begin
			if(ea == 2'b00)
				data_sram_wen = 4'b0001;
			else if(ea == 2'b01)
				data_sram_wen = 4'b0010;
			else if(ea == 2'b10)
				data_sram_wen = 4'b0100;
			else
				data_sram_wen = 4'b1000;
		end

		else if(op==6'b101010) //swl
		begin
			if(ea == 2'b00)
				data_sram_wen = 4'b0001;
			else if(ea == 2'b01)
				data_sram_wen = 4'b0011;
			else if(ea == 2'b10)
				data_sram_wen = 4'b0111;
			else
				data_sram_wen = 4'b1111;
		end

		else if(op==6'b101110) //swr
		begin
			if(ea == 2'b00)
				data_sram_wen = 4'b1111;
			else if(ea == 2'b01)
				data_sram_wen = 4'b1110;
			else if(ea == 2'b10)
				data_sram_wen = 4'b1100;
			else
				data_sram_wen = 4'b1000;
		end

		else if(op==6'b101001) //sh
			data_sram_wen = (ea[1])? 4'b1100:4'b0011;
		else if(op==6'b101011) //sw
			data_sram_wen = 4'b1111;			

		else
			data_sram_wen = 4'b0000;
	end

endmodule