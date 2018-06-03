`timescale 1ns / 1ps
`default_nettype none
module test;
  parameter clock_half_period = 10;
  
  /* input */   
  reg CLK;
  reg RST_X;
  
  /* output */   
  wire ULED;

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
  end
  
  L_TIKA uut(CLK, RST_X, ULED);
  
  initial begin
    $dumpfile("uut.vcd");
    $dumpvars(0, uut);
  end

  initial begin
    #10000;
    $finish;
  end
endmodule

module L_TIKA(CLK, RST_X, ULED);
  parameter WIDTH = 32;
  
  input CLK;
  input RST_X;
  output ULED;
  
  reg [WIDTH-1:0] cnt;

  assign ULED = cnt[2];

  always @(posedge CLK or negedge RST_X) begin
    if (!RST_X) begin
      cnt <= 0;
    end else begin
      cnt <= cnt + 1;
    end
  end

endmodule
`default_nettype wire
