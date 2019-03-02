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

  //### HI LO ###
  reg  [31:0] HI;
  reg  [31:0] LO;
  
  //###  IF  ###
  reg  [31:0] PC_IF;  
  wire IF_allowin;
  wire IF_ready_go;
  wire IF_to_ID_valid;
  
  //###  ID  ###
  reg  ID_valid;
  reg  [31:0] PC_ID;
  
  wire mul_ID;
  wire div_ID;
  wire validin;
  wire ID_allowin;
  wire MemRead_ID;
  wire ALUSrcA_ID;
  wire ID_ready_go;
  wire MemWrite_ID;
  wire HI_write_ID;
  wire LO_write_ID;
  wire is_Branch_ID;
  wire mul_signed_ID;
  wire div_signed_ID;
  wire ID_to_EX_valid;
  wire load_to_use_EX;
  wire load_to_use_MEM;
  wire data_sram_en_ID;
  wire [ 1:0] Jump_ID;
  wire [ 4:0] Esrc1_ID;
  wire [ 4:0] Esrc2_ID;
  wire [ 3:0] ALUop_ID;
  wire [ 3:0] rf_wen_ID;
  wire [ 1:0] RegDst_ID; 
  wire [ 2:0] Branch_ID;
  wire [ 1:0] ALUSrcB_ID;
  wire [ 3:0] MemtoReg_ID;
  wire [ 4:0] rf_waddr_ID;
  wire [ 3:0] data_sram_wen_ID;
  wire [31:0] ReadData1_ID;
  wire [31:0] ReadData2_ID;
  wire [ 1:0] HI_MemtoReg_ID;
  wire [ 1:0] LO_MemtoReg_ID;
  wire [31:0] Instruction_ID;
  wire [31:0] ReadData1_ID_current;
  wire [31:0] ReadData2_ID_current;

  //###  EX  ###
  reg  mul_EX;
  reg  div_EX;
  reg  EX_valid;
  reg  count_EX;
  reg  ALUSrcA_EX;
  reg  MemRead_EX;
  reg  HI_write_EX;
  reg  LO_write_EX;
  reg  mul_signed_EX;
  reg  div_signed_EX;
  reg  data_sram_en_EX;  
  reg  [31:0] PC_EX;
  reg  [ 3:0] ALUop_EX;
  reg  [ 2:0] Branch_EX;
  reg  [ 3:0] rf_wen_EX;
  reg  [ 1:0] ALUSrcB_EX;
  reg  [ 4:0] rf_waddr_EX;
  reg  [ 3:0] MemtoReg_EX;
  reg  [31:0] ReadData1_EX;
  reg  [31:0] ReadData2_EX;
  reg  [ 1:0] HI_MemtoReg_EX;
  reg  [ 1:0] LO_MemtoReg_EX;
  reg  [31:0] Instruction_EX;
  reg  [ 3:0] data_sram_wen_EX;

  wire Zero_EX;
  wire EX_ready_go;
  wire EX_allowin;
  wire Overflow1_EX;
  wire CarryOut1_EX;
  wire div_complete;
  wire mul_complete;
  wire EX_to_MEM_valid;
  wire [31:0] s_EX;
  wire [31:0] r_EX;
  wire [31:0] HI_wdata_EX;
  wire [31:0] LO_wdata_EX;
  wire [31:0] AluInput1_EX;
  wire [31:0] AluInput2_EX;
  wire [31:0] ALU_result_EX;
  wire [63:0] mul_result_EX;
  wire [31:0] rf_wdata_temp_EX;
  wire [31:0] data_sram_wdata_EX;               

  //###  MEM  ###
  reg  mul_MEM;
  reg  div_MEM;
  reg  MEM_valid;
  reg  MemRead_MEM;
  reg  HI_write_MEM;
  reg  LO_write_MEM;
  reg  data_sram_en_MEM;
  reg  [31:0] PC_MEM;
  reg  [ 3:0] rf_wen_MEM;
  reg  [ 4:0] rf_waddr_MEM;
  reg  [ 3:0] MemtoReg_MEM;
  reg  [31:0] HI_wdata_MEM;
  reg  [31:0] LO_wdata_MEM;
  reg  [31:0] ALU_result_MEM;
  reg  [31:0] Instruction_MEM;
  reg  [ 1:0] LO_MemtoReg_MEM;
  reg  [ 1:0] HI_MemtoReg_MEM;
  reg  [31:0] rf_wdata_temp_MEM;
  reg  [ 3:0] data_sram_wen_MEM;
  reg  [31:0] data_sram_wdata_MEM;
  
  wire MEM_allowin;
  wire MEM_ready_go;
  wire MEM_to_WB_valid;
  wire [31:0] rf_wdata;

  //###  WB  ###
  reg  mul_WB;
  reg  div_WB;
  reg  WB_valid;
  reg  HI_write_WB;
  reg  LO_write_WB;
  reg  [31:0] PC_WB;
  reg  [ 3:0] rf_wen_WB;
  reg  [31:0] HI_wdata_WB;
  reg  [31:0] LO_wdata_WB;
  reg  [ 4:0] rf_waddr_WB;
  reg  [ 3:0] MemtoReg_WB;
  reg  [31:0] Instruction_WB;
  reg  [ 1:0] LO_MemtoReg_WB;
  reg  [ 1:0] HI_MemtoReg_WB;
  reg  [31:0] rf_wdata_temp_WB;
  
  wire WB_allowin;
  wire WB_ready_go;
  
  //###   Inst Output ###
  assign inst_sram_en    = (!resetn)?       1'b0:
                           (!ID_allowin)?   1'b0:
                                            1'b1;
  assign inst_sram_wen   = 4'b0;
  assign inst_sram_addr  = PC_IF;
  assign inst_sram_wdata = 32'b0;
  //###   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ###
  //###   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ######   IF   ###
   
   
  //###   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ###  
  assign validin         = resetn;
  assign ID_ready_go     = ~(load_to_use_EX || load_to_use_MEM);
  assign ID_allowin      = !ID_valid || (ID_ready_go && EX_allowin);
  assign ID_to_EX_valid  = ID_valid && ID_ready_go; 
  
  always @ (posedge clk) begin
  if(!resetn)
    ID_valid <= 1'b0;
  else if(ID_allowin)
    ID_valid <= 1'b1;
    
  if(validin && ID_allowin)
  	PC_ID <= PC_IF;
  end
  
  assign load_to_use_EX  = MemRead_EX  && ((Esrc1_ID == rf_waddr_EX  || Esrc2_ID == rf_waddr_EX ) && EX_valid ) && rf_wen_EX  != 4'b0;
  assign load_to_use_MEM = MemRead_MEM && ((Esrc1_ID == rf_waddr_MEM || Esrc2_ID == rf_waddr_MEM) && MEM_valid) && rf_wen_MEM != 4'b0;

  assign Instruction_ID  = inst_sram_rdata;
                   
  assign data_sram_en_ID = MemRead_ID | MemWrite_ID;

  assign rf_waddr_ID     = (RegDst_ID == 2'b00)? Instruction_ID[20:16]:
                           (RegDst_ID == 2'b01)? Instruction_ID[15:11]:
                           (RegDst_ID == 2'b10)? 5'b11111:
                                                 5'b00000;
                         
  assign is_Branch_ID    = ( (Branch_ID==3'b001 && (ReadData1_ID == ReadData2_ID)) ||
                             (Branch_ID==3'b010 && (ReadData1_ID != ReadData2_ID)) )?                 1'b1 : 1'b0;  //beq bne 

  assign Esrc1_ID        = Instruction_ID[25:21];
  assign Esrc2_ID        = Instruction_ID[20:16];
                                                                             
  assign ReadData1_ID    = (Esrc1_ID == rf_waddr_EX  && rf_wen_EX  != 4'b0 && MemRead_EX  != 1'b1)?   rf_wdata_temp_EX:
                           (Esrc1_ID == rf_waddr_EX  && rf_wen_EX  != 4'b0 && MemRead_EX  == 1'b1)?   data_sram_rdata:
                           (Esrc1_ID == rf_waddr_EX  && MemtoReg_EX == 4'b1011)?                      rf_wdata_temp_EX:
                           (Esrc1_ID == rf_waddr_EX  && MemtoReg_EX == 4'b1100)?                      rf_wdata_temp_EX:
                           (Esrc1_ID == rf_waddr_MEM && rf_wen_MEM != 4'b0 && MemRead_MEM != 1'b1)?   rf_wdata_temp_MEM:
                           (Esrc1_ID == rf_waddr_MEM && rf_wen_MEM != 4'b0 && MemRead_MEM == 1'b1)?   data_sram_rdata:
                           (Esrc1_ID == rf_waddr_MEM && MemtoReg_MEM == 4'b1011)?                     rf_wdata_temp_MEM:
                           (Esrc1_ID == rf_waddr_MEM && MemtoReg_MEM == 4'b1100)?                     rf_wdata_temp_MEM:
                           (Esrc1_ID == rf_waddr_WB  && rf_wen_WB  != 4'b0)?                          rf_wdata:
                           (Esrc1_ID == rf_waddr_WB  && MemtoReg_WB == 4'b1011)?                      rf_wdata:
                           (Esrc1_ID == rf_waddr_WB  && MemtoReg_WB == 4'b1100)?                      rf_wdata:
                                                                                                      ReadData1_ID_current;

  assign ReadData2_ID    = (Esrc2_ID == rf_waddr_EX  && rf_wen_EX  != 4'b0 && MemRead_EX  != 1'b1)?   rf_wdata_temp_EX:
                           (Esrc2_ID == rf_waddr_EX  && rf_wen_EX  != 4'b0 && MemRead_EX  == 1'b1)?   data_sram_rdata:
                           (Esrc2_ID == rf_waddr_EX  && MemtoReg_EX == 4'b1011)?                      rf_wdata_temp_EX:
                           (Esrc2_ID == rf_waddr_EX  && MemtoReg_EX == 4'b1100)?                      rf_wdata_temp_EX:
                           (Esrc2_ID == rf_waddr_MEM && rf_wen_MEM != 4'b0 && MemRead_MEM != 1'b1)?   rf_wdata_temp_MEM:
                           (Esrc2_ID == rf_waddr_MEM && rf_wen_MEM != 4'b0 && MemRead_MEM == 1'b1)?   data_sram_rdata:
                           (Esrc2_ID == rf_waddr_MEM && MemtoReg_MEM == 4'b1011)?                     rf_wdata_temp_MEM:
                           (Esrc2_ID == rf_waddr_MEM && MemtoReg_MEM == 4'b1100)?                     rf_wdata_temp_MEM:
                           (Esrc2_ID == rf_waddr_WB  && rf_wen_WB  != 4'b0)?                          rf_wdata:
                           (Esrc2_ID == rf_waddr_WB  && MemtoReg_WB == 4'b1011)?                      rf_wdata:
                           (Esrc2_ID == rf_waddr_WB  && MemtoReg_WB == 4'b1100)?                      rf_wdata:
                                                                                                      ReadData2_ID_current;
  //###   PC   ###
   wire [31:0] PC_next;
   always @(posedge clk) begin
     if(!resetn)
       PC_IF <= 32'hbfc00000;
     else if(ID_allowin)
       PC_IF <= PC_next;
   end      
                                         
  assign PC_next = (Jump_ID == 2'b01 )?       {PC_ID[31:28], Instruction_ID[25:0],1'b0,1'b0}:                            //j jal
                   (Jump_ID == 2'b10 )?       ReadData1_ID:                                                              //jr jalr
                   (is_Branch_ID == 1'b1)?    PC_ID + { {15{Instruction_ID[15]}}, Instruction_ID[14:0], 2'b00 } + 32'd4: //beq bne bgez blez bltz bgtz
                                              PC_IF + 31'd4;                                                              
  //###   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ######   ID   ###
  
  
  
  //###   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ###   
  assign EX_ready_go          = (mul_EX && !count_EX    )?   1'b0:
                                (div_EX && !div_complete)?   1'b0:
                                                             1'b1;
                                                                                                                                       
  assign EX_allowin           = !EX_valid || (EX_ready_go && MEM_allowin);
  assign EX_to_MEM_valid      = EX_valid && EX_ready_go;
  
  always @ (posedge clk) begin
    if(!resetn || !mul_EX) begin
      count_EX <= 1'b0;
    end
    else if(mul_EX)
      count_EX <= count_EX + 1'b1;
  end
  
  always @ (posedge clk) begin
    if(!resetn) 
      EX_valid <= 1'b0;
    else if(EX_allowin)
      EX_valid <= ID_to_EX_valid;
  end
  
  always @ (posedge clk) begin
    if(!resetn) begin
      rf_waddr_EX     <= 5'b0;
      rf_wen_EX       <= 4'b0;
      MemtoReg_EX     <= 4'b0;
    end   
    else if(ID_to_EX_valid && EX_allowin) begin
      PC_EX           <= PC_ID;
      mul_EX          <= mul_ID;
      div_EX          <= div_ID;
      ALUop_EX        <= ALUop_ID;
      rf_wen_EX       <= rf_wen_ID;
      MemRead_EX      <= MemRead_ID;
      MemtoReg_EX     <= MemtoReg_ID;
      rf_waddr_EX     <= rf_waddr_ID;
      mul_signed_EX   <= mul_signed_ID;
      div_signed_EX   <= div_signed_ID;
      Instruction_EX  <= Instruction_ID;
      data_sram_en_EX <= data_sram_en_ID;
      data_sram_wen_EX<= data_sram_wen_ID;
      ReadData1_EX    <= ReadData1_ID;
      ReadData2_EX    <= ReadData2_ID;
      
      HI_write_EX     <= HI_write_ID;
      LO_write_EX     <= LO_write_ID;
      HI_MemtoReg_EX  <= HI_MemtoReg_ID;
      LO_MemtoReg_EX  <= LO_MemtoReg_ID;
      ALUSrcA_EX      <= ALUSrcA_ID;
      ALUSrcB_EX      <= ALUSrcB_ID;
    end
  end

  assign data_sram_wdata_EX = ReadData2_EX;      //sb  sh   swl   swe ..............................

  assign rf_wdata_temp_EX   = (MemtoReg_EX == 4'b0000)?                             ALU_result_EX:
                              (MemtoReg_EX == 4'b0010)?                             PC_EX + 32'd8:                   //jal jalr
                              (MemtoReg_EX == 4'b0011)?                             {Instruction_EX[15:0],16'b0}:    //lui
                              (MemtoReg_EX == 4'b1011)?  (
                              (div_MEM || mul_MEM || HI_MemtoReg_MEM == 2'b10)?     HI_wdata_MEM:
                              (div_WB  || mul_WB  || HI_MemtoReg_WB  == 2'b10)?     HI_wdata_WB:
                                                         HI):
                              (MemtoReg_EX == 4'b1100)?  (
                              (div_MEM || mul_MEM || LO_MemtoReg_MEM == 2'b10)?     LO_wdata_MEM:
                              (div_WB  || mul_WB  || LO_MemtoReg_WB  == 2'b10)?     LO_wdata_WB:
                                                         LO):
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
                                                       
  //###   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ######   EX   ###
 
 

  //###   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ###
  assign MEM_ready_go      = 1'b1;
  assign MEM_allowin       = !MEM_valid || (MEM_ready_go && WB_allowin);
  assign MEM_to_WB_valid   = MEM_valid && MEM_ready_go;

  always @ (posedge clk) begin
    if(!resetn)
      MEM_valid    <= 1'b0;
    else if(MEM_allowin)
      MEM_valid    <= EX_to_MEM_valid;
   end

  always @ (posedge clk) begin
    if(!resetn) begin
      rf_wen_MEM          <= 4'b0;
      MemRead_MEM         <= 1'b0;
      rf_waddr_MEM        <= 5'b0;
      MemtoReg_MEM        <= 4'b0;
    end  
    else if(EX_to_MEM_valid && MEM_allowin) begin
      PC_MEM              <= PC_EX;
      mul_MEM             <= mul_EX;
      div_MEM             <= div_EX;
      rf_wen_MEM          <= rf_wen_EX;
      MemRead_MEM         <= MemRead_EX;
      rf_waddr_MEM        <= rf_waddr_EX;
      MemtoReg_MEM        <= MemtoReg_EX;
      HI_write_MEM        <= HI_write_EX;
      LO_write_MEM        <= LO_write_EX;
      HI_wdata_MEM        <= HI_wdata_EX;
      LO_wdata_MEM        <= LO_wdata_EX;
      ALU_result_MEM      <= ALU_result_EX;
      Instruction_MEM     <= Instruction_EX;
      HI_MemtoReg_MEM     <= HI_MemtoReg_EX;
      LO_MemtoReg_MEM     <= LO_MemtoReg_EX;
      data_sram_en_MEM    <= data_sram_en_EX;
      data_sram_wen_MEM   <= data_sram_wen_EX;
      rf_wdata_temp_MEM   <= rf_wdata_temp_EX;
      data_sram_wdata_MEM <= data_sram_wdata_EX;
    end
  end
  
  assign data_sram_en     =  data_sram_en_MEM;
  assign data_sram_wen    =  data_sram_wen_MEM;
  assign data_sram_wdata  =  data_sram_wdata_MEM;
  assign data_sram_addr   = {ALU_result_MEM[31:2], 2'b00}; 
  //###   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ######   MEM  ###

                                                  
                                                  
  //###   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ###
  assign WB_ready_go     = 1'b1;
  assign WB_allowin      = !WB_valid || WB_ready_go;
  
  always @ (posedge clk) begin
    if(!resetn)
      WB_valid         <= 1'b0;
    else if(WB_allowin)
      WB_valid         <= MEM_to_WB_valid;
  end

  always @ (posedge clk) begin
    if(!resetn) begin
      rf_waddr_WB      <= 5'b0;
      rf_wen_WB        <= 4'b0;
      MemtoReg_WB      <= 4'b0;
    end
    else if(MEM_to_WB_valid && WB_allowin) begin
      PC_WB            <= PC_MEM;
      mul_WB           <= mul_MEM;
      div_WB           <= div_MEM;
      rf_wen_WB        <= rf_wen_MEM;
      rf_waddr_WB      <= rf_waddr_MEM;
      MemtoReg_WB      <= MemtoReg_MEM;
      HI_write_WB      <= HI_write_MEM;
      LO_write_WB      <= LO_write_MEM;
      HI_wdata_WB      <= HI_wdata_MEM;
      LO_wdata_WB      <= LO_wdata_MEM;
      Instruction_WB   <= Instruction_MEM;
      HI_MemtoReg_WB   <= HI_MemtoReg_MEM;
      LO_MemtoReg_WB   <= LO_MemtoReg_MEM;
      rf_wdata_temp_WB <= rf_wdata_temp_MEM;
    end
  end
  
  always @ (posedge clk) begin  //write HI and LO
    if(HI_write_WB)
      HI               <= HI_wdata_WB;
    if(LO_write_WB)
      LO               <= LO_wdata_WB;
  end
  assign rf_wdata      = (MemtoReg_WB == 4'b0001)?    data_sram_rdata:               //lw
                                                      rf_wdata_temp_WB;
  //###   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ######   WB   ###
                                                                 
                                                                
  //###   Debug   ###
  assign debug_wb_pc       = PC_WB;
  assign debug_wb_rf_wen   = (WB_valid)?   rf_wen_WB : 4'B0;
  assign debug_wb_rf_wnum  = rf_waddr_WB;
  assign debug_wb_rf_wdata = rf_wdata;
  
	//cpu_control
  cpu_control  control(.resetn(resetn),
                       .op(Instruction_ID[31:26]),
                       .rt(Instruction_ID[20:16]),
                       .func(Instruction_ID[5:0]),
                       
                       .mul(mul_ID),
                       .div(div_ID),
                       .HI_MemtoReg(HI_MemtoReg_ID),
                       .LO_MemtoReg(LO_MemtoReg_ID),
                       .HI_write(HI_write_ID),
                       .LO_write(LO_write_ID),
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
                       .data_sram_wen(data_sram_wen_ID),
                       .mul_signed(mul_signed_ID),
                       .div_signed(div_signed_ID));
	//reg file
  reg_file  Resigters(.clk(clk),
                      .resetn(resetn),
                      .waddr(rf_waddr_WB),
                      .raddr1(Esrc1_ID),
                      .raddr2(Esrc2_ID),
                      .wen(rf_wen_WB),
                      .wdata(rf_wdata),
                      .rdata1(ReadData1_ID_current),
                      .rdata2(ReadData2_ID_current));
	//ALU
  alu  alu_op(.A(AluInput1_EX),
              .B(AluInput2_EX),
              .ALUop(ALUop_EX),
              .Overflow(Overflow1_EX),
              .CarryOut(CarryOut1_EX),
              .Zero(Zero_EX),
              .Result(ALU_result_EX));
              
  //mul     
  mult mult(.mul_clk(clk),
            .resetn(resetn),
            .mul_signed(mul_signed_EX),
            .x(ReadData1_EX),
            .y(ReadData2_EX),

            .result(mul_result_EX));
  
  //div
  div div(.div_clk(clk),
          .resetn(resetn),
          .div(div_EX),
          .div_signed(div_signed_EX),
          .x(ReadData1_EX),
          .y(ReadData2_EX),
          
          .s(s_EX),
          .r(r_EX),
          .complete(div_complete)
  );
  
endmodule