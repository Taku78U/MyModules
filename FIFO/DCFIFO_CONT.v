`default_nettype none

// 連続データストリームのためのFIFO
// W側がR側の倍以上の周波数を持つとNG

module DCFIFO_CONT
  #(parameter DW = 27,
    parameter FIFO_LEN_LOG = 8,
    parameter RD_THR = 8, // 読み出ししきい値
    parameter EN_BIT = 25
  )
  (input  wire WCLK,
   input  wire RCLK,
   input  wire RST_X,
   input  wire FRST, // 初期リセット以外
   input  wire wen,    // asynchronous
   input  wire [DW-1:0] din,
   output wire [DW-1:0] dot
   );

  reg  [DW-1:0] dot_reg;
  localparam FIFO_LEN = 1 << FIFO_LEN_LOG;
  reg [DW-1:0] mem [0:FIFO_LEN-1];
  reg [FIFO_LEN_LOG:0] wrptr, rdptr;
  wire [FIFO_LEN_LOG-1:0] wradr, rdadr;
  assign wradr = wrptr[FIFO_LEN_LOG-1:0];
  assign rdadr = rdptr[FIFO_LEN_LOG-1:0];

  wire wwen; // wen synced with WCLK
  TRPL_FF_snc_pos wrsnc (WCLK, RST_X, wen & ~FRST, wwen);

  reg val_pre, val_pre_b; // 2個だけ余分なデータを書く
  always @(posedge WCLK or negedge RST_X) begin
    if(~RST_X) begin
      val_pre <= 1'b0;
      val_pre_b <= 1'b0;
    end else begin
      val_pre <= din[EN_BIT];
      val_pre_b <= val_pre;
    end
  end
  

  wire enq;
  assign enq = wwen & ((din[EN_BIT] == 1'b1) | (val_pre == 1'b1) | (val_pre_b == 1'b1));
  wire rden; // wwen synced with RCLK
  wire F_RRST;
  TRPL_FF_snc_neg rdsnc (RCLK, RST_X, enq, rden);
  TRPL_FF_snc_neg rdsnc_f (RCLK, RST_X, FRST, F_RRST);

  reg [6:0] rtcnt;
  reg [6:0] fincnt;

  reg [2:0] rdstate;
  localparam INI_RDSTATE = 0;
  localparam WARMUP = 1; // しきい値実現
  localparam INIRD = 3; // まずひとつ読み出す(フラグ誤判定防止)
  localparam RDNOW = 2;
  //localparam FIN = 4; // 終了フラグをWrite側に送りリセット

  localparam FIN_THR = 9;
  always @(negedge RCLK or negedge RST_X) begin
    if(~RST_X) begin
      rdstate <= INI_RDSTATE;
    end else if(RRST) begin
      rdstate <= INI_RDSTATE;
    end else begin
      case(rdstate)
        INI_RDSTATE: begin
          if(rden) begin
            rdstate <= WARMUP;
          end
        end
        WARMUP: begin
          if(rtcnt >= RD_THR) begin
            rdstate <= INIRD;
          end
        end
        INIRD: begin
          rdstate <= RDNOW;
        end
        RDNOW: begin
          if(dot_reg[EN_BIT] == 1'b0) begin
//            rdstate <= FIN;
            rdstate <= INI_RDSTATE;
          end
        end
//        FIN: begin
//          if(fincnt >= FIN_THR) begin
//            rdstate <= INI_RDSTATE;
//          end
//        end
        default: begin
          rdstate <= INI_RDSTATE;
        end
      endcase
    end
  end
  
  always @(negedge RCLK or negedge RST_X) begin
    if(~RST_X) begin
      rtcnt <= 0;
    end else if((rdstate == WARMUP) & (rtcnt < RD_THR)) begin
      rtcnt <= rtcnt + 1;
    end else if(RRST) begin
      rtcnt <= 0;
    end else begin
      rtcnt <= 0;
    end
  end

//  always @(negedge RCLK or negedge RST_X) begin
//    if(~RST_X) begin
//      fincnt <= 0;
//    end else if(rdstate == FIN) begin
//      fincnt <= fincnt + 1;
//    end else begin
//      fincnt <= 0;
//    end
//  end

  wire deq;
  assign deq = (rdstate == RDNOW) | (rdstate == INIRD);
  //assign deq = (rdstate == RDNOW) | ((rdstate == INIRD) & (dot_reg[EN_BIT] == 1'b1));
  // 本来はこっちだが、下記alwaysブロック内の優先順位で定義した

//  reg rdfin;
//  // Writeポインタリセット
//  // RTL的には「読み終えたらRDポインタをWRポインタに合わせる
//  always @(negedge RCLK or negedge RST_X) begin
//    if(~RST_X) begin
//      rdfin <= 1'b0;
//    end else begin
//      rdfin <= (rdstate == RD_FIN);
//    end
//  end

  // FIFOはデータ中のフラグが0かつ読み込み中の場合のみリセットされる
  // Write側で最後に数個だけフラグ0なデータを書く必要がある

  wire RRST;
  assign RRST = ((rdstate == RDNOW) & (dot_reg[EN_BIT] == 1'b0)) | F_RRST; // 前半はrdstateのRDNOW->INI_RDSTATE遷移条件

  always @(posedge WCLK or negedge RST_X) begin
    if(~RST_X) begin
      wrptr <= 0;
    end else if(enq) begin
      wrptr <= wrptr + 1;
    end else begin
      wrptr <= 0;
    end
  end

  always @(posedge WCLK) begin
    if(enq) begin
      mem[wradr] <= din;
    end
  end

  always @(negedge RCLK or negedge RST_X) begin
    if(~RST_X) begin
      rdptr <= 0;
    end else if(RRST) begin
      rdptr <= 0;
    end else if(deq) begin
      rdptr <= rdptr + 1;
    end
  end

  always @(negedge RCLK) begin
    if(~RST_X) begin
      dot_reg <= 0;
    end else if(deq) begin
      dot_reg <= mem[rdadr];
    end
  end

  assign dot[DW-1:EN_BIT+1] = dot_reg[DW-1:EN_BIT+1];
  assign dot[EN_BIT] = dot_reg[EN_BIT] & (rdstate == RDNOW);
  assign dot[EN_BIT-1:0] = dot_reg[EN_BIT-1:0];

endmodule
`default_nettype wire
