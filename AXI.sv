`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2026 10:56:52
// Design Name: 
// Module Name: AXI_Top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////




module tb_axi_lite_ram;

    // --------------------------------------------------
    // Parameters
    // ---------------------32----------------------------
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 10;

    // --------------------------------------------------
    // Clock & Reset
    // --------------------------------------------------
    reg aclk;
    reg aresetn;

    always #5 aclk = ~aclk;   // 100 MHz clock

    // --------------------------------------------------
    // AXI-Lite Signals
    // --------------------------------------------------

    // Write address
    reg  [ADDR_WIDTH-1:0] s_axi_awaddr;
    reg  [2:0]            s_axi_awprot;
    reg                   s_axi_awvalid;
    wire                  s_axi_awready;

    // Write data
    reg  [DATA_WIDTH-1:0] s_axi_wdata;
    reg  [DATA_WIDTH/8-1:0] s_axi_wstrb;
    reg                   s_axi_wvalid;
    wire                  s_axi_wready;

    // Write response
    wire [1:0]            s_axi_bresp;
    wire                  s_axi_bvalid;
    reg                   s_axi_bready;

    // Read address
    reg  [ADDR_WIDTH-1:0] s_axi_araddr;
    reg  [2:0]            s_axi_arprot;
    reg                   s_axi_arvalid;
    wire                  s_axi_arready;

    // Read data
    wire [DATA_WIDTH-1:0] s_axi_rdata;
    wire [1:0]            s_axi_rresp;
    wire                  s_axi_rvalid;
    reg                   s_axi_rready;

    // --------------------------------------------------
    // DUT Instantiation
    // --------------------------------------------------
    AXI_Slave dut (
        .s_axi_clk           (aclk),
        .s_axi_resetn        (aresetn),

        .s_axi_awaddr   (s_axi_awaddr),
        //.s_axi_awprot   (s_axi_awprot),
        .s_axi_awvalid  (s_axi_awvalid),
        .s_axi_awready  (s_axi_awready),

        .s_axi_wdata    (s_axi_wdata),
        //.s_axi_wstrb    (s_axi_wstrb),
        .s_axi_wvalid   (s_axi_wvalid),
        .s_axi_wready   (s_axi_wready),

        .s_axi_bresp    (s_axi_bresp),
        .s_axi_bvalid   (s_axi_bvalid),
        .s_axi_bready   (s_axi_bready),

        .s_axi_araddr   (s_axi_araddr),
        //.s_axi_arprot   (s_axi_arprot),
        .s_axi_arvalid  (s_axi_arvalid),
        .s_axi_arready  (s_axi_arready),

        .s_axi_rdata    (s_axi_rdata),
        .s_axi_rresp    (s_axi_rresp),
        .s_axi_rvalid   (s_axi_rvalid),
        .s_axi_rready   (s_axi_rready)
    );

    // --------------------------------------------------
    // AXI Write Task
    // --------------------------------------------------
    task axi_write(input [ADDR_WIDTH-1:0] addr,
                   input [DATA_WIDTH-1:0] data);
    begin
        // Write address
        @(posedge aclk);
        s_axi_awaddr  <= addr;
        s_axi_awvalid <= 1'b1;

        wait (s_axi_awready);
        @(posedge aclk);
        s_axi_awvalid <= 1'b0;

        // Write data
        s_axi_wdata  <= data;
        s_axi_wvalid <= 1'b1;

        wait (s_axi_wready);
        
        // Write response
        wait (s_axi_bvalid);
        s_axi_bready <= 1'b1;
        @(posedge aclk);
        s_axi_wvalid <= 1'b0;

        
        @(posedge aclk);
        s_axi_bready <= 1'b0;

        $display("[WRITE] Addr = %0h Data = %0h", addr, data);
    end
    endtask

    // --------------------------------------------------
    // AXI Read Task
    // --------------------------------------------------
    task axi_read(input  [ADDR_WIDTH-1:0] addr,
                  output [DATA_WIDTH-1:0] data);
    begin
        // Read address
        @(posedge aclk);
        s_axi_araddr  <= addr;
        s_axi_arvalid <= 1'b1;
//$display("[READ ] Addr = %0h Data = %0h", addr, data);
        wait (s_axi_arready);
        @(posedge aclk);
        s_axi_rready <= 1'b1;
        wait (s_axi_rvalid);
        data = s_axi_rdata;
        @(posedge aclk);
        s_axi_rready <= 1'b0;
        
        $display("[READ ] Addr = %0h Data = %0h", addr, data);
    end
    endtask

    // --------------------------------------------------
    // Test Sequence
    // --------------------------------------------------
    reg [31:0] rdata;

    initial begin
        // Init
        aclk = 0;
        aresetn = 0;

        s_axi_awvalid = 0;
        s_axi_wvalid  = 0;
        s_axi_bready  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 0;

        s_axi_awprot = 3'b000;
        s_axi_arprot = 3'b000;

        // Reset
        repeat (5) @(posedge aclk);
        aresetn = 1;

        // --------------------------------------------------
        // Test cases
        // --------------------------------------------------
        axi_write(10'h004, 32'hDEADBEEF);
        axi_read (10'h004, rdata);

        if (rdata !== 32'hDEADBEEF)
            $error("DATA MISMATCH!");
        else
            $display("DATA MATCH SUCCESS");

        axi_write(10'h008, 32'h12345678);
        axi_read (10'h008, rdata);

        #50;
        $display("TEST PASSED");
    
  $dumpfile("dump.vcd");
      $dumpvars(1, tb_axi_lite_ram);   // tb = name of your1top testbench module

      #100 
      $finish();
      
    end

endmodule



`timescale 1ns / 1ps

`include "AXI_RAM.sv"

module AXI_Slave( input wire s_axi_clk, s_axi_resetn,
                  input wire s_axi_awid, s_axi_awvalid,
                  input wire s_axi_awlen,
                  input wire s_axi_awsize,
                  input wire [2:0] s_axi_awburst,
                  input wire [9:0] s_axi_awaddr,
                  output reg s_axi_awready,                  
                  
                  /////////write data channel
                  
                 input wire [31:0] s_axi_wdata,
                  input wire     s_axi_wvalid,
                  input wire [1:0] s_axi_wstb,
                  input wire     s_axi_wlast,
                  output reg s_axi_wready,
                  
                  
                  //////// write resp channel
                  
                  output reg s_axi_bid,
                  output reg s_axi_bvalid,
                  input wire s_axi_bready,
                  output reg [1:0] s_axi_bresp,
                  
                  ///////read address channel
                  
                  input wire s_axi_arid, 
                  input wire s_axi_arvalid,
                  input wire s_axi_arlen,
                  input wire s_axi_arsize,
                  input wire [2:0] s_axi_arburst,
                  input wire [9:0] s_axi_araddr,
                  output reg s_axi_arready,
                  
                  //////read data channel
                  
                  output reg s_axi_rid,
                 output reg [31:0] s_axi_rdata,
                  output reg s_axi_rvalid,                  
                  input wire s_axi_rready,
                  output reg [1:0] s_axi_rresp,
                  output reg s_axi_rlast
                  
    );
    
    reg [9:0] wr_addr_reg,rd_addr_reg;
    reg [7:0] ram_wr_data;
    reg [9:0] ram_addr;
    reg [7:0] ram_rdata;
    reg wr_enb,rd_enb;

    
    reg [1:0] write_state, read_state;
    
     localparam           IDLE = 2'b00;
     localparam           write = 2'b01;
     localparam           read = 2'b10;
     localparam           resp = 2'b11;
                
     localparam  resp_okay = 2'b00;
     localparam  slv_err = 2'b11;           
         
      AXI_RAM dut (.clk(s_axi_clk),.rst(s_axi_resetn),.dout(ram_rdata),.datain(ram_wr_data),.wenb(wr_enb),.addr(ram_addr));   
         
         
    ///////////write address chammel     
                
    always @(posedge s_axi_clk)
    begin
         if(!s_axi_resetn) begin
             s_axi_awready <= 1'b0;
             wr_addr_reg <= 10'b0;
             write_state <= IDLE;
        end  else 
            
             case(write_state)
                  
                  IDLE: begin     wr_enb <= 1'b1;
                                 
                              if(s_axi_awvalid)
                              begin
                                     wr_addr_reg <= s_axi_awaddr;
                                      s_axi_awready <= 1'b1;
                                      s_axi_wready <= 1'b1;
                                     write_state <= write;
                                   end  
                  end
                  
                  write: begin  if(s_axi_wvalid )
                                
                                ram_wr_data <= s_axi_wdata;
                                write_state <= resp;
                  end
                  
               resp: begin if(s_axi_wvalid && s_axi_wready) begin
                                s_axi_bvalid <= 1'b1;
                                write_state <= IDLE;
               end
                  end
                  default : write_state <= IDLE;
                  endcase
    end
    

   
   //////////// read address channel
   
 always @(posedge s_axi_clk)
 begin
            if(!s_axi_resetn)  begin 
                    s_axi_arready <= 1'b0;
                    rd_addr_reg <= 10'b0;
                    
                    read_state <= IDLE;
              end
              else
                     case(read_state)
                     
                     IDLE:begin    wr_enb <= 1'b0;
                                   s_axi_arready <= 1'b1;
                                
                                if(s_axi_arready && s_axi_arvalid)
                                  begin 
                                    rd_addr_reg <= s_axi_araddr;
                                    //s_axi_arready <= 1'b0;
                                    read_state <= read;
                                    end
                                    end
                    read: begin if(s_axi_arvalid && s_axi_arready)
                              s_axi_rvalid <= 1'b1;
                               s_axi_rdata <= ram_rdata;    
                              
                              wr_enb <= 0;  
                              read_state <= resp;   
                    end
                    
                       resp: begin if(s_axi_rvalid && s_axi_rready) begin
                                s_axi_rvalid <= 1'b0;
                                  s_axi_arready <= 1'b0;
                                read_state <= IDLE;
                       end
                       end
                   default: read_state <= IDLE;
                endcase    
             end  
             
endmodule


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.06.2026 11:28:29
// Design Name: 
// Module Name: AXI_RAM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module AXI_RAM( input clk,rst,
                input reg [9:0] addr,
                output reg [7:0] dout,
                input reg [7:0] datain,
                input wenb,rdenb 
    );
    
    reg [7:0] mem [1024:0];
    
    always @(posedge clk)
     begin
        if(!rst)
            dout <= 0;
        else
              if(wenb)
                mem[addr] <= datain;
              if(rdenb)
                dout <= mem[addr];    
     
      end
endmodule
