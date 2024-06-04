module mux(i0,i1,i2,i3,s0,s1,f);

input i0,i1,i2,i3,s0,s1;
output f;

wire w0,w1,w2,w3;

  and (w0,~s0,~s1,i0);
  and (w1,~s0,s1,i1);
  and (w2,s0,~s1,i2);
  and (w3,s0,s1,i3);
or(f,w0,w1,w2,w3);

endmodule

module mux1(a,b,c,out);

input a,b,c;
output out;

  mux  m0 (1,~a,a,~a,b,c,out);
 
endmodule