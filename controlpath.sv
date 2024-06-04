module controller(ldA,ldB,ldP,clrP,decQ,clrP,eqz,start,done,clk);
  
  input reg eqz,clk,start;
  output reg ldA,ldB,ldP,clrP,decQ,done;
  
  reg [2:0]state;
  parameter s0 = 3'b000, s1 = 3'b001, s2 = 3'b010, s3 = 3'b011, s4 = 3'b100;
  always@(posedge clk)
   begin 
     case(state)
      
        
       s0: if(start) state <= s1;
        s1: state <= s2;
        s2: state <= s3;
       s3: if(eqz) state <= s4;
        s4: state <= s4;
      endcase   
      end
   
 
  
  always @(state)
     begin
    case (state)
     
        s0: begin #5 ldA = 0;ldB = 0;ldP = 0; clrP = 0; decQ = 0;end
        s1:  begin #5 ldA = 1;end
        s2: begin #5 ldA = 0; ldB = 1;clrP = 1;end
        s3: begin #5 ldA=0;ldB=0;ldP=1;decQ=1;end
        s4: begin #5 done = 1; ldA = 0; ldB = 0; ldP = 0;end
          
       
    endcase
      end
endmodule
   
      