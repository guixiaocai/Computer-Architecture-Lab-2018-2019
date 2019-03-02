`timescale 10 ns / 1 ns

`define DATA_WIDTH 32
`define ADDR_WIDTH 5

module reg_file(
	input clk,
	input resetn,
	input [`ADDR_WIDTH - 1:0] waddr,
	input [`ADDR_WIDTH - 1:0] raddr1,
	input [`ADDR_WIDTH - 1:0] raddr2,
	input [3:0] wen,
	input [`DATA_WIDTH - 1:0] wdata,
	output [`DATA_WIDTH - 1:0] rdata1,
	output [`DATA_WIDTH - 1:0] rdata2
);
	reg [`DATA_WIDTH - 1:0] r [31:0];

	always@(posedge clk)
	begin
	    if(!resetn)
	        r[0] <= 0;
	    else begin
	        if(wen==4'b1111 && waddr != 0)
	            r[waddr] <= wdata;
		      else if(wen==4'b1111 && waddr == 0)
		          r[waddr] <= 0;
	    end
	end


	assign rdata1 = r[raddr1];
	assign rdata2 = r[raddr2];

endmodule