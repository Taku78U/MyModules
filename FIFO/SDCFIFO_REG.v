`timescale 1ns / 1ps
`default_nettype none

// レジスタベースのDCFIFO垂れ流し

module SDCFIFO_REG
  #(parameter DW = 32,
    parameter LEN_LOG = 2, // LEN_LOG_A > LEN_LOG_B
    parameter LEN = 1 << LEN_LOG)
 (input  wire WCLK, RCLK, RST_X,
  input  wire WRST, RRST,
  input  wire enq, deq,
  input  wire [DW-1:0] din,
  output wire [DW-1:0] dot
  );

  reg [DW-1:0] mem [0:LEN-1];

  reg  [LEN_LOG-1:0] wadr;
  wire [LEN_LOG-1:0] wadr_t;
  assign wadr_t = wadr[LEN_LOG-1:0];

  reg  [LEN_LOG-1:0] radr;
  wire [LEN_LOG-1:0] radr_t;
  assign radr_t = radr[LEN_LOG-1:0];

  always @(posedge WCLK or negedge RST_X) begin
    if(~RST_X) begin
      wadr <= 0;
    end else if(WRST) begin
      wadr <= 0;
    end else if(enq) begin
      wadr <= wadr + 1;
    end
  end

  always @(posedge WCLK) begin
    if(enq) begin
      mem[wadr_t] <= din;
    end
  end

  always @(negedge RCLK or negedge RST_X) begin
    if(~RST_X) begin
      radr <= 0;
    end else if(RRST) begin
      radr <= 0;
    end else if(deq) begin
      radr <= radr + 1;
    end
  end

  assign dot = mem[radr_t];

endmodule
`default_nettype wire
