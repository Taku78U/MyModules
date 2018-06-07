`default_nettype none

module SERT_VER
  #(parameter DW = 8,
    parameter RD_LEN = 5,
    parameter WR_LEN = 6,
    parameter RD_LEN_T = 8,
    parameter WR_LEN_T = 8,
    parameter SLOOP_MAX = 100
    )
  (input  wire CLK, RST_X,
   input  wire RX,
   output wire TX);

  wire rxvalid;
  wire [DW-1:0] RXDOT;

  wire [DW-1:0] data [0:RD_LEN_T-1];
  assign data[0] = "V";
  assign data[1] = "E";
  assign data[2] = "R";
  assign data[3] = 8'h0d; // <CR>
  assign data[4] = 8'h0a; // <LF>
  assign data[5] = 0;
  assign data[6] = 0;
  assign data[7] = 0;

  wire [DW-1:0] wdata [0:WR_LEN_T-1];
  assign wdata[0] = "V";
  assign wdata[1] = "1";
  assign wdata[2] = ".";
  assign wdata[3] = "0";
  assign wdata[4] = 8'h0d; // <CR>
  assign wdata[5] = 8'h0a; // <LF>
  assign wdata[6] = 0;
  assign wdata[7] = 0;

  reg [2:0] rdptr; // リードポインタ
  reg send_inst; // 書き込み開始フラグ 1クロック幅

  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      rdptr <= 0;
      send_inst <= 1'b0;
    end else begin
      if(rxvalid & (data[rdptr] == RXDOT) & (rdptr >= RD_LEN-1)) begin // <LF>
        rdptr <= 0;
        send_inst <= 1'b1;
      end else if(rxvalid & (data[rdptr] == RXDOT) & (rdptr < RD_LEN)) begin
        rdptr <= rdptr + 1;
        send_inst <= 1'b0;
      end else if(rxvalid & (data[rdptr] != RXDOT)) begin // 間違えたときは初期化
        rdptr <= 0;
        send_inst <= 1'b0;
      end else begin
        rdptr <= rdptr;
        send_inst <= 1'b0;
      end
    end
  end

  // 送信側
  reg send_inst_wr;
  wire txrdy;
  wire txfin;
  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      send_inst_wr <= 1'b0;
    end else if(send_inst) begin
      send_inst_wr <= 1'b1;
    end else if(txfin) begin // 最後の送信で落ちる
      send_inst_wr <= 1'b0;
    end
  end

  reg [2:0] wrptr;
  wire wen;
  wire [DW-1:0] din;
  assign wen = send_inst_wr & txrdy;

  assign txfin = wen & (wrptr >= WR_LEN - 1);

  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      wrptr <= 0;
    end else begin
      if(wen & (wrptr >= WR_LEN - 1)) begin
        wrptr <= 0;
      end else if(wen & (wrptr < WR_LEN - 1)) begin
        wrptr <= wrptr + 1;
      end else if(send_inst_wr) begin
        wrptr <= wrptr;
      end else begin
        wrptr <= 0;
      end
    end
  end
  
  
  assign din = wdata[wrptr];

  TX_SEND #(.SLOOP_MAX(SLOOP_MAX), .DW(DW))
  txm (CLK, RST_X, wen, din, txrdy, TX);
      
  RX_RECV #(.SLOOP_MAX(SLOOP_MAX), .DW(DW))
  rxm (CLK, RST_X, RX, RXDOT, rxvalid);
      
endmodule

`default_nettype wire
