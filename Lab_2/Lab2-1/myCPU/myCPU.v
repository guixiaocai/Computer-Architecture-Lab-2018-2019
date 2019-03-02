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
  //###   Jump   ###
  wire [1:0] Jump_ID;

  //###   is_Branch   ###
  wire is_Branch_ID;
  
  //###   PC   ###
  reg [31:0] PC_IF, PC_ID, PC_EX, PC_MEM, PC_WB;
  
  //###   Instruction  ###
  wire [31:0] Instruction_ID;
  reg  [31:0] Instruction_EX, Instruction_MEM, Instruction_WB;

  //###   InsT Output ###
  assign inst_sram_en    = (!resetn)? 1'b0 : 1'b1;
  assign inst_sram_wen   = 4'b0;
  assign inst_sram_addr  = PC_IF;
  assign inst_sram_wdata = 32'b0;

  //###   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ###
  //###   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ###
   
   
  //###   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ###
  wire [31:0] AluInput1_ID, AluInput2_ID;
  wire [ 4:0] rf_waddr_ID;
  wire MemWrite_ID, MemRead_ID;
  wire ALUSrcA_ID;
  wire data_sram_en_ID; 
  wire [3:0] ALUop_ID;
  wire [3:0] rf_wen_ID;
  wire [3:0] rf_src_ID;
  wire [1:0] RegDst_ID; 
  wire [2:0] Branch_ID;
  wire [1:0] ALUSrcB_ID;
  wire [3:0] MemtoReg_ID;
  wire [3:0] data_sram_wen_ID;
  wire [31:0] ReadData1_ID;
  wire [31:0] ReadData2_ID;

  always @ (posedge clk) begin
  	PC_ID <= PC_IF;
  end

  assign Instruction_ID = inst_sram_rdata;
                   
  assign data_sram_en_ID = MemRead_ID | MemWrite_ID;
  
  assign AluInput1_ID = (ALUSrcA_ID)? {27'b0,Instruction_ID[10:6]} : ReadData1_ID;

  assign AluInput2_ID = (ALUSrcB_ID==2'b00)? ReadData2_ID:
                        (ALUSrcB_ID==2'b01)? { {17{Instruction_ID[15]}}, Instruction_ID[14:0] }:
                        (ALUSrcB_ID==2'b10)? { 16'b0, Instruction_ID[15:0] }:
                                             32'b0;

  assign rf_waddr_ID = (RegDst_ID == 2'b00)? Instruction_ID[20:16]:
                       (RegDst_ID == 2'b01)? Instruction_ID[15:11]:
                       (RegDst_ID == 2'b10)? 5'b11111:
                                             5'b00000;
                         
  assign is_Branch_ID = ( (Branch_ID==3'b001 && (ReadData1_ID == ReadData2_ID)) ||
                          (Branch_ID==3'b010 && (ReadData1_ID != ReadData2_ID)) )? 1'b1 : 1'b0;  //beq bne                                           
  //###   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ###
  
  
  
  //###   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ###                                     
  reg [31:0] AluInput1_EX, AluInput2_EX;
  reg data_sram_en_EX;
  reg [ 3:0] ALUop_EX;
  reg [ 3:0] rf_wen_EX;
  reg [ 3:0] rf_src_EX;
  reg [ 4:0] rf_waddr_EX;
  reg [ 1:0] RegDst_EX;
  reg [ 2:0] Branch_EX;
  reg [31:0] ReadData1_EX;
  reg [31:0] ReadData2_EX;
  reg [ 3:0] data_sram_wen_EX;
  reg [ 3:0] MemtoReg_EX;
  wire [31:0] data_sram_wdata_EX;
  wire Overflow1_EX;
  wire CarryOut1_EX;
  wire Zero_EX;
  wire [31:0] ALU_result_EX;

  always @ (posedge clk) begin   
    PC_EX           <= PC_ID;
    ALUop_EX        <= ALUop_ID;
    rf_wen_EX       <= rf_wen_ID;
    MemtoReg_EX     <= MemtoReg_ID;
    rf_waddr_EX     <= rf_waddr_ID;   
    Instruction_EX  <= Instruction_ID;
    data_sram_en_EX <= data_sram_en_ID;
    data_sram_wen_EX<= data_sram_wen_ID;   
    AluInput1_EX    <= AluInput1_ID;
    AluInput2_EX    <= AluInput2_ID;
    ReadData1_EX    <= ReadData1_ID;
    ReadData2_EX    <= ReadData2_ID;
  end

  assign data_sram_wdata_EX  = ReadData2_EX;      //sb  sh   swl   swe ..............................
  //###   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ###
 
 

  //###   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ###
  reg data_sram_en_MEM;
  reg [ 3:0] rf_wen_MEM;
  reg [ 3:0] rf_src_MEM;
  reg [ 1:0] RegDst_MEM;
  reg [ 2:0] Branch_MEM;
  reg [ 3:0] data_sram_wen_MEM;
  reg [31:0] ReadData1_MEM;
  reg [ 4:0] rf_waddr_MEM;
  reg [ 3:0] MemtoReg_MEM;
  reg [31:0] ALU_result_MEM;
  reg [31:0] data_sram_wdata_MEM;

  always @ (posedge clk) begin
    PC_MEM              <= PC_EX;
    rf_wen_MEM          <= rf_wen_EX;
    rf_waddr_MEM        <= rf_waddr_EX;
    MemtoReg_MEM        <= MemtoReg_EX;
    ReadData1_MEM       <= ReadData1_EX;
    ALU_result_MEM      <= ALU_result_EX;
    Instruction_MEM     <= Instruction_EX;
    data_sram_en_MEM    <= data_sram_en_EX;
    data_sram_wen_MEM   <= data_sram_wen_EX;
    data_sram_wdata_MEM <= data_sram_wdata_EX;
  end
  
  assign data_sram_en    = data_sram_en_MEM;
  assign data_sram_wen   = data_sram_wen_MEM;
  assign data_sram_wdata = data_sram_wdata_MEM;
  assign data_sram_addr  = { ALU_result_MEM[31:2], 2'b00 }; 
  //###   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ###
   
                                                  
                                                  
  //###   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ###
  reg [ 3:0] rf_wen_WB;
  reg [ 3:0] rf_src_WB;
  reg [ 1:0] RegDst_WB;
  reg [31:0] ReadData1_WB;
  reg [ 4:0] rf_waddr_WB;
  reg [ 3:0] MemtoReg_WB;
  reg [31:0] ALU_result_WB;
  wire [31:0] rf_wdata_WB;
  
  always @ (posedge clk) begin
    PC_WB           <= PC_MEM;
    rf_wen_WB       <= rf_wen_MEM;
    rf_waddr_WB     <= rf_waddr_MEM;
    MemtoReg_WB     <= MemtoReg_MEM;
    ReadData1_WB    <= ReadData1_MEM;
    ALU_result_WB   <= ALU_result_MEM;
    Instruction_WB  <= Instruction_MEM;
  end
  
  assign rf_wdata_WB  =  (MemtoReg_WB == 4'b0000)?  ALU_result_WB:
                         (MemtoReg_WB == 4'b0001)?  data_sram_rdata:               //lw
                         (MemtoReg_WB == 4'b0010)?  PC_WB + 32'd8:                 //jal jalr
                         (MemtoReg_WB == 4'b0011)?  {Instruction_WB[15:0],16'b0}:  //lui
                                                    32'b0;
                                          
  //###   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ###
                                                                 
  
                                                                 
  //###   Debug   ###
  assign debug_wb_pc       = PC_WB;
  assign debug_wb_rf_wen   = rf_wen_WB;
  assign debug_wb_rf_wnum  = rf_waddr_WB;
  assign debug_wb_rf_wdata = rf_wdata_WB;
  
  //###   PC   ###
  wire [31:0] PC_next;
  always @(posedge clk) begin
    if(!resetn)
      PC_IF <= 32'hbfc00000;
    else begin
      	PC_IF <= PC_next;
    end
  end          
                                         
  assign PC_next = (Jump_ID == 2'b01 )?       {PC_ID[31:28], Instruction_ID[25:0],1'b0,1'b0}:                            //j jal
                   (Jump_ID == 2'b10 )?       ReadData1_ID:                                                              //jr jalr
                   (is_Branch_ID == 1'b1)?    PC_ID + { {15{Instruction_ID[15]}}, Instruction_ID[14:0], 2'b00 } + 32'd4: //beq bne bgez blez bltz bgtz
                                              PC_IF + 31'd4;     

	//cpu_control
  cpu_control  control(.resetn(resetn),
                       .op(Instruction_ID[31:26]),
                       .rt(Instruction_ID[20:16]),
                       .func(Instruction_ID[5:0]),
                       
                       .MemRead(MemRead_ID),
                       .MemWrite(MemWrite_ID),
                       .rf_wen(rf_wen_ID),
                       .RegDst(RegDst_ID),
                       .ALUSrcA(ALUSrcA_ID),
                       .ALUSrcB(ALUSrcB_ID),
                       .MemtoReg(MemtoReg_ID),
                       .Branch(Branch_ID),
                       .ALUop(ALUop_ID),
                       .Jump(Jump_ID),
                       .data_sram_wen(data_sram_wen_ID));
	//reg file
  reg_file  Resigters(.clk(clk),
                      .resetn(resetn),
                      .waddr(rf_waddr_WB),
                      .raddr1(Instruction_ID[25:21]),
                      .raddr2(Instruction_ID[20:16]),
                      .wen(rf_wen_WB),
                      .wdata(rf_wdata_WB),
                      .rdata1(ReadData1_ID),
                      .rdata2(ReadData2_ID));
	//ALU
  alu  alu_op(.A(AluInput1_EX),
              .B(AluInput2_EX),
              .ALUop(ALUop_EX),
              .Overflow(Overflow1_EX),
              .CarryOut(CarryOut1_EX),
              .Zero(Zero_EX),
              .Result(ALU_result_EX));
             
endmodule