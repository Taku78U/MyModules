`timescale 1ns / 1ps
`default_nettype none
module test;
  parameter clock_half_period = 10;
  parameter SLOOP_MAX = 100;
  parameter DW = 8;
  
  /* input */   
  reg CLK;
  reg RST_X;
  wire wen;
  wire [DW-1:0] din;
  
  /* TXoutput */
  wire TX;
  wire rdy;

  /* SERT_VER out */
  wire RX;
  wire rxvalid;

  /* RXout */
  wire [DW-1:0] dot;
  wire valid;

  assign wen = rdy;
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
  
  
  SERT_VER #(.SLOOP_MAX(SLOOP_MAX), .DW(DW))
  uut(.CLK(CLK), .RST_X(RST_X), .RX(TX), .TX(RX));

  wire [DW-1:0] data [0:4];
  assign data[0] = "V";
  assign data[1] = "E";
  assign data[2] = "R";
  assign data[3] = 8'h0d; // <CR>
  assign data[4] = 8'h0a; // <LF>

  reg [2:0] wr_ptr;
  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      wr_ptr <= 0;
    end else if(wen & (wr_ptr < 4)) begin
      wr_ptr <= wr_ptr + 1;
    end else if(wen & (wr_ptr >= 4)) begin
      wr_ptr <= 0;
    end
  end

  assign din = data[wr_ptr];

  TX_SEND #(.SLOOP_MAX(SLOOP_MAX), .DW(DW))
  ts (.CLK(CLK), .RST_X(RST_X), .wen(wen), .din(din), .rdy(rdy), .TX(TX));
  
  RX_RECV #(.SLOOP_MAX(SLOOP_MAX), .DW(DW))
  rs (.CLK(CLK), .RST_X(RST_X), .RX(RX), .valid(valid), .dot(dot));

  integer F_HNDL;
  initial begin
    F_HNDL = $fopen ("RDOT.log", "w");
  end

  reg [31:0] cnt = 0;
  always @(posedge CLK) begin
    cnt <= cnt + 1;
  end

  always @(posedge CLK) begin
    $fdisplay(F_HNDL, "%d|%b|VALID:%b|DOT:%x", cnt, RST_X, valid, dot);
  end

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
