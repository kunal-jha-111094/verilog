 module ass_8(d0,d1,d2,d3,d4,d5,d6,d7,y1,y2,y3);
 
 input d0,d1,d2,d3,d4,d5,d6,d7;
 output y1,y2,y3;
 
 wire w0,w1,w2,w3,w4,w5,w6,w7,w8
 
 or(y1,d4,d5,d6,d7);
 or(y2,d2,d3,d6,d7);
 or(y3,d1,d3,d5,d7);
 
 endmodule