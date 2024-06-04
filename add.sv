module add (z,x,y);
  
  input [15:0] x,y;
  output [15:0]z;
  
  assign z = x+y;
  
endmodule