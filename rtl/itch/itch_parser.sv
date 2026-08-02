// Legacy name: ITCH byte pipeline (replaces counter stub).
`timescale 1ns / 1ps

import itch_types::*;

module itch_parser (
    input  logic        clk,
    input  logic        rst,
    input  logic [ 7:0] byte_in,
    input  logic        byte_valid,
    output logic        byte_ready,
    output itch_record_t record,
    output logic        record_valid,
    output logic        parse_error,
    // Board-friendly debug (BBO bid price when wired through itch_hw_core)
    output logic [31:0] stock_price_hex,
    output logic        msg_valid,
    output logic        error_flag
);

  itch_pipeline u_pipe (
      .clk          (clk),
      .rst          (rst),
      .byte_in      (byte_in),
      .byte_valid   (byte_valid),
      .byte_ready   (byte_ready),
      .record       (record),
      .record_valid (record_valid),
      .parse_error  (parse_error)
  );

  assign stock_price_hex = record.price;
  assign msg_valid       = record_valid;
  assign error_flag      = parse_error;

endmodule
