`timescale 1ns / 1ps

module WB_stage(
  input  wire clk,
  input  wire resetn,
  input  wire MemRead_MEM,
  input  wire HI_write_MEM,
  input  wire LO_write_MEM,
  input  wire MEM_to_WB_valid,
  input  wire [31:0] PC_MEM,
  input  wire [01:0] Byte_MEM,
  input  wire [03:0] rf_wen_MEM,
  input  wire [31:0] HI_wdata_MEM,
  input  wire [31:0] LO_wdata_MEM,
  input  wire [03:0] MemtoReg_MEM,
  input  wire [04:0] rf_waddr_MEM,
  input  wire [31:0] ReadData2_MEM,
  input  wire [01:0] HI_MemtoReg_MEM,
  input  wire [01:0] LO_MemtoReg_MEM,
  input  wire [31:0] data_rdata,
  input  wire [31:0] Instruction_MEM,
  input  wire [31:0] rf_wdata_temp_MEM,
  input  wire data_req,
  input  wire data_data_ok,

  output reg  WB_valid,
  output wire WB_allowin,
  output reg  MemRead_WB,
  output reg  HI_write_WB,
  output reg  LO_write_WB,
  output reg  [31:0] PC_WB,
  output wire [31:0] rf_wdata,
  output wire [03:0] rf_wen_WB,
  output reg  [03:0] MemtoReg_WB,
  output reg  [31:0] HI_wdata_WB,
  output reg  [31:0] LO_wdata_WB,
  output reg  [04:0] rf_waddr_WB,
  output reg  [01:0] HI_MemtoReg_WB,
  output reg  [01:0] LO_MemtoReg_WB,
  output reg  [31:0] Instruction_WB,
  
  output reg  [ 3:0] rf_wen_WB_i
  );

  wire        WB_ready_go;
  reg  [ 1:0] Byte_WB;
  reg  [31:0] ReadData2_WB;
  reg  [31:0] rf_wdata_temp_WB;

  reg  data_req_WB;

  assign WB_ready_go        = !data_req_WB || data_data_ok;
  assign WB_allowin         = !WB_valid    || WB_ready_go;

  always @ (posedge clk) begin
    if(!resetn)
      WB_valid              <= 1'b0;
    else if(WB_allowin)
      WB_valid              <= MEM_to_WB_valid;
  end

  always @ (posedge clk) begin
    if(!resetn) begin
      rf_waddr_WB           <= 5'b0;
      rf_wen_WB_i           <= 4'b0;
      MemtoReg_WB           <= 4'b0;
    end
    else if(MEM_to_WB_valid && WB_allowin) begin
      PC_WB                 <= PC_MEM;
      Byte_WB               <= Byte_MEM;
      rf_wen_WB_i           <= rf_wen_MEM;
      MemRead_WB            <= MemRead_MEM;
      rf_waddr_WB           <= rf_waddr_MEM;
      MemtoReg_WB           <= MemtoReg_MEM;
      HI_write_WB           <= HI_write_MEM;
      LO_write_WB           <= LO_write_MEM;
      HI_wdata_WB           <= HI_wdata_MEM;
      LO_wdata_WB           <= LO_wdata_MEM;
      ReadData2_WB          <= ReadData2_MEM;
      HI_MemtoReg_WB        <= HI_MemtoReg_MEM;
      LO_MemtoReg_WB        <= LO_MemtoReg_MEM;
      Instruction_WB        <= Instruction_MEM;
      rf_wdata_temp_WB      <= rf_wdata_temp_MEM;

      data_req_WB           <= data_req;
    end
  end

  assign rf_wen_WB          = (WB_valid && WB_ready_go)?   rf_wen_WB_i:
                                                           4'b0;

  assign rf_wdata           = (MemtoReg_WB == 4'b0001)?    data_rdata:                                     // lw
                              (MemtoReg_WB == 4'b0100)?	   (                                                    // lb
		                      (Byte_WB     == 2'b00  )?    {{25{data_rdata[07]}},data_rdata[06:00]} :
		                      (Byte_WB     == 2'b01  )?    {{25{data_rdata[15]}},data_rdata[14:08]} :
		                      (Byte_WB     == 2'b10  )?    {{25{data_rdata[23]}},data_rdata[22:16]} :
		                                                   {{25{data_rdata[31]}},data_rdata[30:24]}):
		                          
		                      (MemtoReg_WB == 4'b0101)?	   (                                                    // lbu
		                      (Byte_WB     == 2'b00  )?    {24'b0, data_rdata[07:00]                   } :
		                      (Byte_WB     == 2'b01  )?    {24'b0, data_rdata[15:08]                   } :
		                      (Byte_WB     == 2'b10  )?    {24'b0, data_rdata[23:16]                   } :
		                                                   {24'b0, data_rdata[31:24]                   }):

		                      (MemtoReg_WB == 4'b0110)?	   (                                                    // lh
		                      (Byte_WB[1]  == 1'b0   )?    {{17{data_rdata[15]}},data_rdata[14:00]} :
		                                                   {{17{data_rdata[31]}},data_rdata[30:16]}):
		                                                   
		                      (MemtoReg_WB == 4'b0111)?	   (                                                    // lhu
		                      (Byte_WB[1]  == 1'b0   )?    {16'b0, data_rdata[15:00]                   } :
		                                                   {16'b0, data_rdata[31:16]                   }):		                          
		                                                       
                              (MemtoReg_WB == 4'b1000)?	   (                                                    // lwl
		                      (Byte_WB     == 2'b00  )?    {data_rdata[07:00], ReadData2_WB[23:00]     } :
		                      (Byte_WB     == 2'b01  )?    {data_rdata[15:00], ReadData2_WB[15:00]     } :
		                      (Byte_WB     == 2'b10  )?    {data_rdata[23:00], ReadData2_WB[07:00]     } :
		                                                   data_rdata                                  ):

                              (MemtoReg_WB == 4'b1001)?	   (                                                    // lwr
		                      (Byte_WB     == 2'b00  )?    data_rdata                                    :
		                      (Byte_WB     == 2'b01  )?    {ReadData2_WB[31:24], data_rdata[31:08]     } :
		                      (Byte_WB     == 2'b10  )?    {ReadData2_WB[31:16], data_rdata[31:16]     } :
		                                                   {ReadData2_WB[31:08], data_rdata[31:24]     }):
                                                            rf_wdata_temp_WB;

endmodule