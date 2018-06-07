`default_nettype none

module TX_SEND
  #(parameter CLK_FREQ = 10,    // [MHz]
    parameter BAUDRATE = 9600,  // 単位は[bps]
    parameter SLOOP_MAX = CLK_FREQ * 1000 * 1000 / BAUDRATE,
    // シミュレーションではここをオーバーライド(上はコード中不使用)

    parameter DW = 8
   )
  (input  wire CLK,
   input  wire RST_X,
   input  wire wen,
   input  wire [DW-1:0] din,
   output wire rdy,
   output wire TX
   );

  reg [DW-1:0] TXD;

  wire start;
  assign start = rdy & wen;

  reg TX_reg;
  reg [31:0] cnt; // 分周(シリアル送信)
  reg [4:0] bcnt; // TXDビット番号
  reg [4:0] scnt; // TXDサンプリング回数 bcntと同じだがTXDの幅を超える

  reg busy;
  assign rdy = ~busy;
  wire fin;

  wire samp = busy & (cnt == 0);
  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      busy <= 1'b1;
    end else if(start) begin
      busy <= 1'b1;
    end else if(fin) begin
      busy <= 1'b0;
    end
  end

  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      cnt <= 0;
    end else if(start | samp) begin
      cnt <= SLOOP_MAX - 1;
    end else if(busy) begin
      cnt <= cnt - 1;
    end
  end
  

  assign fin = samp & (scnt >= DW + 1);
  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      TX_reg <= 1'b1;
      //bcnt <= 0;
      TXD <= {DW{1'b1}};
      scnt <= 0;
    end else if(start) begin
      TX_reg <= 1'b0;
      TXD <= din;
      //bcnt <= 0;
      scnt <= 0;
    end else if(samp & (scnt < DW)) begin
      TX_reg <= TXD[0];
      TXD    <= {1'b1, TXD[DW-1:1]};
      //bcnt   <= bcnt + 1;
      scnt   <= scnt + 1;
    end else if(samp & (scnt == DW)) begin
      TX_reg <= 1'b1;
      //TXD <= {DW{1'b1}};
      //bcnt <= 0;
      scnt <= scnt + 1;
    end else if(samp & (scnt >= DW + 1)) begin // fin
      TX_reg <= 1'b1;
      //TXD <= {DW{1'b1}};
      //bcnt <= 0;
      scnt <= 0;
    end
  end
  
  reg TX_ff;
  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      TX_ff <=  1'b1;
    end else begin
      TX_ff <= TX_reg;
    end
  end
  assign TX = TX_ff;
  
endmodule
`default_nettype wire
