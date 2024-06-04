module counter(dout,data_in,ldB,decQ,bout,clk);
  
  input reg [15:0] data_in;
  input  ldB,clk,decQ;
  output reg bout;
  output reg [15:0] dout;
  
  always @(posedge clk)begin
    
    if(ldB) begin bout <=  data_in; 
    
      if(decQ) begin bout <= dout-1; 
      end 
    end
  end

endmodule
  
  
  