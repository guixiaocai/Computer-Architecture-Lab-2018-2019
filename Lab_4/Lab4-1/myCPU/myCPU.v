`timescale 10ns / 1ns

module mycpu_top(
  input  clk,
  input  resetn,

  //Instruction
  output inst_sram_en,
  output [ 3:0] inst_sram_wen,
  output [31:0] inst_sram_addr,
  output [31:0] inst_sram_wdata,
  input  [31:0] inst_sram_rdata,
  
  //Data
  output data_sram_en,
  output [ 3:0] data_sram_wen,
  output [31:0] data_sram_addr,
  output [31:0] data_sram_wdata,
  input  [31:0] data_sram_rdata,
  
  //###   Debug   ###
  output [31:0] debug_wb_pc,
  output [ 3:0] debug_wb_rf_wen,
  output [ 4:0] debug_wb_rf_wnum,
  output [31:0] debug_wb_rf_wdata
);

  //### HI LO ###
  reg  [31:0] HI;
  reg  [31:0] LO;
  
  //### CP0_STATUS  ###
  wire [31:0] cp0_status;

  wire        cp0_status_bev;
  reg  [7:0]  cp0_status_im;
  reg         cp0_status_exl;
  reg         cp0_status_ie;
  
  //### CP0_CAUSE  ###
  wire [31:0] cp0_cause;
  
  reg         cp0_cause_bd;
  reg         cp0_cause_ti;
  reg  [5:0]  cp0_cause_ip_h;
  reg  [1:0]  cp0_cause_ip_l;
  reg  [4:0]  cp0_cause_exec;

  reg  [31:0] cp0_epc;
  
  //  ## Exception ##
  wire exception_commit;
  wire eret_cmt;
  
  wire [31:0] mtc0_value;
  wire mtc0_wen_status;
  wire mtc0_wen_cause;
  wire mtc0_wen_epc;

  //###  IF  ###
  reg  [31:0] PC_IF;
  wire [31:0] PC_next;
  
  //###  ID  ###
  wire mul_ID;
  wire div_ID;
  wire ID_valid;
  wire ID_allowin;
  wire MemRead_ID;
  wire ALUSrcA_ID;
  wire HI_write_ID;
  wire LO_write_ID;
  wire mul_signed_ID;
  wire div_signed_ID;
  wire ID_to_EX_valid;
  wire data_sram_en_ID;
  wire [31:0] PC_ID;
  wire [04:0] Esrc1_ID;
  wire [04:0] Esrc2_ID;
  wire [03:0] ALUop_ID;
  wire [03:0] rf_wen_ID;
  wire [01:0] RegDst_ID; 
  wire [02:0] Branch_ID;
  wire [01:0] ALUSrcB_ID;
  wire [03:0] MemtoReg_ID;
  wire [04:0] rf_waddr_ID;
  wire [31:0] ReadData1_ID;
  wire [31:0] ReadData2_ID;
  wire [02:0] store_type_ID;
  wire [01:0] HI_MemtoReg_ID;
  wire [01:0] LO_MemtoReg_ID;
  wire [31:0] Instruction_ID;
  wire [03:0] data_sram_wen_ID;
  wire [31:0] ReadData1_ID_current;
  wire [31:0] ReadData2_ID_current;

  //###  EX  ###
  wire EX_valid;
  wire EX_allowin;
  wire MemRead_EX;
  wire HI_write_EX;
  wire LO_write_EX;
  wire EX_to_MEM_valid;
  wire data_sram_en_EX;
  wire [31:0] PC_EX;
  wire [01:0] Byte_EX;
  wire [03:0] rf_wen_EX;
  wire [01:0] ALUSrcB_EX;
  wire [04:0] rf_waddr_EX;
  wire [03:0] MemtoReg_EX;
  wire [31:0] HI_wdata_EX;
  wire [31:0] LO_wdata_EX;
  wire [31:0] ReadData2_EX;
  wire [01:0] HI_MemtoReg_EX;
  wire [01:0] LO_MemtoReg_EX;
  wire [31:0] Instruction_EX;
  wire [31:0] rf_wdata_temp_EX;
  wire [03:0] data_sram_wen_EX;
  wire [31:0] data_sram_addr_EX;
  wire [31:0] data_sram_wdata_EX;  

  //###  MEM  ###
  wire MEM_valid;
  wire MEM_allowin;
  wire MemRead_MEM;
  wire HI_write_MEM;
  wire LO_write_MEM;
  wire MEM_to_WB_valid;
  wire data_sram_en_MEM;
  wire [31:0] PC_MEM;
  wire [01:0] Byte_MEM;
  wire [03:0] rf_wen_MEM;
  wire [04:0] rf_waddr_MEM;
  wire [03:0] MemtoReg_MEM;
  wire [31:0] HI_wdata_MEM;
  wire [31:0] LO_wdata_MEM;
  wire [31:0] ReadData2_MEM;
  wire [02:0] store_type_MEM;
  wire [31:0] Instruction_MEM;
  wire [01:0] HI_MemtoReg_MEM;
  wire [01:0] LO_MemtoReg_MEM;
  wire [31:0] rf_wdata_temp_MEM;
  wire [03:0] data_sram_wen_MEM;
  wire [31:0] data_sram_addr_MEM;
  wire [31:0] data_sram_wdata_MEM;

  //###  WB  ###;
  wire WB_valid;
  wire WB_allowin;
  wire MemRead_WB;
  wire HI_write_WB;
  wire LO_write_WB;
  wire [31:0] PC_WB;
  wire [31:0] rf_wdata;
  wire [03:0] rf_wen_WB;
  wire [31:0] HI_wdata_WB;
  wire [31:0] LO_wdata_WB;
  wire [04:0] rf_waddr_WB;
  wire [03:0] MemtoReg_WB;
  wire [31:0] Instruction_WB;
  wire [01:0] HI_MemtoReg_WB;
  wire [01:0] LO_MemtoReg_WB;
  
  //###   Inst Output ###
  assign inst_sram_en     = (!resetn)?       1'b0:
                            (!ID_allowin)?   1'b0:
                                             1'b1;
  assign inst_sram_wen    =  4'b0;
  assign inst_sram_addr   =  (exception_commit  && cp0_status_exl == 1'b0)? 32'hbfc00018 : PC_IF;
  assign inst_sram_wdata  =  32'b0;
  
  //###   Data Output ###
  assign data_sram_en     =  data_sram_en_MEM;
  assign data_sram_wen    =  data_sram_wen_MEM;
  assign data_sram_addr   =  data_sram_addr_MEM;
  assign data_sram_wdata  =  data_sram_wdata_MEM;
  
  always @(posedge clk) begin
    if(!resetn)
      PC_IF <= 32'hbfc00000;
    else if(ID_allowin && exception_commit  && cp0_status_exl == 1'b0)
      PC_IF <= 32'hBFC00380;
    else if(ID_allowin && eret_cmt)
      PC_IF <= cp0_epc;
    else if(ID_allowin)
      PC_IF <= PC_next;
  end
   
  // write HI and LO
  always @ (posedge clk) begin  
    if(HI_write_WB)
      HI                   <= HI_wdata_WB;
    if(LO_write_WB)
      LO                   <= LO_wdata_WB;
  end

  // Write cp0_status
  assign cp0_status_bev = 1'b1;
  assign cp0_status = { 9'b0          ,  // 31:23
                        cp0_status_bev,  // 22
                        6'd0          ,  // 21:16
                        cp0_status_im ,  // 15:8
                        6'd0          ,  // 7 :2
                        cp0_status_exl,  // 1
                        cp0_status_ie    //0
                      };
  
  always @ (posedge clk) begin
  	if(!resetn)
  		cp0_status_exl <= 1'b0;
    else if(mtc0_wen_status)
    begin
      cp0_status_im  <= mtc0_value[15:8];   
      cp0_status_exl <= mtc0_value[1];
      cp0_status_ie  <= mtc0_value[0];
    end
    else if(exception_commit && cp0_status_exl == 1'b0)
      cp0_status_exl <= 1'b1;
    else if(eret_cmt)
      cp0_status_exl <= 1'b0;
  end
  
  // Write cp0_cause
  
  assign cp0_cause = { cp0_cause_bd      ,  // 31
                       cp0_cause_ti      ,  // 30
                       14'b0             ,  // 29:16
                       cp0_cause_ip_h    ,  // 15:10
                       cp0_cause_ip_l    ,  // 9 :8
                       1'b0              ,  // 7
                       cp0_cause_exec    ,  // 6 :2
                       2'b0                 // 1 :0
                     };

  always @ (posedge clk) begin
  	if(!resetn)
  	begin
  		cp0_cause_ti   <= 1'b0;
  		cp0_cause_bd   <= 1'b0;
  		cp0_cause_ip_h <= 6'b0;
  		cp0_cause_ip_l <= 2'b0;
  		cp0_cause_exec <= 5'b0;
    end
    else if(mtc0_wen_status)
      cp0_cause_ip_l <= mtc0_value[9:8];
    else if(exception_commit)
      cp0_cause_exec <= 5'b01000;
  end
  
  always @ (posedge clk) begin
  	if(!resetn)
  	  cp0_epc   <= 1'b0;
    else if(mtc0_wen_epc)
      cp0_epc   <= mtc0_value;
    else if(exception_commit == 1'b1 && cp0_status_exl == 1'b0)
      cp0_epc   <= PC_ID;
  end
  
  //###   Debug   ###
  assign debug_wb_pc       =  PC_WB;
  assign debug_wb_rf_wen   =  (WB_valid)?   rf_wen_WB : 4'b0;
  assign debug_wb_rf_wnum  =  rf_waddr_WB;
  assign debug_wb_rf_wdata =  rf_wdata;
  
  //###   ID   ###
  ID_stage ID(
    .clk                  (clk),
    .PC_IF                (PC_IF),
    .resetn               (resetn),
    .rf_wdata             (rf_wdata),
    .EX_valid             (EX_valid),
    .MEM_valid            (MEM_valid),
    .rf_wen_EX            (rf_wen_EX),
    .rf_wen_WB            (rf_wen_WB),    
    .rf_wen_MEM           (rf_wen_MEM),
    .EX_allowin           (EX_allowin),
    .MemRead_WB           (MemRead_WB),
    .MemRead_EX           (MemRead_EX),
    .MemRead_MEM          (MemRead_MEM),
    .MemtoReg_EX          (MemtoReg_EX),
    .MemtoReg_WB          (MemtoReg_WB),
    .rf_waddr_EX          (rf_waddr_EX),
    .rf_waddr_WB          (rf_waddr_WB),
    .rf_waddr_MEM         (rf_waddr_MEM),
    .MemtoReg_MEM         (MemtoReg_MEM),
    .inst_sram_rdata      (inst_sram_rdata),    
    .rf_wdata_temp_EX     (rf_wdata_temp_EX),
    .rf_wdata_temp_MEM    (rf_wdata_temp_MEM),
    .ReadData1_ID_current (ReadData1_ID_current),
    .ReadData2_ID_current (ReadData2_ID_current),
    .cp0_status_exl       (cp0_status_exl),

    .PC_ID                (PC_ID),
    .mul_ID               (mul_ID),
    .div_ID               (div_ID),
    .PC_next              (PC_next),
    .ID_valid             (ID_valid),
    .ALUop_ID             (ALUop_ID),
    .Esrc1_ID             (Esrc1_ID),
    .Esrc2_ID             (Esrc2_ID),
    .RegDst_ID            (RegDst_ID),
    .Branch_ID            (Branch_ID),
    .rf_wen_ID            (rf_wen_ID),
    .ID_allowin           (ID_allowin),
    .ALUSrcA_ID           (ALUSrcA_ID),
    .MemRead_ID           (MemRead_ID),
    .ALUSrcB_ID           (ALUSrcB_ID),
    .rf_waddr_ID          (rf_waddr_ID),
    .HI_write_ID          (HI_write_ID),
    .LO_write_ID          (LO_write_ID),
    .MemtoReg_ID          (MemtoReg_ID),
    .ReadData1_ID         (ReadData1_ID),
    .ReadData2_ID         (ReadData2_ID),
    .store_type_ID        (store_type_ID),
    .mul_signed_ID        (mul_signed_ID),
    .div_signed_ID        (div_signed_ID),
    .HI_MemtoReg_ID       (HI_MemtoReg_ID),
    .LO_MemtoReg_ID       (LO_MemtoReg_ID),
    .ID_to_EX_valid       (ID_to_EX_valid),
    .Instruction_ID       (Instruction_ID),
    .data_sram_en_ID      (data_sram_en_ID),
    .data_sram_wen_ID     (data_sram_wen_ID),

    .exception_commit     (exception_commit),
    .eret_cmt             (eret_cmt),
    .mtc0_value           (mtc0_value),
    .mtc0_wen_status      (mtc0_wen_status),
    .mtc0_wen_cause       (mtc0_wen_cause),
    .mtc0_wen_epc         (mtc0_wen_epc)
  );
  
  //###   EX   ###
  EX_stage EX(
    .HI                   (HI),
    .LO                   (LO),
    .clk                  (clk),
    .PC_ID                (PC_ID),
    .resetn               (resetn),
    .mul_ID               (mul_ID),
    .div_ID               (div_ID),
    .EX_valid             (EX_valid),
    .ALUop_ID             (ALUop_ID),
    .rf_wen_ID            (rf_wen_ID),
    .ALUSrcB_ID           (ALUSrcB_ID),
    .EX_allowin           (EX_allowin),
    .ALUSrcA_ID           (ALUSrcA_ID),
    .MemRead_ID           (MemRead_ID),
    .MemtoReg_ID          (MemtoReg_ID),
    .MEM_allowin          (MEM_allowin), 
    .HI_wdata_WB          (HI_wdata_WB),
    .LO_wdata_WB          (LO_wdata_WB),
    .HI_write_ID          (HI_write_ID),
    .LO_write_ID          (LO_write_ID),
    .rf_waddr_ID          (rf_waddr_ID),
    .ReadData1_ID         (ReadData1_ID),
    .ReadData2_ID         (ReadData2_ID),
    .HI_wdata_MEM         (HI_wdata_MEM),
    .LO_wdata_MEM         (LO_wdata_MEM),
    .store_type_ID        (store_type_ID),
    .mul_signed_ID        (mul_signed_ID),
    .div_signed_ID        (div_signed_ID),
    .HI_MemtoReg_ID       (HI_MemtoReg_ID), 
    .LO_MemtoReg_ID       (LO_MemtoReg_ID),
    .HI_MemtoReg_WB       (HI_MemtoReg_WB),
    .LO_MemtoReg_WB       (LO_MemtoReg_WB),
    .ID_to_EX_valid       (ID_to_EX_valid),
    .Instruction_ID       (Instruction_ID),
    .HI_MemtoReg_MEM      (HI_MemtoReg_MEM),
    .LO_MemtoReg_MEM      (LO_MemtoReg_MEM),
    .data_sram_en_ID      (data_sram_en_ID),
    .data_sram_wen_ID     (data_sram_wen_ID),
    .cp0_status           (cp0_status),
    .cp0_cause            (cp0_cause),
    .cp0_epc              (cp0_epc),

    .PC_EX                (PC_EX),
    .Byte_EX              (Byte_EX),
    .rf_wen_EX            (rf_wen_EX),
    .MemRead_EX           (MemRead_EX),
    .HI_wdata_EX          (HI_wdata_EX),
    .LO_wdata_EX          (LO_wdata_EX),
    .rf_waddr_EX          (rf_waddr_EX),
    .MemtoReg_EX          (MemtoReg_EX),
    .HI_write_EX          (HI_write_EX),
    .LO_write_EX          (LO_write_EX),
    .ReadData2_EX         (ReadData2_EX),
    .HI_MemtoReg_EX       (HI_MemtoReg_EX),
    .LO_MemtoReg_EX       (LO_MemtoReg_EX),
    .Instruction_EX       (Instruction_EX),
    .data_sram_en_EX      (data_sram_en_EX),
    .EX_to_MEM_valid      (EX_to_MEM_valid),
    .rf_wdata_temp_EX     (rf_wdata_temp_EX),
    .data_sram_wen_EX     (data_sram_wen_EX),
    .data_sram_addr_EX    (data_sram_addr_EX),
    .data_sram_wdata_EX   (data_sram_wdata_EX)
  );

  //###   MEM   ###
  MEM_stage MEM(
    .clk                  (clk),
    .PC_EX                (PC_EX),
    .resetn               (resetn),
    .Byte_EX              (Byte_EX),
    .rf_wen_EX            (rf_wen_EX),
    .MemRead_EX           (MemRead_EX),
    .WB_allowin           (WB_allowin),
    .rf_waddr_EX          (rf_waddr_EX),
    .MemtoReg_EX          (MemtoReg_EX),
    .HI_wdata_EX          (HI_wdata_EX),
    .LO_wdata_EX          (LO_wdata_EX),
    .HI_write_EX          (HI_write_EX),
    .LO_write_EX          (LO_write_EX),
    .ReadData2_EX         (ReadData2_EX),
    .HI_MemtoReg_EX       (HI_MemtoReg_EX),
    .LO_MemtoReg_EX       (LO_MemtoReg_EX),
    .Instruction_EX       (Instruction_EX),
    .EX_to_MEM_valid      (EX_to_MEM_valid),
    .data_sram_en_EX      (data_sram_en_EX),
    .rf_wdata_temp_EX     (rf_wdata_temp_EX),
    .data_sram_wen_EX     (data_sram_wen_EX),
    .data_sram_addr_EX    (data_sram_addr_EX),
    .data_sram_wdata_EX   (data_sram_wdata_EX),

    .PC_MEM               (PC_MEM),
    .Byte_MEM             (Byte_MEM),
    .MEM_valid            (MEM_valid),
    .rf_wen_MEM           (rf_wen_MEM),
    .MemRead_MEM          (MemRead_MEM),
    .MEM_allowin          (MEM_allowin),
    .HI_write_MEM         (HI_write_MEM),
    .LO_write_MEM         (LO_write_MEM),
    .HI_wdata_MEM         (HI_wdata_MEM),
    .LO_wdata_MEM         (LO_wdata_MEM),
    .rf_waddr_MEM         (rf_waddr_MEM),
    .MemtoReg_MEM         (MemtoReg_MEM),
    .ReadData2_MEM        (ReadData2_MEM),
    .Instruction_MEM      (Instruction_MEM),
    .HI_MemtoReg_MEM      (HI_MemtoReg_MEM),
    .LO_MemtoReg_MEM      (LO_MemtoReg_MEM),
    .MEM_to_WB_valid      (MEM_to_WB_valid),
    .data_sram_en_MEM     (data_sram_en_MEM),
    .rf_wdata_temp_MEM    (rf_wdata_temp_MEM),
    .data_sram_wen_MEM    (data_sram_wen_MEM),
    .data_sram_addr_MEM   (data_sram_addr_MEM),
    .data_sram_wdata_MEM  (data_sram_wdata_MEM)
  );
  
  
  //###   WB   ###
  WB_stage WB(
    .clk                  (clk),
    .resetn               (resetn),
    .PC_MEM               (PC_MEM),
    .Byte_MEM             (Byte_MEM),
    .rf_wen_MEM           (rf_wen_MEM),
    .MemRead_MEM          (MemRead_MEM),
    .HI_wdata_MEM         (HI_wdata_MEM),
    .LO_wdata_MEM         (LO_wdata_MEM),
    .MemtoReg_MEM         (MemtoReg_MEM),
    .rf_waddr_MEM         (rf_waddr_MEM),
    .HI_write_MEM         (HI_write_MEM),
    .LO_write_MEM         (LO_write_MEM),
    .ReadData2_MEM        (ReadData2_MEM),
    .MEM_to_WB_valid      (MEM_to_WB_valid),
    .data_sram_rdata      (data_sram_rdata),
    .Instruction_MEM      (Instruction_MEM),
    .HI_MemtoReg_MEM      (HI_MemtoReg_MEM),
    .LO_MemtoReg_MEM      (LO_MemtoReg_MEM),
    .rf_wdata_temp_MEM    (rf_wdata_temp_MEM),
  
    .PC_WB                (PC_WB),
    .rf_wdata             (rf_wdata),
    .WB_valid             (WB_valid),
    .rf_wen_WB            (rf_wen_WB),
    .MemRead_WB           (MemRead_WB),
    .WB_allowin           (WB_allowin),
    .HI_write_WB          (HI_write_WB),
    .LO_write_WB          (LO_write_WB),
    .MemtoReg_WB          (MemtoReg_WB),
    .HI_wdata_WB          (HI_wdata_WB),
    .LO_wdata_WB          (LO_wdata_WB),
    .rf_waddr_WB          (rf_waddr_WB),
    .HI_MemtoReg_WB       (HI_MemtoReg_WB),
    .LO_MemtoReg_WB       (LO_MemtoReg_WB),
    .Instruction_WB       (Instruction_WB)
  );
  
  //reg file
  reg_file  Resigters(
    .clk                  (clk),
    .wen                  (rf_wen_WB),
    .resetn               (resetn),
    .wdata                (rf_wdata),
    .raddr1               (Esrc1_ID),
    .raddr2               (Esrc2_ID), 
    .waddr                (rf_waddr_WB),  
    .rdata1               (ReadData1_ID_current),
    .rdata2               (ReadData2_ID_current)
  );

endmodule