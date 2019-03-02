`timescale 1ns / 1ps

module ID_stage(
  input  wire clk,
  input  wire resetn,
  input  wire EX_valid,
  input  wire MEM_valid,
  input  wire WB_valid,
  input  wire EX_allowin,
  input  wire MemRead_EX,
  input  wire MemRead_WB,
  input  wire MemRead_MEM,
  input  wire [31:0] PC_IF,
  input  wire [31:0] rf_wdata,
  input  wire [03:0] rf_wen_EX,
  input  wire [03:0] rf_wen_WB,
  input  wire [03:0] rf_wen_WB_i,
  input  wire [03:0] rf_wen_MEM,
  input  wire [03:0] MemtoReg_EX,
  input  wire [03:0] MemtoReg_WB,
  input  wire [04:0] rf_waddr_EX,
  input  wire [04:0] rf_waddr_WB,
  input  wire [04:0] rf_waddr_MEM,
  input  wire [03:0] MemtoReg_MEM,
  input  wire        IF_to_ID_valid,
  input  wire [31:0] inst_rdata,
  input  wire [31:0] rf_wdata_temp_EX,
  input  wire [31:0] rf_wdata_temp_MEM,
  input  wire [31:0] ReadData1_ID_current,
  input  wire [31:0] ReadData2_ID_current,
  input  wire cp0_status_exl,
  input  wire exception_commit,
  input  wire [31:0] cp0_epc,
  input  wire exe_bad_PC_IF,
  input  wire exception_commit_i_IF,
  
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
  output reg  [31:0] Instruction_ID,
  output wire [03:0] data_sram_wen_ID,

  output wire eret_cmt,
  output wire [31:0] mtc0_value_ID,

  output wire mtc0_wen_status_ID,
  output wire mtc0_wen_cause_ID,
  output wire mtc0_wen_epc_ID,
  output wire mtc0_wen_count_ID,
  output wire mtc0_wen_compare_ID,

  output wire exe_syscall_ID,
  output wire exe_break_ID,
  output wire exe_ri_ID,
  output reg  exe_bad_PC_ID,
  output wire is_ADD_ADDI_SUB_ID,
  output reg  is_delay_slot_ID,
  
  input wire inst_data_ok
);

//  wire validin;
  wire ID_ready_go;
  wire MemWrite_ID;
  wire is_Branch_ID;
  wire load_to_use_EX;
  wire load_to_use_MEM;
  wire load_to_use_WB;
  wire [1:0] Jump_ID;
  wire inst_SYSCALL;
  wire inst_BREAK;
  wire exe_find_syscall;
  wire exe_find_break;
  wire is_BJ;
  wire RI;
  wire mtc0_wen_status;
  wire mtc0_wen_cause;
  wire mtc0_wen_epc;
  wire mtc0_wen_count;
  wire mtc0_wen_compare;
  wire [ 3:0] rf_wen;

  reg [31:0] inst_rdata_i;
  assign ID_ready_go     = ~(load_to_use_EX || load_to_use_MEM || load_to_use_WB);
  assign ID_allowin      = !ID_valid || (ID_ready_go && EX_allowin);
  assign ID_to_EX_valid  =  ID_valid && ID_ready_go;
  
  always @(posedge clk) begin
    if(!resetn) begin
      inst_rdata_i      <= 32'b0;
    end
    else if(IF_to_ID_valid && ID_allowin) begin
      inst_rdata_i      <= 32'b0;
    end
    else if(inst_data_ok) begin
      inst_rdata_i      <= inst_rdata;
    end
  end

  reg next_miss;
  reg [31:0] miss_PC;
  always @ (posedge clk) begin
    if(!resetn)
      next_miss <= 1'b0;
    else if(IF_to_ID_valid && ID_allowin)
      next_miss <= 1'b0;
    else if( ID_valid && !(exception_commit && cp0_status_exl == 1'b0) && !eret_cmt && Jump_ID != 2'b01 && Jump_ID != 2'b10 && is_Branch_ID != 1'b01)
      next_miss <= 1'b0;
    else if( (exception_commit && cp0_status_exl == 1'b0) || eret_cmt || ( (Jump_ID == 2'b01 || Jump_ID == 2'b10 || is_Branch_ID == 1'b01) && ID_valid) ) begin
      next_miss <= 1'b1;
      miss_PC   <= PC_next;
    end
  end
  
  
  always @ (posedge clk) begin
    if(!resetn)
      ID_valid             <= 1'b0;
    else if( (exception_commit && cp0_status_exl == 1'b0 && ID_allowin)  ||  ( eret_cmt && PC_next[1:0] != 2'b0)  )
      ID_valid             <= 1'b0;
    else if(ID_allowin) begin
      ID_valid             <= (exception_commit_i_IF)?   1'b0:
                                                         IF_to_ID_valid;
    end
  
    if(!resetn) begin 
      PC_ID                <= 32'h0;
      Instruction_ID       <= 32'h0;
    end
    if(IF_to_ID_valid && ID_allowin) begin
      PC_ID                <= PC_IF;
      Instruction_ID       <= (PC_IF[1:0] != 2'b0)?     32'b0:
                              (inst_data_ok      )?     inst_rdata:
                                                         inst_rdata_i;
    end 
  
    if(is_BJ)
      is_delay_slot_ID     <= 1'b1;
    else
      is_delay_slot_ID     <= 1'b0;
  end

  always @ (posedge clk) begin
    if(!resetn)
      exe_bad_PC_ID             <= 1'b0;
    else
      exe_bad_PC_ID             <= exe_bad_PC_IF;
  end
  
  assign load_to_use_EX  = MemRead_EX  && ((Esrc1_ID == rf_waddr_EX  || Esrc2_ID == rf_waddr_EX ) && EX_valid ) && rf_wen_EX   != 4'b0 && exception_commit == 1'b0;
  assign load_to_use_MEM = MemRead_MEM && ((Esrc1_ID == rf_waddr_MEM || Esrc2_ID == rf_waddr_MEM) && MEM_valid) && rf_wen_MEM  != 4'b0 && exception_commit == 1'b0;
  assign load_to_use_WB  = MemRead_WB  && ((Esrc1_ID == rf_waddr_WB  || Esrc2_ID == rf_waddr_WB ) && WB_valid ) && rf_wen_WB_i != 4'b0 && exception_commit == 1'b0 && rf_wen_WB == 4'b0;

  assign data_sram_en_ID = MemRead_ID || MemWrite_ID;

  assign rf_waddr_ID     = (RegDst_ID == 2'b00)?   Instruction_ID[20:16]:
                           (RegDst_ID == 2'b01)?   Instruction_ID[15:11]:
                           (RegDst_ID == 2'b10)?   5'b11111:
                                                   5'b00000;

  assign is_Branch_ID    =   (!ID_valid)?                                                                                          1'b0:
                           ( (Branch_ID==3'b001 && (ReadData1_ID     == ReadData2_ID                               )) ||                    // beq
                             (Branch_ID==3'b010 && (ReadData1_ID     != ReadData2_ID                               )) ||                    // bne
                             (Branch_ID==3'b011 && (ReadData1_ID[31] == 01'b0                                      )) ||                    // bgez
                             (Branch_ID==3'b101 && (ReadData1_ID[31] == 01'b1                                      )) ||                    // bltz bltzal
                             (Branch_ID==3'b110 && (ReadData1_ID     != 32'b0          && ReadData1_ID[31] == 1'b0 )) ||                    // bgtz
                             (Branch_ID==3'b100 && (ReadData1_ID     == 32'b0          || ReadData1_ID[31] == 1'b1 )) )?           1'b1:    // blez 
                                                                                                                                   1'b0;
 
  assign Esrc1_ID        =  Instruction_ID[25:21];
  assign Esrc2_ID        =  Instruction_ID[20:16];

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

  assign mtc0_value_ID   = ReadData2_ID;

  //###   PC   ###
  wire [01:0] Jump;
  assign Jump_ID         = (ID_valid)?      Jump:
                                            2'b0;

  assign PC_next         = (exception_commit && cp0_status_exl == 1'b0)?        32'hbfc00380:
                           (eret_cmt)?                                          cp0_epc:
                           (next_miss)?                                         miss_PC:
                           (Jump_ID      == 2'b01)?                            {PC_ID[31:28], Instruction_ID[25:0], 2'b00}:                                 // j jal
                           (Jump_ID      == 2'b10)?                             ReadData1_ID:                                                              // jr jalr
                           (is_Branch_ID == 1'b01)?                             PC_ID + { {15{Instruction_ID[15]}}, Instruction_ID[14:0], 2'b00 } + 32'd4: // beq bne bgez blez bltz bgtz 
                                                                                PC_IF + 32'd4;

  assign rf_wen_ID       = (ID_valid)?                                          rf_wen:
                                                                                4'b0;

  assign exe_syscall_ID      =  inst_SYSCALL && ID_valid;
  assign exe_break_ID        =  inst_BREAK && ID_valid;
  assign exe_ri_ID           =  RI && ID_valid;
  
  assign mtc0_wen_status_ID  =  mtc0_wen_status  && ID_valid;
  assign mtc0_wen_cause_ID   =  mtc0_wen_cause   && ID_valid;
  assign mtc0_wen_epc_ID     =  mtc0_wen_epc     && ID_valid;
  assign mtc0_wen_count_ID   =  mtc0_wen_count   && ID_valid;
  assign mtc0_wen_compare_ID =  mtc0_wen_compare && ID_valid;

  //cpu_control
  cpu_control  control(
    .resetn        (resetn),
    .op            (Instruction_ID[31:26]),
    .rs            (Instruction_ID[25:21]),
    .rt            (Instruction_ID[20:16]),
    .rd            (Instruction_ID[15:11]),
    .func          (Instruction_ID[5:0]),
  
    .mul           (mul_ID),
    .div           (div_ID),
    .Jump          (Jump),
    .ALUop         (ALUop_ID),
    .rf_wen        (rf_wen),
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
    .data_sram_wen (data_sram_wen_ID),
    
    .inst_SYSCALL  (inst_SYSCALL),
    .inst_BREAK    (inst_BREAK),
    .RI            (RI),
    .eret_cmt      (eret_cmt),
    .mtc0_wen_status  (mtc0_wen_status),
    .mtc0_wen_cause   (mtc0_wen_cause),
    .mtc0_wen_epc     (mtc0_wen_epc),
    .mtc0_wen_count   (mtc0_wen_count),
    .mtc0_wen_compare (mtc0_wen_compare),
    .is_ADD_ADDI_SUB  (is_ADD_ADDI_SUB_ID),
    .is_BJ            (is_BJ)
  );
endmodule