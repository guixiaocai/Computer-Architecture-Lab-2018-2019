`timescale 1ns / 1ps

module EX_stage(
  input  wire clk,
  input  wire resetn,
  input  wire mul_ID,
  input  wire div_ID,
  input  wire MemRead_ID,
  input  wire ALUSrcA_ID,
  input  wire mul_signed_ID,
  input  wire div_signed_ID,
  input  wire MEM_allowin,
  input  wire HI_write_ID,
  input  wire LO_write_ID,
  input  wire ID_to_EX_valid,
  input  wire data_sram_en_ID,
  input  wire [31:0] HI,
  input  wire [31:0] LO,
  input  wire [31:0] PC_ID,
  input  wire [03:0] ALUop_ID,
  input  wire [03:0] rf_wen_ID,
  input  wire [01:0] ALUSrcB_ID,
  input  wire [03:0] MemtoReg_ID,
  input  wire [04:0] rf_waddr_ID,
  input  wire [31:0] HI_wdata_WB,
  input  wire [31:0] LO_wdata_WB,
  input  wire [31:0] LO_wdata_MEM,
  input  wire [31:0] HI_wdata_MEM,
  input  wire [31:0] ReadData1_ID,
  input  wire [31:0] ReadData2_ID,
  input  wire [02:0] store_type_ID,
  input  wire [01:0] HI_MemtoReg_ID,
  input  wire [01:0] LO_MemtoReg_ID,
  input  wire [31:0] Instruction_ID,
  input  wire [01:0] LO_MemtoReg_WB,
  input  wire [01:0] HI_MemtoReg_WB,
  input  wire [01:0] HI_MemtoReg_MEM,
  input  wire [01:0] LO_MemtoReg_MEM,
  input  wire [03:0] data_sram_wen_ID,
  
  input  wire [31:0] cp0_status,
  input  wire [31:0] cp0_cause,
  input  wire [31:0] cp0_epc,


  output reg  EX_valid,
  output wire EX_allowin,
  output reg  MemRead_EX,
  output reg  HI_write_EX,
  output reg  LO_write_EX,
  output reg  data_sram_en_EX,
  output wire EX_to_MEM_valid,
  output reg  [31:0] PC_EX,
  output wire [01:0] Byte_EX,
  output reg  [03:0] rf_wen_EX,
  output wire [31:0] HI_wdata_EX,
  output wire [31:0] LO_wdata_EX,
  output reg  [04:0] rf_waddr_EX,
  output reg  [03:0] MemtoReg_EX,
  output reg  [31:0] ReadData2_EX,
  output reg  [31:0] Instruction_EX,
  output reg  [01:0] HI_MemtoReg_EX,
  output reg  [01:0] LO_MemtoReg_EX,
  output wire [31:0] rf_wdata_temp_EX,
  output wire [03:0] data_sram_wen_EX,
  output wire [31:0] data_sram_addr_EX,
  output wire [31:0] data_sram_wdata_EX
	);
	
  reg  mul_EX;
  reg  div_EX;
  wire Zero_EX;
  reg  count_EX;
  reg  ALUSrcA_EX;
  wire EX_ready_go;
  wire Overflow1_EX;
  wire CarryOut1_EX;
  wire div_complete;
  wire mul_complete;
  reg  mul_signed_EX;
  reg  div_signed_EX;
  wire [31:0] s_EX;
  wire [31:0] r_EX;
  reg  [03:0] ALUop_EX;
  reg  [01:0] ALUSrcB_EX;
  reg  [31:0] ReadData1_EX;
  wire [31:0] AluInput1_EX;
  wire [31:0] AluInput2_EX;
  wire [31:0] ALU_result_EX;
  wire [63:0] mul_result_EX;
  reg  [02:0] store_type_EX;
  reg  [03:0] data_sram_wen_temp;
  
  assign EX_ready_go       = (mul_EX && !count_EX    )?   1'b0:
                             (div_EX && !div_complete)?   1'b0:
                                                          1'b1;
                                                                                                                                       
  assign EX_allowin        = !EX_valid || (EX_ready_go && MEM_allowin);
  assign EX_to_MEM_valid   =  EX_valid && EX_ready_go;
  
  always @ (posedge clk) begin
    if(!resetn || !mul_EX)
      count_EX             <= 1'b0;
    else if(mul_EX)
      count_EX             <= count_EX + 1'b1;
  end
  
  always @ (posedge clk) begin
    if(!resetn) 
      EX_valid             <= 1'b0;
    else if(EX_allowin)
      EX_valid             <= ID_to_EX_valid;
  end
  
  always @ (posedge clk) begin
    if(!resetn) begin
      rf_waddr_EX          <= 5'b0;
      rf_wen_EX            <= 4'b0;
      MemtoReg_EX          <= 4'b0;
    end   
    else if(ID_to_EX_valid && EX_allowin) begin
      PC_EX                <= PC_ID;
      mul_EX               <= mul_ID;
      div_EX               <= div_ID;
      ALUop_EX             <= ALUop_ID;
      rf_wen_EX            <= rf_wen_ID;
      ALUSrcA_EX           <= ALUSrcA_ID;
      ALUSrcB_EX           <= ALUSrcB_ID;
      MemRead_EX           <= MemRead_ID;
      HI_write_EX          <= HI_write_ID;
      LO_write_EX          <= LO_write_ID;
      MemtoReg_EX          <= MemtoReg_ID;
      rf_waddr_EX          <= rf_waddr_ID;
      ReadData1_EX         <= ReadData1_ID;
      ReadData2_EX         <= ReadData2_ID;
      mul_signed_EX        <= mul_signed_ID;
      div_signed_EX        <= div_signed_ID;
      store_type_EX        <= store_type_ID;
      HI_MemtoReg_EX       <= HI_MemtoReg_ID;
      LO_MemtoReg_EX       <= LO_MemtoReg_ID;
      Instruction_EX       <= Instruction_ID;
      data_sram_en_EX      <= data_sram_en_ID;
      data_sram_wen_temp   <= data_sram_wen_ID;
    end
  end
  
  assign data_sram_wdata_EX = (store_type_EX == 3'b001)?                            {4{ReadData2_EX[07:0]} }:       // sb
                              (store_type_EX == 3'b010)?                            {2{ReadData2_EX[15:0]} }:       // sh 
                              (store_type_EX == 3'b011)?                            (                               // swl 
                              (Byte_EX       == 2'b00 )?                            {24'd0, ReadData2_EX[31:24]} :
                              (Byte_EX       == 2'b01 )?                            {16'd0, ReadData2_EX[31:16]} :
                              (Byte_EX       == 2'b10 )?                            {08'd0, ReadData2_EX[31:08]} :
                                                                                    ReadData2_EX                ):
                              (store_type_EX == 3'b100)?                            (                               // swr
                              (Byte_EX       == 2'b00 )?                            ReadData2_EX                 :
                              (Byte_EX       == 2'b01 )?                            {ReadData2_EX[23:00], 08'd0} :
                              (Byte_EX       == 2'b10 )?                            {ReadData2_EX[15:00], 16'd0} :
                                                                                    {ReadData2_EX[07:00], 24'd0}):
                                                                                    ReadData2_EX;            

  assign data_sram_addr_EX  = {ALU_result_EX[31:2], 2'b00};
  
  assign Byte_EX            = ALU_result_EX[1:0];
  
  assign data_sram_wen_EX   = (store_type_EX == 3'b001)?                            (// sb
                              (Byte_EX       == 2'b00)?                             4'b0001 :
                              (Byte_EX       == 2'b01)?                             4'b0010 :
                              (Byte_EX       == 2'b10)?                             4'b0100 :
                                                                                    4'b1000):
                              (store_type_EX == 3'b010)?                            (// sh
                              (Byte_EX[1]    == 1'b1  )?                            4'b1100 :
                                                                                    4'b0011):                                                      
                              (store_type_EX == 3'b011)?                             (// swl
                              (Byte_EX       == 2'b00)?                             4'b0001 :
                              (Byte_EX       == 2'b01)?                             4'b0011 :
                              (Byte_EX       == 2'b10)?                             4'b0111 :
                                                                                    4'b1111):
                              (store_type_EX == 3'b100)?                             (// swr
                              (Byte_EX       == 2'b00)?                             4'b1111 :
                              (Byte_EX       == 2'b01)?                             4'b1110 :
                              (Byte_EX       == 2'b10)?                             4'b1100 :
                                                                                    4'b1000):
                                                                                    data_sram_wen_temp;

  assign rf_wdata_temp_EX   = (MemtoReg_EX == 4'b0000)?                             ALU_result_EX:
                              (MemtoReg_EX == 4'b0010)?                             PC_EX + 32'd8:                   //jal jalr bltzal bgezal
                              (MemtoReg_EX == 4'b0011)?                             {Instruction_EX[15:0],16'b0}:    //lui
                              (MemtoReg_EX == 4'b1011)?                             (
                              (HI_MemtoReg_MEM != 2'b11)?                           HI_wdata_MEM:
                              (HI_MemtoReg_WB  != 2'b11)?                           HI_wdata_WB:
                                                                                    HI):
                              (MemtoReg_EX == 4'b1100)?                             (
                              (LO_MemtoReg_MEM != 2'b11)?                           LO_wdata_MEM:
                              (LO_MemtoReg_WB  != 2'b11)?                           LO_wdata_WB:
                                                                                    LO):
                              (MemtoReg_EX == 4'b1101)?                             (
                              (Instruction_EX[15:11] == 5'd12)?                            cp0_status:
                              (Instruction_EX[15:11] == 5'd13)?                            cp0_cause :
                              (Instruction_EX[15:11] == 5'd14)?                            cp0_epc   :
                                                                                    32'b0):
                                                                                    32'b0;

  assign AluInput1_EX       = (ALUSrcA_EX)?                                         {27'b0,Instruction_EX[10:6]}:
                                                                                    ReadData1_EX;

  assign AluInput2_EX       = (ALUSrcB_EX==2'b01)?                                  { {17{Instruction_EX[15]}}, Instruction_EX[14:0] }:
                              (ALUSrcB_EX==2'b10)?                                  { 16'b0, Instruction_EX[15:0] }:
                              (ALUSrcB_EX==2'b00)?                                  ReadData2_EX:
                                                                                    32'b0;

  assign HI_wdata_EX        = (HI_MemtoReg_EX == 2'b00)?                            mul_result_EX[63:32]:
                              (HI_MemtoReg_EX == 2'b01)?                            r_EX:
                              (HI_MemtoReg_EX == 2'b10)?                            ReadData1_EX:
                                                                                    32'b0;
                                                                         
  assign LO_wdata_EX        = (LO_MemtoReg_EX == 2'b00)?                            mul_result_EX[31: 0]:
                              (LO_MemtoReg_EX == 2'b01)?                            s_EX:
                              (LO_MemtoReg_EX == 2'b10)?                            ReadData1_EX:
                                                                                    32'b0;
                                                                                    
	//ALU
  alu  alu_op(
    .A        (AluInput1_EX),
    .B        (AluInput2_EX),
    .ALUop    (ALUop_EX),

    .Zero     (Zero_EX),
    .Result   (ALU_result_EX),
    .Overflow (Overflow1_EX),
    .CarryOut (CarryOut1_EX)
  );

  //mul     
  mult mult(
    .mul_clk    (clk),
    .resetn     (resetn),
    .x          (ReadData1_EX),
    .y          (ReadData2_EX),
    .mul_signed (mul_signed_EX),


    .result     (mul_result_EX)
  );
  
  //div
  div div(
    .div_clk    (clk),
    .resetn     (resetn),
    .div        (div_EX),
    .div_signed (div_signed_EX),
    .x          (ReadData1_EX),
    .y          (ReadData2_EX),
          
    .s          (s_EX),
    .r          (r_EX),
    .complete   (div_complete)
  );
endmodule