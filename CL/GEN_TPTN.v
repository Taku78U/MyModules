`default_nettype none

module GEN_TPTN
  #(parameter DW = 24,
    parameter L_LEN = 32,
    parameter H_LEN = 24,
    parameter INT_LINE = 2,
    parameter INT_LR_DR = 1,
    parameter INT_DF_LF = 2,
    parameter FR_LR_H = 0, // 最初何本か水平画素が出力されるもの 未実装
    parameter LF_FF_H = 0, // 最初何本か水平画素が出力されるもの 未実装
    parameter INVAL_L_MOE = 0, // 無効LINE時もLVALを立てるか 未実装

    parameter INT_H = 1, // 同期間隔(クロック数)

    parameter TPTN_A = 10'h155,
    parameter TPTN_B = 10'h2aa

    )
  (input  wire CLK, RST_X,
   input  wire en,
   output wire [3+DW-1:0] dot);


  parameter LPIX = INT_LINE + L_LEN + INT_LR_DR + INT_DF_LF;
  parameter HPIX = H_LEN + FR_LR_H + LF_FF_H;
  parameter SUMPIX = LPIX * HPIX;

  always @(negedge RST_X) begin
    $display("%d", LPIX);
  end

  wire fval;
  wire lval;
  wire dval;
  assign dot[DW+3-1] = dval;
  assign dot[DW+3-2] = fval;
  assign dot[DW+3-3] = lval;

  reg [31:0] fcnt, lcnt, dcnt, hcnt;


  localparam S_SUMPIX = INT_H + LPIX * HPIX; // 同期間隔も含める

  // fvalの動き
  always @(negedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      fcnt <= 0;
    end else if((fcnt >= S_SUMPIX - 1) | ~en) begin
      fcnt <= 0;
    end else if(en) begin
      fcnt <= fcnt + 1;
    end
  end

  assign fval= en & (fcnt >= INT_H); // fvalの1サイクル前 これでLVAL以下を制御

  always @(negedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      lcnt <= 0;
    end else if(lcnt >= LPIX - 1) begin
      lcnt <= 0;
    end else if(fval) begin
      lcnt <= lcnt + 1;
    end else if(~fval) begin
      lcnt <= 0;
    end
  end

  assign lval = fval & (lcnt >= INT_LINE);

  always @(negedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      dcnt <= 0;
    end else if(lval) begin
      dcnt <= dcnt + 1;
    end else if(~lval) begin
      dcnt <= 0;
    end
  end
  assign dval = (dcnt >= INT_LR_DR) & (dcnt < INT_LR_DR + L_LEN);

  // data
  reg ptr;
  wire [DW-1:0] tptn [0:1];
  assign tptn[0] = {{14{1'b1}}, TPTN_A};
  assign tptn[1] = {{14{1'b1}}, TPTN_B};

  always @(negedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      ptr <= 1'b1;
    end else if(fcnt == INT_H - 1) begin
      ptr <= ~ptr;
    end else if(dval) begin
      ptr <= ~ptr;
    end else if(~en) begin
      ptr <= 1'b1;
    end
  end

  assign dot[DW-1:0] = tptn[ptr];

endmodule


`default_nettype wire
