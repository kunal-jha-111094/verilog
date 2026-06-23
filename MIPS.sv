`include "datapath.sv"
`include "controlpath.sv"
`include"instructionmem.sv"
`include "datamem.sv"

module mips (
    input  logic clk,
    input  logic reset
);

    logic memtoreg, memwrite, pcsrc;
    logic alusrc, regdst, regwrite, jump;
    logic zero;

    logic [2:0] alucontrol;

    logic [31:0] pc;
    logic [31:0] instr;
    logic [31:0] aluout;
    logic [31:0] writedata;
    logic [31:0] readdata;

    // Instruction Memory
    instr_memory imem (
        .addr(pc),
        .instr(instr)
    );

    // Data Memory
    data_memory dmem (
        .clk(clk),
        .memwrite(memwrite),
        .addr(aluout),
        .writedata(writedata),
        .readdata(readdata)
    );

    // Control Unit
    control_unit cu (
        .op(instr[31:26]),
        .funct(instr[5:0]),
        .zero(zero),
        .memtoreg(memtoreg),
        .memwrite(memwrite),
        .alusrc(alusrc),
        .regdst(regdst),
        .regwrite(regwrite),
        .jump(jump),
        .pcsrc(pcsrc),
        .alucontrol(alucontrol)
    );

    // Datapath
    datapath dp (
        .clk(clk),
        .reset(reset),
        .memtoreg(memtoreg),
        .memwrite(memwrite),
        .pcsrc(pcsrc),
        .alusrc(alusrc),
        .regdst(regdst),
        .regwrite(regwrite),
        .jump(jump),
        .alucontrol(alucontrol),
        .zero(zero),
        .pc(pc),
        .instr(instr),
        .aluout(aluout),
        .writedata(writedata),
        .readdata(readdata)
    );

endmodule


`include "registerfile.sv"
module datapath(
    input logic clk,
    input logic reset,

    input logic memtoreg,
    input logic memwrite,
    input logic pcsrc,
    input logic alusrc,
    input logic regdst,
    input logic regwrite,
    input logic jump,

    input logic [2:0] alucontrol,

    output logic zero,
    output logic [31:0] pc,

    input logic [31:0] instr,

    output logic [31:0] aluout,
    output logic [31:0] writedata,

    input logic [31:0] readdata
);

    logic [31:0] srca, srcb;
    logic [31:0] result;

    logic [31:0] signimm;
    logic [31:0] signimmsh;

    logic [31:0] pcplus4;
    logic [31:0] pcbranch;
    logic [31:0] pcnext;

    logic [4:0] writereg;

    register_file rf(
        .clk(clk),
        .regwrite(regwrite),
        .readreg1(instr[25:21]),
        .readreg2(instr[20:16]),
        .writereg(writereg),
        .result(result),
        .readdata1(srca),
        .readdata2(writedata)
    );

    always_ff @(posedge clk or posedge reset)
    begin
        if(reset)
            pc <= 0;
        else
            pc <= pcnext;
    end

    assign pcplus4  = pc + 4;

    assign signimm  = {{16{instr[15]}},instr[15:0]};

    assign signimmsh = signimm << 2;

    assign pcbranch = pcplus4 + signimmsh;

    assign pcnext =
           jump ? {pcplus4[31:28],instr[25:0],2'b00} :
           (pcsrc ? pcbranch : pcplus4);

    assign writereg =
           regdst ? instr[15:11] :
                    instr[20:16];

    assign srcb =
           alusrc ? signimm :
                    writedata;

    always_comb
    begin
        case(alucontrol)

            3'b010: aluout = srca + srcb;
            3'b110: aluout = srca - srcb;
            3'b000: aluout = srca & srcb;
            3'b001: aluout = srca | srcb;
            3'b111: aluout = (srca < srcb);

            default: aluout = 32'b0;

        endcase
    end

    assign zero = (aluout == 0);

    assign result =
           memtoreg ? readdata :
                      aluout;

endmodule



module control_unit(

    input logic [5:0] op,
    input logic [5:0] funct,
    input logic zero,

    output logic memtoreg,
    output logic memwrite,
    output logic alusrc,
    output logic regdst,
    output logic regwrite,
    output logic jump,
    output logic pcsrc,

    output logic [2:0] alucontrol
);

    logic branch;
    logic [1:0] aluop;

    always_comb
    begin
        memtoreg = 0;
        memwrite = 0;
        branch   = 0;
        alusrc   = 0;
        regdst   = 0;
        regwrite = 0;
        jump     = 0;
        aluop    = 2'b00;

        case(op)

            6'b000000:
            begin
                regdst   = 1;
                regwrite = 1;
                aluop    = 2'b10;
            end

            6'b100011:
            begin
                alusrc   = 1;
                memtoreg = 1;
                regwrite = 1;
            end

            6'b101011:
            begin
                alusrc   = 1;
                memwrite = 1;
            end

            6'b000100:
            begin
                branch = 1;
                aluop  = 2'b01;
            end

            6'b001000:
            begin
                alusrc   = 1;
                regwrite = 1;
            end

            6'b000010:
                jump = 1;

        endcase
    end

    assign pcsrc = branch & zero;

    always_comb
    begin
        case(aluop)

            2'b00: alucontrol = 3'b010;
            2'b01: alucontrol = 3'b110;

            2'b10:
            begin
                case(funct)

                    6'b100000: alucontrol = 3'b010;
                    6'b100010: alucontrol = 3'b110;
                    6'b100100: alucontrol = 3'b000;
                    6'b100101: alucontrol = 3'b001;
                    6'b101010: alucontrol = 3'b111;

                    default:   alucontrol = 3'b000;

                endcase
            end

            default: alucontrol = 3'b000;

        endcase
    end

endmodule

module register_file(

    input logic clk,
    input logic regwrite,

    input logic [4:0] readreg1,
    input logic [4:0] readreg2,
    input logic [4:0] writereg,

    input logic [31:0] result,

    output logic [31:0] readdata1,
    output logic [31:0] readdata2
);

    logic [31:0] registers [0:31];

    initial
    begin
        for(int i=0;i<32;i++)
            registers[i]=0;
    end

    assign readdata1 =
            (readreg1==0) ? 0 :
                            registers[readreg1];

    assign readdata2 =
            (readreg2==0) ? 0 :
                            registers[readreg2];

    always_ff @(posedge clk)
    begin
        if(regwrite && writereg!=0)
            registers[writereg] <= result;
    end

endmodule



module instr_memory(

    input  logic [31:0] addr,
    output logic [31:0] instr
);

    logic [31:0] ROM [0:31];

    initial begin

        ROM[0] = 32'h2002000A; // ADDI R2,R0,10
        ROM[1] = 32'h00431820; // ADD R3,R2,R3
        ROM[2] = 32'h8C640004; // LW R4,4(R3)
        ROM[3] = 32'hAC040006; // SW R4,6(R0)
        ROM[4] = 32'hFC000000; // HLT

    end

    assign instr = ROM[addr[31:2]];

endmodule

module data_memory(

    input logic clk,
    input logic memwrite,

    input logic [31:0] addr,
    input logic [31:0] writedata,

    output logic [31:0] readdata
);

    logic [31:0] RAM [0:31];

    initial begin
        for(int i=0;i<32;i++)
            RAM[i] = 0;

      RAM[3] = 32'hDEADBEEF;
    end

    assign readdata = RAM[addr[31:2]];

    always_ff @(posedge clk)
    begin
        if(memwrite)
            RAM[addr[31:2]] <= writedata;
    end

endmodule

`timescale 1ns/1ps

module mips_tb;

  logic clk;
  logic reset;

  //--------------------------------------------------
  // DUT
  //--------------------------------------------------
  mips dut(
      .clk(clk),
      .reset(reset)
  );

  //--------------------------------------------------
  // Clock Generation
  //--------------------------------------------------
  initial begin
      clk = 0;
      forever #5 clk = ~clk;
  end

  //--------------------------------------------------
  // Reset
  //--------------------------------------------------
  initial begin
      reset = 1;

      #20;
      reset = 0;

      #150;
      $display("\nSimulation Complete\n");
      $finish;
  end

  //--------------------------------------------------
  // Processor Trace
  //--------------------------------------------------
  always @(posedge clk)
  begin

      $display("------------------------------------------------");

      $display("TIME : %0t", $time);

      $display("PC   = %h", dut.dp.pc);
      $display("INST = %h", dut.dp.instr);

      $display("RS=%0d RT=%0d RD=%0d",
                dut.dp.instr[25:21],
                dut.dp.instr[20:16],
                dut.dp.instr[15:11]);

      $display("ALU RESULT = %h", dut.dp.aluout);

      $display("REGWRITE=%b MEMWRITE=%b MEMTOREG=%b",
                dut.regwrite,
                dut.memwrite,
                dut.memtoreg);

      $display("R2=%h  R3=%h  R4=%h",
                dut.dp.rf.registers[2],
                dut.dp.rf.registers[3],
                dut.dp.rf.registers[4]);

  end

  //--------------------------------------------------
  // Memory Write Monitor
  //--------------------------------------------------
  always @(posedge clk)
  begin
      if(dut.memwrite)
      begin
          $display("\n*** DATA MEMORY WRITE ***");
          $display("Address : %h", dut.aluout);
          $display("Data    : %h\n", dut.writedata);
      end
  end

  //--------------------------------------------------
  // Waveform Dump
  //--------------------------------------------------
  initial begin
      $dumpfile("mips.vcd");
      $dumpvars(0,mips_tb);
  end

endmodule
