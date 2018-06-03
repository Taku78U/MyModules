`default_nettype none

//レジスタベースで実装可能な短いFIFO

module SINGLE_CH_DCFIFO_S
  #(parameter DW = 27,
    parameter LEN_LOG = 2,
    parameter RD_THR = 13'd4300
    )
  (input  wire CLK, RST_X,
   input  wire FRST, // CLK posに同期済
   input  wire sel, // CLK posに同期済
   input  wire [DW-1:0] din,
   output wire [DW-1:0] dot);

  // CLK neg シンクロナイザ
  reg wsel;
  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      wsel <= 1'b0;
    end else begin
      wsel <= sel & ~FRST;
    end
  end

  reg rden_ffa;
  reg rden_ffb;
  reg rden_ffc;
  always @(negedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      rden_ffa <= 1'b0;
      rden_ffb <= 1'b0;
      rden_ffc <= 1'b0;
    end else begin
      rden_ffa <= wsel;
      rden_ffb <= rden_ffa;
      rden_ffc <= rden_ffb;
    end
  end
  wire rden;
  assign rden = rden_ffc;

  wire [DW-1:0] dot_w;
  reg  [DW-1:0] dot_reg;  
  SDCFIFO_REG #(.DW(DW), .LEN_LOG(LEN_LOG))
  dcpnc (.WCLK(CLK), .RCLK(CLK), .RST_X(RST_X), .WRST(~wsel), .RRST(~rden), .deq(rden),
         .din(din), .dot(dot_w));

  always @(negedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      dot_reg <= 0;
    end else if(~rden) begin
      dot_reg <= 0;
    end else if(rden) begin
      dot_reg <= dot_w;
    end
  end
  assign dot = dot_reg;

endmodule
`default_nettype wire
