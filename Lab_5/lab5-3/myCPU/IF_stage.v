`timescale 1ns / 1ps

module IF_stage(
  input  wire        clk,
  input  wire        resetn,
  input  wire        ID_allowin,
  input  wire        exception_commit,
  input  wire [31:0] PC_next,
  input  wire        inst_addr_ok,
  input  wire        inst_data_ok,

  output reg  [31:0] PC_IF,
  output wire        inst_req,
  output wire        inst_wr,
  output wire [ 1:0] inst_size,
  output wire [31:0] inst_addr,
  output wire [31:0] inst_wdata,
  output wire        IF_to_ID_valid,
  output reg         exception_commit_i_IF
);

  wire validin;
  wire IF_valid;
  wire IF_ready_go;
  reg  inst_addr_arrived;
  reg  inst_data_arrived;

  assign inst_req        = resetn && !inst_addr_arrived;
  assign inst_wr         = 1'b0;
  assign inst_size       = 2'd2;
  assign inst_addr       = PC_IF;
  assign inst_wdata      = 32'b0;
  
  assign validin         =  1'b1;
  assign IF_valid        =  1'b1;
  assign IF_ready_go     =  inst_data_ok || inst_data_arrived;
  assign IF_to_ID_valid  =  IF_valid     && IF_ready_go;

  always @(posedge clk) begin
  if(!resetn)
    inst_data_arrived   <= 1'b0;
  else if(IF_to_ID_valid && ID_allowin)
    inst_data_arrived   <= 1'b0;
  else if(inst_data_ok)
    inst_data_arrived   <= 1'b1;
  end

  always @(posedge clk) begin
  if(!resetn)
    inst_addr_arrived   <= 1'b0;
  else if(IF_to_ID_valid && ID_allowin)
    inst_addr_arrived   <= 1'b0;
  else if(inst_addr_ok)
    inst_addr_arrived   <= 1'b1;
  end

  always @ (posedge clk)begin
    if(!resetn)
      exception_commit_i_IF <= 1'b0;
    else if(IF_to_ID_valid && ID_allowin)
      exception_commit_i_IF <= 1'b0;
    else if(exception_commit)
      exception_commit_i_IF <= 1'b1;
  end

  always @(posedge clk) begin
    if(!resetn)
      PC_IF   <= 32'hbfc00000;
    else if(IF_to_ID_valid && ID_allowin)
      PC_IF   <= PC_next;
  end

endmodule