`timescale 1ns / 1ps

module ID_stage(
  input  wire clk,
  input  wire resetn,
  input  wire EX_valid,
  input  wire MEM_valid,
  input  wire EX_allowin,
  input  wire MemRead_EX,
  input  wire MemRead_WB,
  input  wire MemRead_MEM,
  input  wire [31:0] PC_IF,
  input  wire [31:0] rf_wdata,
  input  wire [03:0] rf_wen_EX,
  input  wire [03:0] rf_wen_WB,
  input  wire [03:0] rf_wen_MEM,
  input  wire [03:0] MemtoReg_EX,
  input  wire [03:0] MemtoReg_WB,
  input  wire [04:0] rf_waddr_EX,
  input  wire [04:0] rf_waddr_WB,
  input  wire [04:0] rf_waddr_MEM,
  input  wire [03:0] MemtoReg_MEM,
  input  wire [31:0] inst_sram_rdata,
  input  wire [31:0] rf_wdata_temp_EX,
  input  wire [31:0] rf_wdata_temp_MEM,
  input  wire [31:0] ReadData1_ID_current,
  input  wire [31:0] ReadData2_ID_current,
  
  output wire mul_ID,
  output wire div_ID,
  output reg  ID_valid,
  output wire ID_allowin,
  output wire ALUSrcA_ID,
  output wire MemRead_ID,
  output wire HI_write_ID,
  output wire LO_write_ID,
  output wire mul_signed_ID,
  output wire div_signed_ID,
  output wire ID_to_EX_valid,
  output wire data_sram_en_ID,
  output reg  [31:0] PC_ID,
  output wire [31:0] PC_next,
  output wire [04:0] Esrc1_ID,
  output wire [04:0] Esrc2_ID,
  output wire [03:0] ALUop_ID,
  output wire [01:0] RegDst_ID,
  output wire [02:0] Branch_ID,
  output wire [03:0] rf_wen_ID,
  output wire [01:0] ALUSrcB_ID,
  output wire [03:0] MemtoReg_ID,
  output wire [04:0] rf_waddr_ID,
  output wire [31:0] ReadData1_ID,
  output wire [31:0] ReadData2_ID,
  output wire [02:0] store_type_ID,
  output wire [01:0] HI_MemtoReg_ID,
  output wire [01:0] LO_MemtoReg_ID,
  output wire [31:0] Instruction_ID,
  output wire [03:0] data_sram_wen_ID
  );

  wire validin;
  wire ID_ready_go;
  wire MemWrite_ID;
  wire is_Branch_ID;
  wire load_to_use_EX;
  wire load_to_use_MEM;
  wire [1:0] Jump_ID;
  
  assign validin         =  resetn;
  assign ID_ready_go     = ~(load_to_use_EX || load_to_use_MEM);
  assign ID_allowin      = !ID_valid || (ID_ready_go && EX_allowin);
  assign ID_to_EX_valid  =  ID_valid && ID_ready_go;  

  always @ (posedge clk) begin
  if(!resetn)
    ID_valid             <= 1'b0;
  else if(ID_allowin)
    ID_valid             <= 1'b1;

  if(validin && ID_allowin)
    PC_ID                <= PC_IF;
  end
  
  assign load_to_use_EX  = MemRead_EX  && ((Esrc1_ID == rf_waddr_EX  || Esrc2_ID == rf_waddr_EX ) && EX_valid ) && rf_wen_EX  != 4'b0;
  assign load_to_use_MEM = MemRead_MEM && ((Esrc1_ID == rf_waddr_MEM || Esrc2_ID == rf_waddr_MEM) && MEM_valid) && rf_wen_MEM != 4'b0;

  assign Instruction_ID  = inst_sram_rdata;

  assign data_sram_en_ID = MemRead_ID || MemWrite_ID;

  assign rf_waddr_ID     = (RegDst_ID == 2'b00)?   Instruction_ID[20:16]:
                           (RegDst_ID == 2'b01)?   Instruction_ID[15:11]:
                           (RegDst_ID == 2'b10)?   5'b11111:
                                                   5'b00000;

  assign is_Branch_ID    = ( (Branch_ID==3'b001 && (ReadData1_ID     == ReadData2_ID                               )) ||                    // beq
                             (Branch_ID==3'b010 && (ReadData1_ID     != ReadData2_ID                               )) ||                    // bne
                             (Branch_ID==3'b011 && (ReadData1_ID[31] == 01'b0                                      )) ||                    // bgez
                             (Branch_ID==3'b101 && (ReadData1_ID[31] == 01'b1                                      )) ||                    // bltz bltzal
                             (Branch_ID==3'b110 && (ReadData1_ID     != 32'b0          && ReadData1_ID[31] == 1'b0 )) ||                    // bgtz
                             (Branch_ID==3'b100 && (ReadData1_ID     == 32'b0          || ReadData1_ID[31] == 1'b1 )) )?           1'b1:    // blez 
                                                                                                                                   1'b0;
 
  assign Esrc1_ID        = Instruction_ID[25:21];
  assign Esrc2_ID        = Instruction_ID[20:16];

  assign ReadData1_ID    = (Esrc1_ID == rf_waddr_EX  && rf_wen_EX    != 4'b0000 && MemRead_EX  != 1'b1)?   rf_wdata_temp_EX:
                           (Esrc1_ID == rf_waddr_EX  && rf_wen_EX    != 4'b0000 && MemRead_EX  == 1'b1)?   rf_wdata:
                           (Esrc1_ID == rf_waddr_MEM && rf_wen_MEM   != 4'b0000 && MemRead_MEM != 1'b1)?   rf_wdata_temp_MEM:
                           (Esrc1_ID == rf_waddr_MEM && rf_wen_MEM   != 4'b0000 && MemRead_MEM == 1'b1)?   rf_wdata:
                           (Esrc1_ID == rf_waddr_WB  && rf_wen_WB    != 4'b0000)?                          rf_wdata:
                                                                                                           ReadData1_ID_current;

  assign ReadData2_ID    = (Esrc2_ID == rf_waddr_EX  && rf_wen_EX    != 4'b0000 && MemRead_EX  != 1'b1)?   rf_wdata_temp_EX:
                           (Esrc2_ID == rf_waddr_EX  && rf_wen_EX    != 4'b0000 && MemRead_EX  == 1'b1)?   rf_wdata:
                           (Esrc2_ID == rf_waddr_MEM && rf_wen_MEM   != 4'b0000 && MemRead_MEM != 1'b1)?   rf_wdata_temp_MEM:
                           (Esrc2_ID == rf_waddr_MEM && rf_wen_MEM   != 4'b0000 && MemRead_MEM == 1'b1)?   rf_wdata:
                           (Esrc2_ID == rf_waddr_WB  && rf_wen_WB    != 4'b0000)?                          rf_wdata:
                                                                                                           ReadData2_ID_current;

  //###   PC   ###                                                                                                                                                 
  assign PC_next         = (Jump_ID      == 2'b01)?     {PC_ID[31:28], Instruction_ID[25:0],1'b0,1'b0}:                            // j jal
                           (Jump_ID      == 2'b10)?     ReadData1_ID:                                                              // jr jalr
                           (is_Branch_ID == 1'b01)?     PC_ID + { {15{Instruction_ID[15]}}, Instruction_ID[14:0], 2'b00 } + 32'd4: // beq bne bgez blez bltz bgtz 
                                                        PC_IF + 31'd4;                                                              

	//cpu_control
  cpu_control  control(
    .resetn        (resetn),
    .op            (Instruction_ID[31:26]),
    .rt            (Instruction_ID[20:16]),
    .func          (Instruction_ID[5:0]),
  
    .mul           (mul_ID),
    .div           (div_ID),
    .Jump          (Jump_ID),
    .ALUop         (ALUop_ID),
    .rf_wen        (rf_wen_ID),
    .RegDst        (RegDst_ID),
    .Branch        (Branch_ID),
    .MemRead       (MemRead_ID),
    .ALUSrcA       (ALUSrcA_ID),
    .ALUSrcB       (ALUSrcB_ID),
    .MemWrite      (MemWrite_ID),
    .HI_write      (HI_write_ID),
    .LO_write      (LO_write_ID),
    .MemtoReg      (MemtoReg_ID),
    .store_type    (store_type_ID),
    .mul_signed    (mul_signed_ID),
    .div_signed    (div_signed_ID),
    .HI_MemtoReg   (HI_MemtoReg_ID),
    .LO_MemtoReg   (LO_MemtoReg_ID),
    .data_sram_wen (data_sram_wen_ID)
  );
endmodule