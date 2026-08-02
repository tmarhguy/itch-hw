`timescale 1ns / 1ps

module itch_hw_tb (
    input logic clk,
    input logic rst
);

  logic [7:0] byte_in;
  logic       byte_valid;
  logic       byte_ready;

  logic [31:0] bbo_bid_price, bbo_ask_price;
  logic [31:0] bbo_bid_shares, bbo_ask_shares;
  logic        record_valid, bbo_valid, parse_error, book_error;

  itch_hw_core dut (
      .clk            (clk),
      .rst            (rst),
      .byte_in        (byte_in),
      .byte_valid     (byte_valid),
      .byte_ready     (byte_ready),
      .bbo_bid_price  (bbo_bid_price),
      .bbo_ask_price  (bbo_ask_price),
      .bbo_bid_shares (bbo_bid_shares),
      .bbo_ask_shares (bbo_ask_shares),
      .record_valid   (record_valid),
      .bbo_valid      (bbo_valid),
      .parse_error    (parse_error),
      .book_error     (book_error)
  );

endmodule
