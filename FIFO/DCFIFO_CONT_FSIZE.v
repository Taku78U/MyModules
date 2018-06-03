`timescale 1ns / 1ps
`default_nettype none

// 2のべき乗でないFIFO
// FIFO2コで実装できるもの

module DCFIFO_CONT_FSIZE
  #(parameter DW = 32,
    parameter LEN_LOG_A = 12, LEN_LOG_B = 9, // LEN_LOG_A > LEN_LOG_B
    parameter LEN_A = 1 << LEN_LOG_A,
    parameter LEN_B = 1 << LEN_LOG_B)
 (input  wire WCLK, RCLK, RST_X,
  input  wire WRST, RRST,
  input  wire enq, deq,
  input  wire [DW-1:0] din,
  output wire [DW-1:0] dot
  );

  reg [DW-1:0] mem_a [0:LEN_A-1];
  reg [DW-1:0] mem_b [0:LEN_B-1];

  reg  [(LEN_LOG_A+1)-1:0] wadr; // 最上位bitはmem選択用
  wire [LEN_LOG_A-1:0] wadr_a;
  wire [LEN_LOG_B-1:0] wadr_b;
  assign wadr_a = wadr[LEN_LOG_A-1:0];
  assign wadr_b = wadr[LEN_LOG_B-1:0];

  reg  [(LEN_LOG_A+1)-1:0] radr; // 最上位bitはmem選択用
  wire [LEN_LOG_A-1:0] radr_a;
  wire [LEN_LOG_B-1:0] radr_b;
  assign radr_a = radr[LEN_LOG_A-1:0];
  assign radr_b = radr[LEN_LOG_B-1:0];

  reg [DW-1:0] dot_a, dot_b;
  reg [DW-1:0] dot_ff;
  reg rdmemsel_ff;

  always @(negedge RCLK or negedge RST_X) begin
    if(~RST_X) begin
      rdmemsel_ff <= 1'b0;
    end else if(RRST) begin
      rdmemsel_ff <= 1'b0;
    end else if(deq) begin
      rdmemsel_ff <= radr[LEN_LOG_A];
    end
  end

  localparam LEN_SUM = LEN_A + LEN_B;
  always @(posedge WCLK or negedge RST_X) begin
    if(~RST_X) begin
      wadr <= 0;
    end else if(WRST) begin
      wadr <= 0;
    end else if(enq & (wadr >= LEN_SUM - 1)) begin
      wadr <= 0;
    end else if(enq) begin
      wadr <= wadr + 1;
    end
  end

  always @(negedge RCLK or negedge RST_X) begin
    if(~RST_X) begin
      radr <= 0;
    end else if(RRST) begin
      radr <= 0;
    end else if(deq & (radr >= LEN_SUM - 1)) begin
      radr <= 0;
    end else if(deq) begin
      radr <= radr + 1;
    end
  end

  always @(posedge WCLK) begin
    if(enq & wadr[LEN_LOG_A]) begin
      mem_b[wadr_b] <= din;
    end else if(enq & ~wadr[LEN_LOG_A])
      mem_a[wadr_a] <= din;
  end

  always @(negedge RCLK or negedge RST_X) begin
    if(~RST_X) begin
      dot_a <= 0;
    end else if(deq) begin
      dot_a <= mem_a[radr_a];
    end
  end

  always @(negedge RCLK or negedge RST_X) begin
    if(~RST_X) begin
      dot_b <= 0;
    end else if(deq) begin
      dot_b <= mem_b[radr_b];
    end
  end

  reg deq_ff;
  always @(negedge RCLK or negedge RST_X) begin
    if(~RST_X) begin
      deq_ff <= 0;
    end else if(RRST) begin
      deq_ff <= 1'b0;
    end else begin
      deq_ff <= deq;
    end
  end

  always @(negedge RCLK or negedge RST_X) begin
    if(~RST_X) begin
      dot_ff <= 0;
    end else if(RRST) begin
      dot_ff <= 0;
    end else if(deq_ff) begin
      dot_ff <= (rdmemsel_ff) ? dot_b : dot_a;
    end
  end

  assign dot = dot_ff;

endmodule
`default_nettype wire
