// ITCH parse + order book (100 MHz domain).
`timescale 1ns / 1ps

import itch_types::*;

module itch_hw_core (
    input  logic        clk,
    input  logic        rst,
    input  logic [ 7:0] byte_in,
    input  logic        byte_valid,
    output logic        byte_ready,
    output logic [31:0] bbo_bid_price,
    output logic [31:0] bbo_ask_price,
    output logic [31:0] bbo_bid_shares,
    output logic [31:0] bbo_ask_shares,
    output logic        record_valid,
    output logic        bbo_valid,
    output logic        parse_error,
    output logic        book_error
);

  itch_record_t record;
  logic         rec_valid;
  logic         parse_err;

  itch_pipeline u_pipe (
      .clk          (clk),
      .rst          (rst),
      .byte_in      (byte_in),
      .byte_valid   (byte_valid),
      .byte_ready   (byte_ready),
      .record       (record),
      .record_valid (rec_valid),
      .parse_error  (parse_err)
  );

  order_book u_book (
      .clk            (clk),
      .rst            (rst),
      .record         (record),
      .record_valid   (rec_valid),
      .bbo_bid_price  (bbo_bid_price),
      .bbo_ask_price  (bbo_ask_price),
      .bbo_bid_shares (bbo_bid_shares),
      .bbo_ask_shares (bbo_ask_shares),
      .bbo_valid      (bbo_valid),
      .book_error     (book_error)
  );

  assign record_valid = rec_valid;
  assign parse_error  = parse_err;

endmodule
