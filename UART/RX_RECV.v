`default_nettype none

module RX_RECV
  #(parameter CLK_FREQ = 10,    // 相手先ドメインのクロック周波数[MHz]
    parameter BAUDRATE = 9600,  // 単位は[bps]
    parameter SLOOP_MAX = CLK_FREQ*1000*1000/BAUDRATE,
    // シミュレーションはここをオーバーライド(上はコード中不使用)
    
    parameter DW = 8
  )
  (input  wire CLK,
   input  wire RST_X,
   input  wire RX,
   output wire [DW-1:0] dot,
   output wire valid);

  reg [DW-1+2:0] RXD;

  reg [2:0] shreg;

  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      shreg <= 3'b111;
    end else begin
      shreg <= {shreg[1:0], RX};
    end
  end

  // Startエッジ検出
  wire start;
  reg busy;
  assign start = ~busy & (shreg[2] == 1'b0);

  wire fin; // 始まりがあれば、終わりもあるんだよ
  
  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      busy <= 1'b0;
    end else begin
      if(start) begin
        busy <= 1'b1;
      end else if(fin) begin
        busy <= 1'b0;
      end
    end
  end

  reg [31:0] cnt; // サンプリングカウンタ
  wire samp; // サンプリング
  assign samp = busy & (cnt == 0);
  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      cnt <= 0;
    end else if(start) begin
      cnt <= (SLOOP_MAX >> 1);
    end else if(samp) begin
      cnt <= SLOOP_MAX;
    end else if(busy) begin
      cnt <= cnt - 1;
    end else begin
      cnt <= 0;
    end
  end

  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      RXD <= 0;
    end else if(samp) begin
      RXD <= {shreg[2], RXD[DW-1+2:1]};
    end
  end

  reg [4:0] bcnt; // ビットカウンタ(すなわちサンプリング回数カウンタ)
  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      bcnt <= 0;
    end else if(samp) begin
      bcnt <= bcnt + 1;
    end else if(busy) begin
      bcnt <= bcnt;
    end else begin
      bcnt <= 0;
    end
  end

  assign fin = (bcnt == 9) & samp;
  reg fin_reg; // データチェックトリガ
  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      fin_reg <= 1'b0;
    end else begin
      fin_reg <= fin;
    end
  end

  reg valid_reg;
  reg [DW-1:0] dot_reg;
  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      valid_reg <= 1'b0;
      dot_reg <= 0;
    end else if(fin_reg & (RXD[0] === 1'b0) & (RXD[DW-1+2] == 1'b1)) begin
      valid_reg <= 1'b1;
      dot_reg <= RXD[DW:1];
    end else begin
      valid_reg <= 1'b0;
      dot_reg <= dot_reg;
    end
  end
  assign valid = valid_reg;
  assign dot = dot_reg;

endmodule
`default_nettype wire
