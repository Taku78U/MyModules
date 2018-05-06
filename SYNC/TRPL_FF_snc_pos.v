`default_nettype none

module TRPL_FF_snc_pos
 (input  wire CLK, RST_X,
  input  wire din, // asynchronous signal
  output reg  dot);

  reg aff, bff;
  always @(posedge CLK or negedge RST_X) begin
    if(~RST_X) begin
      aff <= 1'b0;
      bff <= 1'b0;
      dot <= 1'b0;
    end else begin
      aff <= din;
      bff <= aff;
      dot <= bff;
    end
  end

endmodule

`default_nettype wire
