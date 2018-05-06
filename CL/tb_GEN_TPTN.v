`timescale 1ns / 1ps
`default_nettype none
module test;
  parameter clock_half_period = 10;
  
  /* input */   
  reg CLK;
  reg RST_X;
  reg en;
  
  /* output */   
  wire ULED;
  wire [23:0] dot;
  wire fval, lval, dval;

  initial begin
    CLK = 0;
    forever #(clock_half_period) CLK = ~CLK;
  end
  
  initial begin
    RST_X = 1;
    #1000;
    RST_X = 0;
    #1000;
    RST_X = 1;
    #10;
    en = 1;
  end
  
  GEN_TPTN #(.DW(24), .L_LEN(6), .H_LEN(4))
  uut(CLK, RST_X, en, {dval, fval, lval, dot});
  
  initial begin
    $dumpfile("uut.vcd");
    $dumpvars(0, uut);
  end

  initial begin
    #10000;
    $finish;
  end
endmodule

`default_nettype wire
