`timescale 10ns / 1ns

module mycpu_top(
  input  clk,
  input  resetn,

  //Instruction
  output  inst_sram_en,
  output  [3:0]  inst_sram_wen,
  output  [31:0] inst_sram_addr,
  output  [31:0] inst_sram_wdata,
  input   [31:0] inst_sram_rdata,
  
  //Data
  output  data_sram_en,
  output  [3:0]  data_sram_wen,
  output  [31:0] data_sram_addr,
  output  [31:0] data_sram_wdata,
  input   [31:0] data_sram_rdata,
  
  //###   Debug   ###
  output  [31:0] debug_wb_pc,
  output  [3:0]  debug_wb_rf_wen,
  output  [4:0]  debug_wb_rf_wnum,
  output  [31:0] debug_wb_rf_wdata
);

  //###   Reg_file   ###
  wire [4:0]  WriteRegAdd;
  wire [31:0] WriteData_Reg;
  reg  [31:0] WriteData_Reg_for_debug;
  wire [31:0] ReadData1, ReadData2;

  //###  Control signal  ###
  wire RegWrite, MemWrite, MemRead;
  wire [2:0] ALUOp;
  wire [3:0] MemtoReg;
  wire [1:0] RegDst; 
  wire [2:0] Branch;
  wire [1:0] Jump;
  wire [1:0] ALUSrc;
  
  //###   ALU   ###
  wire Overflow1, CarryOut1, Zero;
  wire [3:0]  ALUctr;
  wire [31:0] AluInput2;
  wire [31:0] AluInput1;
  wire [31:0] Result_op;
	
  //###   Extend   ###
  wire [31:0] SignExtend, ShiftLift, ZeroExtend;
	
  //###  Instruction & Data   ###
  wire [31:0] Instruction;
  wire [5:0]  op;
  wire [4:0]  rs;
  wire [4:0]  rt;
  wire [4:0]  rd;
  wire [4:0]  shamt;
  wire [5:0]  func;
  wire [15:0] offset;
  wire [31:0] read_memory_data;
  
  //###   PC   ###
  reg  [31:0] PC;
  wire [31:0] PC_i;
  reg  [31:0] PC_reg;
  wire [31:0] Result_PC;
  wire PCWrite;
  
  //###   State   ###
  reg [2:0] current_state, next_state;
  parameter IF = 3'b000;
  parameter IW = 3'b001;
  parameter ID = 3'b010;
  parameter EX = 3'b011;
  parameter LD = 3'b100;
  parameter RDW = 3'b101;
  parameter WB = 3'b110;
  parameter ST = 3'b111;
//  parameter IW_WAIT = 4'b1000;
  
  //###   output   ####
  assign inst_sram_wen = 4'b0;
  assign inst_sram_wdata = 32'b0;
  assign inst_sram_addr = PC;
  assign data_sram_en = MemRead|MemWrite;
  
  //###   rename   ###
  assign Instruction = inst_sram_rdata;
  assign op = inst_sram_rdata[31:26];
  assign rs = inst_sram_rdata[25:21];
  assign rt = inst_sram_rdata[20:16];
  assign rd = inst_sram_rdata[15:11];
  assign shamt = inst_sram_rdata[10:6];
  assign func = inst_sram_rdata[5:0];
  assign offset = inst_sram_rdata[15:0];
  assign read_memory_data = data_sram_rdata;

  //### debug ###
  assign debug_wb_pc = PC_reg;
  assign debug_wb_rf_wen = {4{RegWrite}};
  assign debug_wb_rf_wnum = WriteRegAdd;
  assign debug_wb_rf_wdata = WriteData_Reg;
  
  always @( posedge clk) begin
    if(next_state == EX)
      PC_reg <= PC;
  end
  
  //###   PC   ###
  assign PC_i = PC + 4;

  always @(posedge clk) begin
    if(!resetn)
      PC <= 32'hbfc00000;
    else begin
      if(PCWrite) begin
        if(Jump == 2'b00) begin
           if(  (Branch==3'b001 && Zero == 1) || (Branch==3'b010 && Zero == 0) || (Branch==3'b011 && ReadData1[31] == 0)
             || (Branch==3'b100 && (ReadData1[31] == 1||ReadData1[31:0]==32'b0)) || (Branch==3'b101 && ReadData1[31] == 1 )
             || (Branch==3'b110 && (ReadData1[31] == 0&&ReadData1[31:0]!=32'b0)) )      // beq bne bgez blez bltz bgtz
             PC <= Result_PC;
           else
             PC <= PC_i;
				end
         else if(Jump == 2'b01)	//j jal
           PC <= {PC_i[31:28], Instruction[25:0],1'b0,1'b0};
         else if(Jump == 2'b10)	//jr jalr
           PC <= ReadData1;
         else
           PC <= PC_i;
      end
    end
  end

	//### State ###
  always @(posedge clk) begin
  if(!resetn)
    current_state <= IF;
  else
    current_state <= next_state;
  end

  always @( * ) begin
  if(!resetn)
    next_state = IF;
  else
    case(current_state)
      IF: next_state = IW;
      IW: next_state = ID;
      ID: next_state = EX;
      ST: next_state = IF;
      LD: next_state = RDW;
      RDW: next_state = WB;
      WB: next_state = IF;
      EX:	begin
        if(op == 6'b000100|| op == 6'b000101|| op == 6'b000110|| op == 6'b000010||
           op == 6'b000001|| (op == 6'b000000 && func == 6'b001000) ||
           op == 6'b000111|| (op == 6'b000000 && func == 6'b001001) ||
           (op == 6'b000000 && ((func==6'b001011 && ReadData2== 32'b0) || (func==6'b001010 && ReadData2 != 0))))
          next_state = IF;
        else if(op == 6'b100100|| op == 6'b100001|| op == 6'b100101|| op == 6'b100010||
                op == 6'b100110|| op == 6'b100011|| op == 6'b100000)
          next_state = LD;
        else if(op == 6'b101011|| op == 6'b101000|| op == 6'b101001|| op == 6'b101010||
                op == 6'b101110)
          next_state = ST;
        else
          next_state = WB;
      end
      default: next_state = IF;
    endcase
  end
 
 
	//### WriteRegAdd ###
  assign WriteRegAdd = (RegDst == 2'b00)? rt:
                       (RegDst == 2'b01)? rd:
                       (RegDst == 2'b10)? 5'b11111:
                                          5'b00000;

  //### WriteData_Reg ###
  assign WriteData_Reg = (MemtoReg == 4'b0000)? Result_op:    //ALU_Result
                         (MemtoReg == 4'b0010)? PC_reg + 32'd8:     //jal jalr 
                         (MemtoReg == 4'b0001)? read_memory_data:  //lw
                         (MemtoReg == 4'b0011)? {offset,16'b0}: //lui
                         (MemtoReg == 4'b1010)? ReadData1:    //movn
                         (MemtoReg == 4'b0100)?	({32{Result_op[1:0]==2'b00}} & {{25{read_memory_data[7]}},read_memory_data[6:0]})  //lb
                                               |({32{Result_op[1:0]==2'b01}} & {{25{read_memory_data[15]}},read_memory_data[14:8]})
                                               |({32{Result_op[1:0]==2'b10}} & {{25{read_memory_data[23]}},read_memory_data[22:16]})
                                               |({32{Result_op[1:0]==2'b11}} & {{25{read_memory_data[31]}},read_memory_data[30:24]}):
                         (MemtoReg == 4'b0101)? ({32{Result_op[1:0]==2'b00}} & {24'b0,read_memory_data[7:0]})   //lbu
                                               |({32{Result_op[1:0]==2'b01}} & {24'b0,read_memory_data[15:8]})
                                               |({32{Result_op[1:0]==2'b10}} & {24'b0,read_memory_data[23:16]})
                                               |({32{Result_op[1:0]==2'b11}} & {24'b0,read_memory_data[31:24]}):
                         (MemtoReg == 4'b0110)? ({32{Result_op[1]==1'b0}} & {{17{read_memory_data[15]}},read_memory_data[14:0]})   //lh
                                               |({32{Result_op[1]==1'b1}} & {{17{read_memory_data[31]}},read_memory_data[30:16]}):
                         (MemtoReg == 4'b0111)? ({32{Result_op[1]==1'b0}} & {16'b0,read_memory_data[15:0]})     //lhu
                         		                   |({32{Result_op[1]==1'b1}} & {16'b0,read_memory_data[31:16]}):
                         (MemtoReg == 4'b1000)? ({32{Result_op[1:0]==2'b00}} & {read_memory_data[7:0],read_memory_data[23:0]})     //lwl
                                               |({32{Result_op[1:0]==2'b01}} & {read_memory_data[15:0],read_memory_data[15:0]})
                                               |({32{Result_op[1:0]==2'b10}} & {read_memory_data[23:0],read_memory_data[7:0]})
                                               |({32{Result_op[1:0]==2'b11}} & read_memory_data):
                         (MemtoReg == 4'b1001)? ({32{Result_op[1:0]==2'b00}} & read_memory_data)  //lwr
                                               |({32{Result_op[1:0]==2'b01}} & {ReadData2[31:24],read_memory_data[31:8]})
                                               |({32{Result_op[1:0]==2'b10}} & {ReadData2[31:16],read_memory_data[31:16]})
                                               |({32{Result_op[1:0]==2'b11}} & {ReadData2[31:8],read_memory_data[31:24]}):
                                               32'b0;

	//signed 16bit -> 32bit
	assign SignExtend = { {17{offset[15]}},offset[14:0] };
	//Shift Left 2	
	assign ShiftLift = {SignExtend[31],SignExtend[28:0],1'b0,1'b0};
	//zero_extend
	assign ZeroExtend = {16'b0,offset};

	//ALU_Input
	assign AluInput1 = (op ==6'b000000&&(func==6'b000011 || func==6'b000010 || func==6'b000000))? 
                     {27'b0,shamt} : ReadData1;

  assign AluInput2 = (ALUSrc==2'b00)? ReadData2:
                     (ALUSrc==2'b01)? SignExtend:
                     (ALUSrc==2'b10)? ZeroExtend:
                                      32'b0;
    
	//### ALUctr ###
	assign ALUctr = (ALUOp==3'b000)? 4'b0010: //lw sw addiu lb
	                (ALUOp==3'b001)? 4'b0110: //beq bne
	                (ALUOp==3'b011)? 4'b0111: //slti
	                (ALUOp==3'b100)? 4'b0011: //sltiu
	                (ALUOp==3'b101)? 4'b0001: //ori
	                (ALUOp==3'b110)? 4'b1010: //xori
	                (ALUOp==3'b111)? 4'b0000: //andi
	                (func==6'b100001)? 4'b0010: //addu      //3'b010 
	                (func==6'b100011)? 4'b0110: //subu
	                (func==6'b101010)? 4'b0111: //slt
	                (func==6'b101011)? 4'b0011: //sltu
	                (func==6'b100101)? 4'b0001: //or
	                (func==6'b100100)? 4'b0000: //and
	                (func==6'b100111)? 4'b0101: //nor
	                (func==6'b100110)? 4'b1010: //xor
	                (func==6'b000010 ||
	                 func==6'b000110)? 4'b1001: //srl srlv
	                (func==6'b000011 ||
	                 func==6'b000111)? 4'b1000: //sra srav
	                (func==6'b000000 ||
	                 func==6'b000100)? 4'b0100: //sll sllv
	                                   4'b0001;
	                
	//###   Menory   ###
  assign data_sram_addr = { Result_op[31:2], 2'b00 };

  assign data_sram_wdata = (op==6'b101000)? {4{ReadData2[7:0]}}:  //sb
                           (op==6'b101001)? {2{ReadData2[15:0]}}: //sh
                           (op==6'b101010)? ({32{Result_op[1:0]==2'b00}} & {24'd0,ReadData2[31:24]})   //swl
                                           |({32{Result_op[1:0]==2'b01}} & {16'd0,ReadData2[31:16]})
                                           |({32{Result_op[1:0]==2'b10}} & {8'd0,ReadData2[31:8]})
                                           |({32{Result_op[1:0]==2'b11}} & ReadData2):
                           (op==6'b101110)? ({32{Result_op[1:0]==2'b00}} & ReadData2)                  //swr
                                           |({32{Result_op[1:0]==2'b01}} & {ReadData2[23:0],8'd0})
                                           |({32{Result_op[1:0]==2'b10}} & {ReadData2[15:0],16'd0})
                                           |({32{Result_op[1:0]==2'b11}} & {ReadData2[7:0],24'd0}):
                                           ReadData2;
  
	//cpu_control
  cpu_control  control(.resetn(resetn),.op(op),.rt(rt),.func(func),.ea(Result_op[1:0]),.state(current_state),.MemRead(MemRead),
                       .RegWrite(RegWrite),.MemWrite(MemWrite),.RegDst(RegDst),.ALUSrc(ALUSrc),.MemtoReg(MemtoReg),.Branch(Branch),
                       .ALUOp(ALUOp),.Jump(Jump),.data_sram_wen(data_sram_wen),.PCWrite(PCWrite),.inst_sram_en(inst_sram_en));
	//reg_file
  reg_file  Resigters(.clk(clk),.resetn(resetn),.waddr(WriteRegAdd),.raddr1(rs),.raddr2(rt),.wen(RegWrite),
                      .wdata(WriteData_Reg),.rdata1(ReadData1),.rdata2(ReadData2));
	//ALU
  alu  alu_op(.A(AluInput1),.B(AluInput2),.ALUop(ALUctr),.Overflow(Overflow1),
              .CarryOut(CarryOut1),.Zero(Zero),.Result(Result_op)),
              
       alu_PC(.A(PC_i),.B(ShiftLift),.ALUop(4'b0010),.Overflow( ),
              .CarryOut( ),.Zero( ),.Result(Result_PC));
endmodule