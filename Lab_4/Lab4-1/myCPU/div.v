`timescale 10 ns / 1 ns

module div(
  input  div_clk,
  input  resetn,
  input  div,
  input  div_signed,
  input  [31:0] x,
  input  [31:0] y,

  output [31:0] s,
  output [31:0] r,
  output complete
);

  wire [31:0] x_abs;
  wire [31:0] y_abs;
  reg  [63:0] A;       // dividend for iteration process
  reg  [32:0] B;       // divisor  for iteration process
  wire [32:0] A_sub_B; // to identify 1 or 0 at some bit
  reg  [32:0] s_temp;
  
  reg  [ 5:0] count;   // count the number of clk
  
  always @(posedge div_clk) begin
    if(!resetn || !div) begin
      count    <=   5'b0;
  	end
  	else
  	  count    <= (count + 1) % 34;
  end

  assign x_abs = (!div_signed)?  x:
                 (!x[31])?       x:
                                 (~x + 1'b1);
                                 
  assign y_abs = (!div_signed)?  y:
                 (!y[31])?       y:
                                 (~y + 1'b1);

  assign A_sub_B = A[63:31] + ~B + 1'b1;

  always @(posedge div_clk) begin
    if(!resetn || !div) begin
      A           <=  64'b0;
      B           <=  33'b0;
    end
    else if(count == 6'd0) begin
      A           <= {{32{1'b0}}, x_abs};
      B           <= {    1'b0  , y_abs};
    end
  	else if(count != 6'd33) begin
  	  s_temp      <= s_temp << 1'b1;
      s_temp[0]   <= ~A_sub_B[32];

      A           <= A << 1'b1;
      if(!A_sub_B[32])
        A[63:32]  <= A_sub_B[31:0];
        
    end
  end
  
  assign complete = (count == 6'd33);

  assign s = (!div_signed  )?   s_temp:
             ( x[31]& y[31])?   s_temp:
             (~x[31]&~y[31])?   s_temp:
                                ~s_temp   + 1'b1; 
  
  assign r = (!div_signed  )?   A[63:32]:
             (~x[31]&~y[31])?   A[63:32]:
             (~x[31]& y[31])?   A[63:32]:
                                ~A[63:32] + 1'b1;

endmodule