// Placeholder ITCH parser — replace with real UDP/ITCH logic; keeps top synthesizable today.
`timescale 1ns / 1ps

module itch_parser (
    input  logic        clk,
    input  logic        rst,
    output logic [31:0] stock_price_hex,
    output logic        msg_valid,
    output logic        error_flag
);

  // Visible bring-up pattern until the parser is implemented.
  logic [27:0] tick;

  always_ff @(posedge clk) begin
    if (rst) begin
      tick             <= '0;
      stock_price_hex  <= 32'h0012_3456;
      msg_valid        <= 1'b0;
      error_flag       <= 1'b0;
    end else begin
      tick <= tick + 28'd1;
      if (tick == 28'd99_999_999) begin
        tick            <= '0;
        stock_price_hex <= stock_price_hex + 32'd1;
        msg_valid       <= 1'b1;
      end else begin
        msg_valid <= 1'b0;
      end
    end
  end

endmodule
