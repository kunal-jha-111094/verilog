module ass7(A,B,C,a,b,c,d,e,f,g);

input A,B,C;
output a,b,c,d,e,f,g;

wire w0,w1,w2,w3,w4;
wire w5,w6,w7,w8,w9;
wire w10,w11,w12,w13;
wire w14,w15,w16,w17;
wire w18,w19,w20,w21;

and(w0,~A,~B,~C);
and(w1,B,B);
and(w2,A,C);
or(a,w0,w1,,w2);

and(w3,~A,~A);
and(w4,B,~c);
or(b,w3,w4);

and(w5,A,A);
and(w6,~A,~B);
and(w7,~A,C);
or(c,w5,w6,w7);

and(w8,~A,~c);
and(w9,B,C);
and(w10,A,~B);
or(d,w8,w9,w10);

and(w11,~A,~C);
and(w12,A,B,C);
or(e,w11,w12);

and(w13,~B,~C);
and(w14,A,~B);
and(w15,A,~C);
or(f,w13,w14,w15);

and(w16,~A,B);
and(w17,B,~C);
and(w18,A,~B);
or(g,w16,w17,w18);


endmodule