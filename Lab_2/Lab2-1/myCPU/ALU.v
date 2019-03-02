`timescale 10 ns / 1 ns

`define DATA_WIDTH 32

module alu(
	input [`DATA_WIDTH - 1:0] A,
	input [`DATA_WIDTH - 1:0] B,
	input [3:0] ALUop,
	output Overflow,
	output CarryOut,
	output Zero,
	output reg [`DATA_WIDTH - 1:0] Result
);
	wire [`DATA_WIDTH:0] rA;
	wire [`DATA_WIDTH:0] rB;
	wire [`DATA_WIDTH:0] rResult;
	wire [`DATA_WIDTH:0] A_SUB_B;



	always @( *)
	begin
	case(ALUop)
		4'b0000: Result = A&B;	//and

		4'b0001: Result = A|B;	//or

		4'b0010: Result = A + B;	//add

		4'b0011: Result = (rResult[32])? 1:0;	//sltu

		4'b0100: Result = B << A[4:0];	// sll

		4'b0101: Result = ~(A|B);	//nor

		4'b0110: Result = A_SUB_B;	//sub

		4'b1000: Result = ({32{B[31]}} << (6'd32-{1'b0,A[4:0]}) | (B >> A[4:0]));	//sra

		4'b1001: Result = B >> A[4:0];	//srl

		4'b1010: Result = A^B;	//xor

		4'b0111: begin	//slt
			 	if(A[31]==1&&B[31]==0)
					Result=1;
				else if(A[31]==0&&B[31]==1)
					Result=0;
				else begin
	        Result = (A_SUB_B[31]==1)? 1:0;
        end
		end
	  default: Result = 32'b0;
	endcase
	end

	
  assign rResult = {1'b0, A} + {1'b1, ~B} + 1;
  assign A_SUB_B = A + ~B + 1;
  //Zero
  assign Zero = (Result == 0)? 1:0;

	//Overflow
	assign Overflow =( ( ALUop==3'b010 && ((A[31]==0 && B[31]==0 && Result[31]==1)||(A[31]==1 && B[31]==1 && Result[31]==0)) ) 
                         ||( ALUop==3'b110 && ((A[31]==0 && B[31]==1 && Result[31]==1)||(A[31]==1 && B[31]==0 && Result[31]==0)) ) ) ?  1:0;
	
	//CarryOut
	assign rA = {1'b0,A} + ~{1'b0,Result} + 1;
	assign rB = {1'b0,B} + ~{1'b0,Result} + 1;
	assign CarryOut = ((ALUop==3'b010 && rA[32]==0 && rB[32]==0 &&A!=0 &&B!=0) ||(ALUop==3'b110 && rA[32]==1))? 1:0;


endmodule