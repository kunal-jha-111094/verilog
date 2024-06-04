module pipo1(dout,data_in,ldP,clk,clrP);
  
  input reg [15:0] data_in;
  output reg [15:0] dout;
  input clk,clrP,ldP;
  
  always@(posedge clk)
    
    if(clrP) begin dout <= 16'b0;
 
  if(ldP) begin dout <= data_in;end
    end
endmodule
    
    