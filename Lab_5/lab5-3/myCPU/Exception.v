`timescale 10ns / 1ns

module Exception(

    input  wire [ 5:0] int, //high active

    input  wire        clk,
    input  wire        resetn,
    input  wire [31:0] PC_IF,
    input  wire        EX_valid,
    input  wire        mtc0_wen_status_EX,
    input  wire [31:0] mtc0_value_EX,
    input  wire        exception_commit,
    input  wire        mtc0_wen_cause_EX,
    input  wire        exe_bad_PC_EX,
    input  wire        exe_ri_EX,
    input  wire        exe_overflow_EX,
    input  wire        exe_syscall_EX,
    input  wire        exe_break_EX,
    input  wire        exe_badvaddr_L_EX,
    input  wire        exe_badvaddr_S_EX,
    input  wire        is_delay_slot_EX,
    input  wire        mtc0_wen_compare_EX,
    input  wire        mtc0_wen_epc_EX,
    input  wire [31:0] PC_EX,
    input  wire        mtc0_wen_count_EX,
    input  wire [31:0] ALU_result_EX,
    input  wire        eret_cmt,

    output wire        exe_bad_PC_IF,
    output reg         cp0_status_exl,
    output wire [31:0] cp0_status,
    output wire [31:0] cp0_cause,
    output reg  [31:0] cp0_epc,
    output reg  [31:0] cp0_count,
    output reg  [31:0] cp0_compare,
    output reg  [31:0] cp0_badvaddr,
    output wire        exe_int_EX
);
  // ### Status ###
  wire       cp0_status_bev;
  reg  [7:0] cp0_status_im;
  reg        cp0_status_ie;
  
  // ### Cause ###
  reg         cp0_cause_bd;
  reg         cp0_cause_ti;
  reg  [5:0]  cp0_cause_ip_h;
  reg  [1:0]  cp0_cause_ip_l;
  reg  [4:0]  cp0_cause_exec;
  
  assign exe_bad_PC_IF   = ( PC_IF[1:0] != 2'b0 );

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
        cp0_cause_ip_l   <= mtc0_value_EX[9:8];

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

        cp0_cause_bd     <= is_delay_slot_EX;
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

  assign exe_int_EX =  cp0_status_ie     &&!cp0_status_exl   &&
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
  
endmodule