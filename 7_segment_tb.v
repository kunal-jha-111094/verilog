
module tb_6;

reg A,B,C;
wire a,b,c,d,e,f,g;

 
  ass7 dut(.A(A),.B(B),.C(C),.a(a),.b(b),.c(c),.d(d),.e(e),.f(f),.g(g));
initial begin
A=0;B=0;C=0;
  #80 $finish;
  end 
 
  always #40 A=~A;
  always #20 B=~B;
  always #10 C=~C;




initial begin
  $monitor ($time,"A=%b,B=%b,C=%b,a=%b,b=%b,c=%b,d=%b,e=%b,f=%b,g=%b",A,B,C,a,b,c,c,d,e,f,g);
  $dumpvars;
  $dumpfile("mux1.vcd");
  
end
endmodule