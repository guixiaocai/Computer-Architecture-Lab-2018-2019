`timescale 10 ns / 1 ns

module reg_file(
	input  clk,
	input  resetn,
	input  [4:0] waddr,
	input  [4:0] raddr1,
	input  [4:0] raddr2,
	input  [3:0] wen,
	input  [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);
	reg [31:0] r [31:0];

	always@(posedge clk)
	begin
	  if(!resetn)
	    r[0] <= 32'b0;
	  else if(wen == 4'b1111)
	    r[waddr] <= wdata;
	end

	assign rdata1 = (raddr1 == 5'b0)? 32'b0 : r[raddr1];
	assign rdata2 = (raddr2 == 5'b0)? 32'b0 : r[raddr2];

endmodule