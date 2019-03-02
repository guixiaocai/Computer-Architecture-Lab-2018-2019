`timescale 10 ns / 1 ns

module alu(
	input [31:0] A,
	input [31:0] B,
	input [3:0] ALUop,
	output Overflow,
	output CarryOut,
	output Zero,
	output [31:0] Result
);
	wire [32:0] rA;
	wire [32:0] rB;
	wire [32:0] rResult;
	wire [32:0] A_SUB_B;

  assign Result = (ALUop == 4'b0000)? A&B:           //and
                  (ALUop == 4'b0001)? A|B:      	   //or
                  (ALUop == 4'b0010)? A+B:    	     //add
                  (ALUop == 4'b0011)? ((rResult[32])? 1:0):  //sltu
                  (ALUop == 4'b0100)? B << A[4:0]:   //sll
                  (ALUop == 4'b0101)? ~(A|B):        //nor
                  (ALUop == 4'b0110)? A_SUB_B:       //sub
                  (ALUop == 4'b1000)? ({32{B[31]}} << (6'd32-{1'b0,A[4:0]}) | (B >> A[4:0])):  //sra
                  (ALUop == 4'b1001)? B >> A[4:0]:   //srl
                  (ALUop == 4'b1010)? A^B:           //xor
                  (ALUop == 4'b0111)? (( A[31] & ~B[31])?   32'b1:   //slt
                                       (~A[31] &  B[31])?   32'b0:
                                       (A_SUB_B[31])?       32'b1:
                                                            32'b0):
                                      32'b0;

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