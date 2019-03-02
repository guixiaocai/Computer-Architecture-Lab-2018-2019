`timescale 1ns / 1ps

module MEM_stage(
  input  wire clk,
  input  wire resetn,
  input  wire WB_allowin,
  input  wire MemRead_EX,       
  input  wire HI_write_EX,
  input  wire LO_write_EX,
  input  wire EX_to_MEM_valid,
  input  wire data_sram_en_EX,
  input  wire [31:0] PC_EX,
  input  wire [01:0] Byte_EX,
  input  wire [03:0] rf_wen_EX,
  input  wire [04:0] rf_waddr_EX,
  input  wire [03:0] MemtoReg_EX,
  input  wire [31:0] HI_wdata_EX,
  input  wire [31:0] LO_wdata_EX,
  input  wire [31:0] ReadData2_EX,
  input  wire [31:0] Instruction_EX,
  input  wire [01:0] HI_MemtoReg_EX,
  input  wire [01:0] LO_MemtoReg_EX,
  input  wire [31:0] rf_wdata_temp_EX,
  input  wire [03:0] data_sram_wen_EX,
  input  wire [31:0] data_sram_addr_EX,
  input  wire [31:0] data_sram_wdata_EX,
  input  wire exe_badvaddr_S_EX,
  input  wire exe_badvaddr_L_EX,
  input  wire exe_overflow_EX,

  output reg  MEM_valid,
  output wire MEM_allowin,
  output reg  MemRead_MEM,
  output reg  HI_write_MEM,
  output reg  LO_write_MEM,
  output wire MEM_to_WB_valid,
  output reg  data_sram_en_MEM,
  output reg  [31:0] PC_MEM,
  output reg  [01:0] Byte_MEM,
  output reg  [03:0] rf_wen_MEM,
  output reg  [31:0] HI_wdata_MEM,
  output reg  [31:0] LO_wdata_MEM,
  output reg  [04:0] rf_waddr_MEM,
  output reg  [03:0] MemtoReg_MEM,
  output reg  [31:0] ReadData2_MEM,
  output reg  [31:0] Instruction_MEM,
  output reg  [01:0] HI_MemtoReg_MEM,
  output reg  [01:0] LO_MemtoReg_MEM,
  output reg  [31:0] rf_wdata_temp_MEM,
  output reg  [03:0] data_sram_wen_MEM,
  output reg  [31:0] data_sram_addr_MEM,
  output reg  [31:0] data_sram_wdata_MEM
  );

  wire   MEM_ready_go;

  assign MEM_ready_go       = 1'b1;
  assign MEM_allowin        = !MEM_valid || (MEM_ready_go && WB_allowin);
  assign MEM_to_WB_valid    =  MEM_valid && MEM_ready_go;

  always @ (posedge clk) begin
    if(!resetn)
      MEM_valid             <= 1'b0;
    else if(MEM_allowin)
      MEM_valid             <= EX_to_MEM_valid;
   end

  always @ (posedge clk) begin
    if(!resetn) begin
      rf_wen_MEM            <= 4'b0;
      MemRead_MEM           <= 1'b0;
      rf_waddr_MEM          <= 5'b0;
      MemtoReg_MEM          <= 4'b0;
    end  
    else if(EX_to_MEM_valid && MEM_allowin) begin
      PC_MEM                <= PC_EX;
      Byte_MEM              <= Byte_EX;

      MemRead_MEM           <= MemRead_EX;
      rf_waddr_MEM          <= rf_waddr_EX;
      MemtoReg_MEM          <= MemtoReg_EX;
      HI_write_MEM          <= HI_write_EX;
      LO_write_MEM          <= LO_write_EX;
      HI_wdata_MEM          <= HI_wdata_EX;
      LO_wdata_MEM          <= LO_wdata_EX;
      ReadData2_MEM         <= ReadData2_EX;
      HI_MemtoReg_MEM       <= HI_MemtoReg_EX;
      LO_MemtoReg_MEM       <= LO_MemtoReg_EX;
      Instruction_MEM       <= Instruction_EX;


      rf_wdata_temp_MEM     <= rf_wdata_temp_EX;
      data_sram_addr_MEM    <= data_sram_addr_EX;
      data_sram_wdata_MEM   <= data_sram_wdata_EX;

      if(exe_overflow_EX || exe_badvaddr_L_EX)
        rf_wen_MEM          <= 4'b0;
      else
        rf_wen_MEM          <= rf_wen_EX;

      if(!exe_badvaddr_S_EX) begin
        data_sram_en_MEM    <= data_sram_en_EX;
        data_sram_wen_MEM   <= data_sram_wen_EX;
      end
      else begin
        data_sram_en_MEM    <= 1'b0;
        data_sram_wen_MEM   <= 4'b0;
      end
    end
  end

endmodule