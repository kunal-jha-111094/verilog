///////////////////////// SPI DESIGN///////////////////////////

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


/////////////////////////////////Interface/////////////////////////

interface SPI_if;
  
  bit[11:0] din;
  bit mosi;
  bit fclk;
  bit cs,reset;
  bit sclk;
  bit newd;
  
endinterface

//////////////////////////////Transaction//////////////////////////

class transaction;
  
  rand bit newd;
  rand bit [11:0] din;
  bit cs;
  bit mosi;
  
  function void display(input string name);
    $display("[%0s] newd = %b din = %b cs = %b mosi =%b", name,newd,din,cs,mosi);
  endfunction
  
  function transaction copy();
    
    copy = new();
    copy.din = this.din;
    copy.cs = this.cs;
    copy.newd = this.newd;
    copy.mosi = this.mosi;
    return copy;
    
  endfunction
  
  
endclass
  
  
  //////////////////////////////generator////////////////////////////////
  
  
  
  
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
      tr.display("Gen");
      @(nextdrv);
      @(nextsco);
    end
    ->done; 
    $finish;
    
  endtask
  
endclass
  
  
  //////////////////////////////////driver//////////////////////////////
  
  
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
     vif.cs <= 1'b1;
     vif.newd <= 1'b0;
     vif.din <= 1'b0;
     vif.mosi <= 1'b0;
     repeat(10) @(posedge vif.fclk);
      vif.reset <= 1'b0;
     repeat(5) @(posedge vif.fclk);
 
    $display("[DRV] : RESET DONE");
    $display("-----------------------------------------");
  endtask
  
  task run;
    forever begin
      mbx.get(tr);
      @(posedge vif.sclk);
      
      vif.newd <= 1'b1;
      vif.din <= tr.din;
      
      @(posedge vif.sclk);
      mbds.put(vif.din);
      vif.newd <= 1'b0;
      wait(vif.cs == 1'b1);
      $display("[Drv]  din = %b",tr.din);      
      ->nextdrv;
      
    end
  endtask
  
endclass
  
  //////////////////////////////////// monitor/////////////////////////
  
  class monitor;
  
  transaction tr;
  virtual SPI_if vif;
  
  mailbox #(bit [11:0]) mbx;
  
  bit [11:0] srx;
 
  
  event nextsco;
  
  function new( mailbox #(bit [11:0]) mbx);
    this.mbx = mbx;
     //tr = new();
  endfunction
  
  task run;
    forever begin
      @(posedge vif.sclk);
      wait(vif.cs == 1'b0)
      @(posedge vif.sclk);
          
      for(int i = 0; i < 12; i++)begin
          @(posedge vif.sclk)
           srx[i] = vif.mosi;
      end
           
      wait(vif.cs == 1'b1);
      $display("[Mon] DATANEW: srx = %b",srx);
      mbx.put(srx);
    end
  endtask
  
endclass

////////////////////////////////////scoreboard/////////////////////////

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
  
  ////////////////////////////////////environment/////////////////
  
  
  `include "SPI.sv"
`include "transaction.sv"
`include "interface.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"



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
    @(gen.done);
    #200;
    $finish;
  endtask
  
  task run;
    pre_test();
    test();
    post_test();
  endtask
  
endclass