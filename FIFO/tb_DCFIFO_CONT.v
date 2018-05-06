`timescale 1ns / 1ns
`default_nettype none
module test;
  parameter clocka_half_period = 10;
  parameter clockb_half_period = 9;
  parameter DW = 27;
  parameter EN_BIT = 25;

  parameter DLEN = 100;

  parameter RD_THR = 11;
  
  /* input */   
  reg CLK;
  reg RCLK;
  reg RST_X;
  reg [DW-1:0] din;
  
  /* output */   
  wire [DW-1:0] dot;

  initial begin
    CLK = 0;
    forever #(clocka_half_period) CLK = ~CLK;
  end
  
  initial begin
    RCLK = 0;
    forever #(clockb_half_period) RCLK = ~RCLK;
  end
  
  initial begin
    RST_X = 1;
    din[EN_BIT] = 1'b0;
    #20;
    RST_X = 0;
    #1000;
    RST_X = 1;
    #200;
    din[EN_BIT] = 1'b1;
    #(clocka_half_period * 2 * DLEN);
    din[EN_BIT] = 1'b0;
  end

  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      din[DW-1:EN_BIT+1] <= 0;
      din[EN_BIT-1:0] <= 0;
    end else if(din[EN_BIT]) begin
      {din[DW-1:EN_BIT+1], din[EN_BIT-1:0]} <= {din[DW-1:EN_BIT+1], din[EN_BIT-1:0]} + 1;
    end
  end

  reg cnt = 0;
  reg rdcnt = 0;
  always @(posedge CLK) begin
    cnt <= cnt + 1;
  end
  always @(negedge RCLK) begin
    rdcnt <= rdcnt + 1;
  end

  wire [DW-2:0] tdin;
  wire wflag;
  wire [DW-2:0] tdot;
  wire valid;

  assign tdin = {din[DW-1:EN_BIT+1], din[EN_BIT-1:0]};
  assign wflag = din[EN_BIT];
  assign tdot = {dot[DW-1:EN_BIT+1], dot[EN_BIT-1:0]};
  assign valid = dot[EN_BIT];

  DCFIFO_CONT #(.DW(DW), .RD_THR(RD_THR), .FIFO_LEN_LOG(5)) uut (CLK, RCLK, RST_X, 1'b0, 1'b1, din, dot);
  
  initial begin
    $dumpfile("uut.vcd");
    $dumpvars(0, uut);
  end

  initial begin
    #100000;
    $finish;
  end
endmodule
`default_nettype wire
