`timescale 1ns / 1ps
`default_nettype none
module test;
  parameter clock_half_period = 10;
  parameter DW = 32;
  
  /* input */   
  reg CLK;
  reg RST_X;
  reg enq;
  reg [DW-1:0] din = 0;
  
  /* output */   
  wire [DW-1:0] dot;

  initial begin
    CLK = 0;
    forever #(clock_half_period) CLK = ~CLK;
  end
  
  initial begin
    enq = 0;
    RST_X = 1;
    #1000;
    RST_X = 0;
    #1000;
    RST_X = 1;
    enq = 1;
  end

  reg [31:0] wcnt = 0, rcnt = 0;
  always @(posedge CLK) begin
    wcnt <= wcnt + 1;
  end
  always @(negedge CLK) begin
    rcnt <= rcnt + 1;
  end

  always @(posedge CLK) begin
    din <= din + 1;
  end

  integer F_HNDL_DIN, F_HNDL_DOT;
  initial begin
    F_HNDL_DIN = $fopen("DIN.log", "w");
  end
  initial begin
    F_HNDL_DOT = $fopen("DOT.log", "w");
  end
  always @(posedge CLK) begin
    if(enq) begin
      $fdisplay(F_HNDL_DIN, "%d", din);
    end
  end 
  always @(negedge CLK) begin
    $fdisplay(F_HNDL_DOT, "%d", dot);
  end
  
  SINGLE_CH_DCFIFO_FSIZE #(.DW(DW), .LEN_LOG_A(12), .LEN_LOG_B(9), .RD_THR(4300))
  uut(CLK, RST_X, 1'b0, enq, din, dot);
  
  initial begin
    $dumpfile("uut.vcd");
    $dumpvars(0, uut);
  end

  initial begin
    #1000000;
    $finish;
  end
endmodule
`default_nettype wire

