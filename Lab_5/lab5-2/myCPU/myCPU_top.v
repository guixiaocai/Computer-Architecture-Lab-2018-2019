`timescale 10ns / 1ns

module mycpu_top( 
    input  [ 5:0]  int, //high active

    input          aclk,
    input          aresetn,  //low active

    //axi
    //ar
    output [ 3:0] arid,
    output [31:0] araddr,
    output [ 7:0] arlen,
    output [ 2:0] arsize,
    output [ 1:0] arburst,
    output [ 1:0] arlock,
    output [ 3:0] arcache,
    output [ 2:0] arprot,
    output        arvalid,
    input         arready,
    //r
    input  [ 3:0] rid,
    input  [31:0] rdata,
    input  [ 1:0] rresp,
    input         rlast,
    input         rvalid,
    output        rready,
    //aw
    output [ 3:0] awid,
    output [31:0] awaddr,
    output [ 7:0] awlen,
    output [ 2:0] awsize,
    output [ 1:0] awburst,
    output [ 1:0] awlock,
    output [ 3:0] awcache,
    output [ 2:0] awprot,
    output        awvalid,
    input         awready,
    //w
    output [ 3:0] wid,
    output [31:0] wdata,
    output [ 3:0] wstrb,
    output        wlast,
    output        wvalid,
    input         wready,
    //b
    input  [ 3:0] bid,
    input  [ 1:0] bresp,
    input         bvalid,
    output        bready,

    //debug interface
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
  
  //###   CP0   ###
  reg  [31:0] cp0_count;
  reg  [31:0] cp0_compare;
  reg  [31:0] cp0_badvaddr;

  //  ## Exception ##
  wire exception_commit;
  wire eret_cmt;
  wire is_delay_slot_ID;
  wire is_delay_slot_EX;
  
  wire [31:0] mtc0_value_ID;
  wire mtc0_wen_status_ID;
  wire mtc0_wen_cause_ID;
  wire mtc0_wen_epc_ID;
  wire mtc0_wen_count_ID;
  wire mtc0_wen_compare_ID;
  
  wire [31:0] mtc0_value_EX;
  wire mtc0_wen_status_EX;
  wire mtc0_wen_cause_EX;
  wire mtc0_wen_epc_EX;
  wire mtc0_wen_count_EX;
  wire mtc0_wen_compare_EX;

  wire exe_syscall_ID;
  wire exe_break_ID;
  wire exe_ri_ID;
  wire exe_bad_PC_ID;

  wire exe_int_EX;
  wire exe_syscall_EX;
  wire exe_break_EX;
  wire exe_ri_EX;
  wire exe_bad_PC_EX;
  wire exe_badvaddr_S_EX;
  wire exe_badvaddr_L_EX;
  wire exe_overflow_EX;
 
  //###  IF  ###
  wire [31:0] PC_IF;
  wire [31:0] PC_next;
  wire        IF_to_ID_valid;
  wire        exception_commit_i_IF;

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
  wire is_ADD_ADDI_SUB_ID;

  //###  EX  ###
  wire EX_valid;
  wire EX_allowin;
  wire MemRead_EX;
  wire HI_write_EX;
  wire LO_write_EX;
  wire [ 2:0] store_type_EX;

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
  wire [31:0] ALU_result_EX;
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
  wire [03:0] rf_wen_WB_i;

  //###  AXI  ###
    //------inst sram-like-------
    wire        inst_req    ;
    wire        inst_wr     ;
    wire [ 1:0] inst_size   ;
    wire [31:0] inst_addr   ;
    wire [31:0] inst_wdata  ;
    wire [31:0] inst_rdata  ;
    wire        inst_addr_ok;
    wire        inst_data_ok;
    
    //------data sram-like-------
    wire        data_req    ;
    wire        data_wr     ;
    wire [ 2:0] data_size   ;
    wire [31:0] data_addr   ;
    wire [31:0] data_wdata  ;
    wire [31:0] data_rdata  ;
    wire        data_addr_ok;
    wire        data_data_ok;
    
  wire clk;
  wire resetn;
  assign clk = aclk;
  assign resetn = aresetn;

  wire exe_bad_PC_IF;
  assign exe_bad_PC_IF   = ( PC_IF[1:0] != 2'b0 );
  
  // write HI and LO
  always @ (posedge clk) begin  
    if(HI_write_WB)
      HI                <= HI_wdata_WB;
    if(LO_write_WB)
      LO                <= LO_wdata_WB;
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
    else if(mtc0_wen_status_EX && EX_valid)
    begin
      cp0_status_im  <= mtc0_value_EX[15:8];   
      cp0_status_exl <= mtc0_value_EX[1];
      cp0_status_ie  <= mtc0_value_EX[0];
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

   wire   timer_int, count_cmp_eq;
   assign timer_int = cp0_cause_ti;
   assign count_cmp_eq = cp0_count == cp0_compare;
 
  always @ (posedge clk) begin
    if(!resetn)
    begin
      cp0_cause_bd   <= 1'b0;
      cp0_cause_ti   <= 1'b0;
      cp0_cause_ip_h <= 6'b0;
      cp0_cause_ip_l <= 2'b0;
      cp0_cause_exec <= 5'b0;
    end
    else begin
      if(mtc0_wen_cause_EX && EX_valid)
        cp0_cause_ip_l <= mtc0_value_EX[9:8];

      if(exception_commit && cp0_status_exl == 1'b0)
      begin
        if(exe_int_EX)
          cp0_cause_exec <= 5'b00000;
        else if(exe_bad_PC_EX)
          cp0_cause_exec <= 5'b00100;
        else if(exe_ri_EX)
          cp0_cause_exec <= 5'b01010;
        else if(exe_overflow_EX)
          cp0_cause_exec <= 5'b01100;
        else if(exe_syscall_EX)
          cp0_cause_exec <= 5'b01000;
        else if(exe_break_EX)
          cp0_cause_exec <= 5'b01001;
        else if(exe_badvaddr_L_EX)
          cp0_cause_exec <= 5'b00100;
        else if(exe_badvaddr_S_EX)
          cp0_cause_exec <= 5'b00101;

        cp0_cause_bd   <= is_delay_slot_EX;
      end

      if(mtc0_wen_compare_EX && EX_valid)
        cp0_cause_ti   <= 1'b0;
      else if(count_cmp_eq)
        cp0_cause_ti   <= 1'b1;

        cp0_cause_ip_h[5] <= timer_int;
        cp0_cause_ip_h[4] <= int[4];
        cp0_cause_ip_h[3] <= int[3];
        cp0_cause_ip_h[2] <= int[2];
        cp0_cause_ip_h[1] <= int[2];
        cp0_cause_ip_h[0] <= int[0];

      // Add hw_int
    end
  end

  assign exe_int_EX = cp0_status_ie && !cp0_status_exl &&
                      (cp0_cause_ip_h[5] && cp0_status_im[7] ||
                       cp0_cause_ip_h[4] && cp0_status_im[6] ||
                       cp0_cause_ip_h[3] && cp0_status_im[5] ||
                       cp0_cause_ip_h[2] && cp0_status_im[4] ||
                       cp0_cause_ip_h[1] && cp0_status_im[3] ||
                       cp0_cause_ip_h[0] && cp0_status_im[2] ||
                       cp0_cause_ip_l[1] && cp0_status_im[1] ||
                       cp0_cause_ip_l[0] && cp0_status_im[0] );

  // Write cp0_epc
  always @ (posedge clk) begin
    if(!resetn)
      cp0_epc   <= 1'b0;
    else if(mtc0_wen_epc_EX && EX_valid)
      cp0_epc   <= mtc0_value_EX;
    else if(exception_commit == 1'b1 && cp0_status_exl == 1'b0 && is_delay_slot_EX == 1'b0)
      cp0_epc   <= PC_EX;
    else if(exception_commit == 1'b1 && cp0_status_exl == 1'b0 && is_delay_slot_EX == 1'b1)
      cp0_epc   <= PC_EX - 32'h4;
  end

  // Write cp0_count
  reg count_add_en;
  always @(posedge clk) begin
    count_add_en <= (!resetn)? 1'b0 : ~count_add_en;
  end

  always @ (posedge clk) begin
  	if(!resetn)
  	  cp0_count <= 32'h0;
  	else if(mtc0_wen_count_EX && EX_valid)
  	  cp0_count <= mtc0_value_EX;
    else if (count_add_en)
      cp0_count <= cp0_count + 1'b1;
  end

  // Write cp0_compare
  always @ (posedge clk) begin
  	if(!resetn)
  	  cp0_compare <= 32'hffffffff;
  	else if(mtc0_wen_compare_EX && EX_valid)
  	  cp0_compare <= mtc0_value_EX;
  end

  // Write cp0_BadVaddr
  always @ (posedge clk) begin
  	if(!resetn)
  	  cp0_badvaddr <= 32'b0;
  	else if(exception_commit && exe_bad_PC_EX && cp0_status_exl == 1'b0)
  	  cp0_badvaddr <= PC_EX;
  	else if(exception_commit && (exe_badvaddr_S_EX || exe_badvaddr_L_EX) && cp0_status_exl == 1'b0 )
  	  cp0_badvaddr <= ALU_result_EX;
  end

  //###   Debug   ###
  assign debug_wb_pc       =  PC_WB;
  assign debug_wb_rf_wen   =  (WB_valid)?   rf_wen_WB : 4'b0;
  assign debug_wb_rf_wnum  =  rf_waddr_WB;
  assign debug_wb_rf_wdata =  rf_wdata;

 cpu_axi_interface axi_ifc(
    .clk          (aclk        ),
    .resetn       (aresetn     ),
        
    .inst_req     (inst_req    ),
    .inst_wr      (inst_wr     ),
    .inst_size    (inst_size   ),
    .inst_addr    (inst_addr   ),
    .inst_wdata   (inst_wdata  ),
    .inst_rdata   (inst_rdata  ),
    .inst_addr_ok (inst_addr_ok),
    .inst_data_ok (inst_data_ok),

    .data_req     (data_req    ),
    .data_wr      (data_wr     ),
    .data_size    (data_size   ),
    .data_addr    (data_addr   ),
    .data_wdata   (data_wdata  ),
    .data_rdata   (data_rdata  ),
    .data_addr_ok (data_addr_ok),
    .data_data_ok (data_data_ok),

    .arid         (arid        ),
    .araddr       (araddr      ),
    .arlen        (arlen       ),
    .arsize       (arsize      ),
    .arburst      (arburst     ),
    .arlock       (arlock      ),
    .arcache      (arcache     ),
    .arprot       (arprot      ),
    .arvalid      (arvalid     ),
    .arready      (arready     ),
        
    .rid          (rid         ),
    .rdata        (rdata       ),
    .rresp        (rresp       ),
    .rlast        (rlast       ),
    .rvalid       (rvalid      ),
    .rready       (rready      ),
        
    .awid         (awid        ),
    .awaddr       (awaddr      ),
    .awlen        (awlen       ),
    .awsize       (awsize      ),
    .awburst      (awburst     ),
    .awlock       (awlock      ),
    .awcache      (awcache     ),
    .awprot       (awprot      ),
    .awvalid      (awvalid     ),
    .awready      (awready     ),
        
    .wid          (wid         ),
    .wdata        (wdata       ),
    .wstrb        (wstrb       ),
    .wlast        (wlast       ),
    .wvalid       (wvalid      ),
    .wready       (wready      ),
        
    .bid          (bid         ),
    .bresp        (bresp       ),
    .bvalid       (bvalid      ),
    .bready       (bready      )
    );

  //###   IF   ###
IF_stage IF(
    .clk                   (aclk),
    .resetn                (aresetn),
    .ID_allowin            (ID_allowin),
    .exception_commit      (exception_commit),
    .PC_next               (PC_next),
    .inst_addr_ok          (inst_addr_ok),
    .inst_data_ok          (inst_data_ok),

    .PC_IF                 (PC_IF),
    .inst_req              (inst_req),
    .inst_wr               (inst_wr),
    .inst_size             (inst_size),
    .inst_addr             (inst_addr),
    .inst_wdata            (inst_wdata),
    .IF_to_ID_valid        (IF_to_ID_valid),
    .exception_commit_i_IF (exception_commit_i_IF)
);
  //###   ID   ###
  ID_stage ID(
    .clk                  (aclk),
    .PC_IF                (PC_IF),
    .resetn               (aresetn),
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
    .IF_to_ID_valid       (IF_to_ID_valid),
    .inst_rdata           (inst_rdata),    
    .rf_wdata_temp_EX     (rf_wdata_temp_EX),
    .rf_wdata_temp_MEM    (rf_wdata_temp_MEM),
    .ReadData1_ID_current (ReadData1_ID_current),
    .ReadData2_ID_current (ReadData2_ID_current),
    .cp0_status_exl       (cp0_status_exl),
    .exception_commit     (exception_commit),
    .cp0_epc              (cp0_epc),
    .exe_bad_PC_IF        (exe_bad_PC_IF),
    .inst_data_ok         (inst_data_ok),
    .rf_wen_WB_i  (rf_wen_WB_i),
    .WB_valid  (WB_valid),
    .exception_commit_i_IF (exception_commit_i_IF),

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

    .eret_cmt             (eret_cmt),
    .mtc0_value_ID        (mtc0_value_ID),
    .mtc0_wen_status_ID   (mtc0_wen_status_ID),
    .mtc0_wen_cause_ID    (mtc0_wen_cause_ID),
    .mtc0_wen_epc_ID      (mtc0_wen_epc_ID),
    .mtc0_wen_count_ID    (mtc0_wen_count_ID),
    .mtc0_wen_compare_ID  (mtc0_wen_compare_ID),
    .is_ADD_ADDI_SUB_ID   (is_ADD_ADDI_SUB_ID),
    .exe_syscall_ID       (exe_syscall_ID),
    .exe_break_ID         (exe_break_ID),
    .exe_ri_ID            (exe_ri_ID),
    .exe_bad_PC_ID        (exe_bad_PC_ID),
    .is_delay_slot_ID     (is_delay_slot_ID)
  );
  
  //###   EX   ###
  EX_stage EX(
    .HI                   (HI),
    .LO                   (LO),
    .clk                  (aclk),
    .PC_ID                (PC_ID),
    .resetn               (aresetn),
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
    .cp0_compare          (cp0_compare),
    .cp0_count            (cp0_count),
    .cp0_badvaddr         (cp0_badvaddr),
    .exe_syscall_ID       (exe_syscall_ID),
    .exe_break_ID         (exe_break_ID),
    .exe_ri_ID            (exe_ri_ID),
    .exe_bad_PC_ID        (exe_bad_PC_ID),
    .is_delay_slot_ID     (is_delay_slot_ID),
    .cp0_status_exl       (cp0_status_exl),
    .mtc0_wen_status_ID   (mtc0_wen_status_ID),
    .mtc0_wen_cause_ID    (mtc0_wen_cause_ID),
    .mtc0_wen_epc_ID      (mtc0_wen_epc_ID),
    .mtc0_wen_count_ID    (mtc0_wen_count_ID),
    .mtc0_wen_compare_ID  (mtc0_wen_compare_ID),
    .mtc0_value_ID        (mtc0_value_ID),
    .exe_int_EX           (exe_int_EX),
    .is_ADD_ADDI_SUB_ID   (is_ADD_ADDI_SUB_ID),

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
    .data_sram_wdata_EX   (data_sram_wdata_EX),
    .exception_commit     (exception_commit),
    .exe_badvaddr_S_EX    (exe_badvaddr_S_EX),
    .exe_badvaddr_L_EX    (exe_badvaddr_L_EX),
    .exe_overflow_EX      (exe_overflow_EX),
    .store_type_EX     (store_type_EX),
    
    .mtc0_wen_status_EX   (mtc0_wen_status_EX),
    .mtc0_wen_cause_EX    (mtc0_wen_cause_EX),
    .mtc0_wen_epc_EX      (mtc0_wen_epc_EX),
    .mtc0_wen_count_EX    (mtc0_wen_count_EX),
    .mtc0_wen_compare_EX  (mtc0_wen_compare_EX),
    .mtc0_value_EX        (mtc0_value_EX),
    .is_delay_slot_EX     (is_delay_slot_EX),

    .exe_syscall_EX       (exe_syscall_EX),
    .exe_break_EX         (exe_break_EX),
    .exe_ri_EX            (exe_ri_EX),
    .exe_bad_PC_EX        (exe_bad_PC_EX),
    .ALU_result_EX        (ALU_result_EX)
  );

  //###   MEM   ###
  MEM_stage MEM(
    .clk                  (aclk),
    .PC_EX                (PC_EX),
    .resetn               (aresetn),
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
    .exe_badvaddr_S_EX    (exe_badvaddr_S_EX),
    .exe_badvaddr_L_EX    (exe_badvaddr_L_EX),
    .exe_overflow_EX      (exe_overflow_EX),
    .data_addr_ok     (data_addr_ok),
    .store_type_EX   (store_type_EX),

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
//    .data_sram_en_MEM     (data_sram_en_MEM),
    .rf_wdata_temp_MEM    (rf_wdata_temp_MEM),
//    .data_sram_wen_MEM    (data_sram_wen_MEM),
//    .data_sram_addr_MEM   (data_sram_addr_MEM),
//    .data_sram_wdata_MEM  (data_sram_wdata_MEM)
    .data_req   (data_req),
    .data_wr    (data_wr),
    .data_size  (data_size),
    .data_addr  (data_addr),
    .data_wdata (data_wdata)
  );
  
  
  //###   WB   ###
  WB_stage WB(
    .clk                  (aclk),
    .resetn               (aresetn),
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
    .data_rdata     (data_rdata),
    .Instruction_MEM      (Instruction_MEM),
    .HI_MemtoReg_MEM      (HI_MemtoReg_MEM),
    .LO_MemtoReg_MEM      (LO_MemtoReg_MEM),
    .rf_wdata_temp_MEM    (rf_wdata_temp_MEM),
    .data_req     (data_req),
    .data_data_ok (data_data_ok),
    
  
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
    .Instruction_WB       (Instruction_WB),
    .rf_wen_WB_i  (rf_wen_WB_i)
  );
  
  //reg file
  reg_file  Resigters(
    .clk                  (aclk),
    .wen                  (rf_wen_WB),
    .resetn               (aresetn),
    .wdata                (rf_wdata),
    .raddr1               (Esrc1_ID),
    .raddr2               (Esrc2_ID), 
    .waddr                (rf_waddr_WB),  
    .rdata1               (ReadData1_ID_current),
    .rdata2               (ReadData2_ID_current)
  );

endmodule