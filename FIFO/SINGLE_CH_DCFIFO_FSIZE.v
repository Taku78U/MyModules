
`default_nettype none

module SINGLE_CH_DCFIFO_FSIZE
  #(parameter DW = 27,
    parameter LEN_LOG_A = 5'd12,
    parameter LEN_LOG_B = 9,
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
  always @(negedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      rden_ffa <= 1'b0;
      rden_ffb <= 1'b0;
    end else begin
      rden_ffa <= wsel;
      rden_ffb <= rden_ffa;
    end
  end
  wire rden;
  assign rden = rden_ffb;

  // しきい値実装部
  reg [1:0] rd_state;
  localparam INI_RDSTATE = 2'b00;
  localparam RDWAIT = 2'b01;
  localparam RDNOW = 2'b11;
  reg [LEN_LOG_A:0] rdthr_cnt;
  always @(negedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      rd_state <= INI_RDSTATE;
    end else if(~rden) begin
      rd_state <= INI_RDSTATE;
    end else begin
      case(rd_state)
        INI_RDSTATE: begin
          if(rden) begin
            rd_state <= RDWAIT;
          end
        end
        RDWAIT: begin
          if(rdthr_cnt >= RD_THR - 1) begin
            rd_state <= RDNOW;
          end
        end
        RDNOW: begin
        end
        default: begin
          rd_state <= INI_RDSTATE;
        end
      endcase
    end
  end

  always @(negedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      rdthr_cnt <= 0;
    end else if(~rden) begin
      rdthr_cnt <= 0;
    end else if(rd_state == RDWAIT) begin
      rdthr_cnt <= rdthr_cnt + 1;
    end
  end
  wire deq;
  assign deq = (rd_state == RDNOW);

  DCFIFO_CONT_FSIZE #(.DW(DW), .LEN_LOG_A(LEN_LOG_A), .LEN_LOG_B(LEN_LOG_B))
  dcpnc (.WCLK(CLK), .RCLK(CLK), .RST_X(RST_X), .WRST(~wsel), .enq(wsel), .RRST(~rden), .deq(deq),
         .din(din), .dot(dot));

endmodule
`default_nettype wire
