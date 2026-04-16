 ///////////////////////design master///////////////////////
 
 module SPI(
input fclk, reset,newd,
input [11:0] din, 
output reg mosi,cs,sclk
    );
  
  typedef enum bit [1:0] {idle = 2'b00, enable = 2'b01, send = 2'b10, comp = 2'b11 } state_type;
  state_type state = idle;
  
  int countc = 0;
  int count = 0;
 
  /////////////////////////generation of sclk
   always@(posedge fclk)
  begin
    if(reset == 1'b1) begin
      countc <= 0;
      sclk <= 1'b0;
    end
    else begin 
      if(countc < 10 )   /// fclk / 20
          countc <= countc + 1;
      else
          begin
          countc <= 0;
          sclk <= ~sclk;
          end
    end
  end
  
  //////////////////state machine
    reg [11:0] temp;
    
  always@(posedge sclk)
  begin
    if(reset == 1'b1) begin
      cs <= 1'b1; 
      mosi <= 1'b0;
    end
    else begin
     case(state)
         idle:
             begin
               if(newd == 1'b1) begin
                 state <= send;
                 temp <= din; 
                 cs <= 1'b0;
               end
               else begin
                 state <= idle;
                 temp <= 8'h00;
               end
             end
       
       
       send : begin
         if(count <= 11) begin
           mosi <= temp[count]; /////sending lsb first
           count <= count + 1;
         end
         else
             begin
               count <= 0;
               state <= idle;
               cs <= 1'b1;
               mosi <= 1'b0;
             end
       end
       
                
      default : state <= idle; 
       
   endcase
  end 
 end
  
endmodule

/////////////////////////////////design slave//////////////////////////

module SPI_s ( input sclk,cs,mosi,
               output [11:0] dout,
               output  reg done
             );
               
					
 typedef enum bit {detect_start = 1'b0, read_data = 1'b1} state_type;
state_type state = detect_start;
 
reg [11:0] temp = 12'h000;
int count = 0;
 
always@(posedge sclk)
begin
 
case(state)
detect_start: 
begin
done   <= 1'b0;
if(cs == 1'b0)
 state <= read_data;
 else
 state <= detect_start;
end
 
read_data : begin
if(count <= 11)
 begin
 count <= count + 1;
 temp  <= { mosi, temp[11:1]};
 end
 else
 begin
 count <= 0;
 done <= 1'b1;
 state <= detect_start;
 end
 
end
 
endcase
end
assign dout = temp;
 
endmodule

//////////////////////////////TOP////////////////////////////

`include "interface.sv"
`include "transaction.sv"

`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "env.sv"

`include "SPI_master.sv"
`include "SPI_slave.sv"

module top(		input fclk,reset,newd,
           		input [11:0] din,
           		output [11:0] dout, 
				output done

          );
  
   wire sclk,cs,mosi;
  
  SPI M1 (fclk,reset,newd,din,mosi,cs,sclk);
  SPI_s S1(sclk,cs,mosi,dout,done);
  
endmodule 

//////////////////////interface//////////////////////

interface SPI_if;

  logic [11:0] din;
  logic        mosi;
  logic        fclk;
   logic        cs, reset;
  logic        sclk;
  logic        newd;
  logic [11:0] dout;
  logic        done;

endinterface

//////////////////////////generator//////////////////

class generator;
  
  transaction tr;
  
  event nextdrv;
  event done;
  event nextsco;
  
  int count = 0;
  
  mailbox #(transaction) mbx;
  
  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
    tr = new();    
  endfunction
  
  task random;
    repeat(count) begin 
      assert(tr.randomize) else $error("[gen] : randomization failed");
      mbx.put(tr.copy);
      $display("[GEN] datain = %0b", tr.din);
      
      @(nextsco);
    end
    ->done; 
    $finish;
    
  endtask
  
endclass
  
//////////////////////transaction//////////////////////////

  
  class transaction;
  
   bit newd;
  rand bit [11:0] din;
  bit [11:0] dout;
  
  function transaction copy();
    
    copy = new();
    copy.din = this.din;
    copy.newd = this.newd;
    copy.dout = this.dout;
    return copy;
    
  endfunction
  
  
endclass
  
  ///////////////////////driver/////////////////////////
  
  class driver;
  
  transaction tr;
  virtual SPI_if vif;
  
  mailbox #(transaction) mbx;
  mailbox #(bit [11:0]) mbds;
  
  event nextdrv;
  
  function new( mailbox #(transaction) mbx,mailbox #(bit [11:0]) mbds);
    this.mbx = mbx;
    this.mbds = mbds;
  // tr = new();
  endfunction
  
   task reset();
     vif.reset <= 1'b1;
     
     vif.newd <= 1'b0;
     vif.din <= 1'b0;
     
     repeat(10) @(posedge vif.fclk);
      vif.reset <= 1'b0;
     repeat(5) @(posedge vif.fclk);
 
    $display("[DRV] : RESET DONE");
    $display("-----------------------------------------");
  endtask
  
  task run;
    forever begin
      mbx.get(tr);
      vif.newd <= 1'b1;
      vif.din <= tr.din; 
      mbds.put(tr.din);
      @(posedge vif.sclk);
     //mbds.put(vif.din);
      vif.newd <= 1'b0;
      @(posedge vif.done);
      
      $display("[Drv]  din = %0b",tr.din);   
      @(posedge vif.sclk);
      
    end
  endtask
  
endclass

//////////////////////////////monitor///////////////////

  
  class monitor;
  
  transaction tr;
  virtual SPI_if vif;
  
  mailbox #(bit [11:0]) mbx;
  
 event nextsco;
  
  function new( mailbox #(bit [11:0]) mbx);
    this.mbx = mbx;
     //tr = new();
  endfunction
  
  task run;
    tr = new();
    forever begin
      @(posedge vif.sclk);
      @(posedge vif.done);
      tr.dout = vif.dout;
      @(posedge vif.sclk);  
      $display("[MON] data sent: %0b",tr.dout);
      
      mbx.put(tr.dout);

           
    
    end
  endtask
  
endclass

/////////////////////scoreboard////////////////////////

class scoreboard;
  
 
  
  mailbox #(bit[11:0]) mbds;
  mailbox #(bit[11:0]) mbms;
  bit[11:0] ds;
  bit [11:0] ms;
  
  event nextsco;
  
  function new( mailbox #(bit[11:0]) mbds, mailbox #(bit[11:0]) mbms);
    this.mbds = mbds;
    this.mbms = mbms;
  endfunction
  
  task run;
    
    forever begin
    mbds.get(ds);
    mbms.get(ms);
      
       $display("ds = %0b ms = %0b", ds,ms);
    
      if(ds == ms)
        $display("data matched");
      else
        $display("data mismatched");
      
     
      
      $display("--------------------------");
      ->nextsco;
    end
    
      
    
  endtask
  
endclass
 

////////////////////////////////environment//////////////////////// 
  
class environment;
  
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  
  virtual SPI_if vif;
  
  mailbox #(transaction) mbgd;
  mailbox #(bit [11:0]) mbds;
  mailbox #(bit [11:0]) mbms;
  
  event nextgd;
  event nextgs;
  
  function new(virtual SPI_if vif);
    
    mbgd = new();
    mbds = new();
    mbms = new();
    
    gen = new(mbgd);
    drv = new(mbgd, mbds);
    mon = new(mbms);
    sco = new(mbds, mbms);
    
    this.vif = vif;
    drv.vif = this.vif;
    mon.vif = this.vif;
    
    gen.nextsco = nextgs;
    sco.nextsco = nextgs; 
    
    gen.nextdrv = nextgd;
    drv.nextdrv = nextgd;
    
  endfunction
  
  task pre_test;
    drv.reset();    
  endtask
  
  task test;
    fork
      gen.random();
      mon.run();
      drv.run();
      sco.run();
    join_any
    disable fork;
  endtask
  
  task post_test;
    wait(gen.done.triggered);
    #4;
    $finish;
  endtask
  
  task run;
    pre_test();
    test();
    post_test();
  endtask
  
endclass