// Byte-stream ITCH decode wrapper (parser + optional stats).
`timescale 1ns / 1ps

import itch_types::*;

module itch_pipeline (
    input  logic        clk,
    input  logic        rst,
    input  logic [ 7:0] byte_in,
    input  logic        byte_valid,
    output logic        byte_ready,
    output itch_record_t record,
    output logic        record_valid,
    output logic        parse_error
);

  itch_byte_fsm u_fsm (
      .clk          (clk),
      .rst          (rst),
      .byte_in      (byte_in),
      .byte_valid   (byte_valid),
      .byte_ready   (byte_ready),
      .record       (record),
      .record_valid (record_valid),
      .parse_error  (parse_error)
  );

endmodule
