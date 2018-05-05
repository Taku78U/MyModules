`timescale 1ns / 1ps
`default_nettype none
module test;
  parameter clock_half_period = 10;
  localparam DW = 8;
  localparam SLOOP_MAX = 15;
  
  /* input */   
  reg CLK;
  reg RST_X;
  wire wen;
  reg [DW-1:0] din;
  
  /* TX output */   
  wire rdy;
  wire TX;

  /* RX output */
  wire [DW-1:0] dot;
  wire valid;

  initial begin
    CLK = 0;
    forever #(clock_half_period) CLK = ~CLK;
  end
  
  initial begin
    RST_X = 1;
    #5;
    RST_X = 0;
    #1000;
    RST_X = 1;
  end

  assign wen = rdy;

  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      din <= 8'b01010101;
    end else if(rdy) begin
      din <= ~din;
    end
  end

  TX_SEND #(.SLOOP_MAX(SLOOP_MAX), .DW(DW))
  uut(CLK, RST_X, wen, din, rdy, TX);  

  RX_RECV #(.SLOOP_MAX(SLOOP_MAX), .DW(DW))
  uutr(CLK, RST_X, TX, dot, valid);  

  integer F_HNDL;
  initial begin
    F_HNDL = $fopen("TX.log", "w");
  end

  reg [31:0] cnt = 0;
  always @(posedge CLK) begin
    cnt <= cnt + 1;
  end
  
  always @(posedge CLK) begin
    $fdisplay(F_HNDL, "%x|%b|WEN:%b|DIN:%d|TXD:%b|TX:%b|SCNT:%d|CNT:%d|RXDOT:%d|VALID:%b|RCNT:%d|RBC:%d|RXD:%b", cnt, RST_X, wen, din, uut.TXD, TX, uut.scnt, uut.cnt, dot, valid, uutr.cnt, uutr.bcnt, uutr.RXD);
  end  
  
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
