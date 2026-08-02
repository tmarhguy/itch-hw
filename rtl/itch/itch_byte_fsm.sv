// Streaming ITCH 5.0 decoder: A / E / X messages.
// record_valid pulses 1 cycle after message assembly (<= 3 cycles after last byte).
`timescale 1ns / 1ps

import itch_types::*;

module itch_byte_fsm (
    input  logic        clk,
    input  logic        rst,
    input  logic [ 7:0] byte_in,
    input  logic        byte_valid,
    output logic        byte_ready,
    output itch_record_t record,
    output logic        record_valid,
    output logic        parse_error
);

  typedef enum logic [1:0] {
    StIdle,
    StCollect,
    StDecode
  } state_e;

  // Packed message buffer (36 bytes) — avoids unpacked-array tool quirks.
  localparam int unsigned MsgBufBytes = 36;
  localparam int unsigned MsgBufWidth = MsgBufBytes * 8;

  state_e         state_q;
  logic [MsgBufWidth-1:0] msg_buf;
  logic [5:0]     byte_cnt_q;
  logic [5:0]     msg_len_q;
  logic [7:0]     msg_type_q;

  itch_record_t record_q;
  logic         record_valid_q;
  logic         parse_error_q;

  function automatic logic [7:0] buf_byte(input logic [MsgBufWidth-1:0] m, input int unsigned i);
    buf_byte = m[i*8 +: 8];
  endfunction

  assign byte_ready = (state_q != StDecode);

  always_ff @(posedge clk) begin
    if (rst) begin
      state_q        <= StIdle;
      msg_buf        <= '0;
      byte_cnt_q     <= '0;
      msg_len_q      <= '0;
      msg_type_q     <= '0;
      record_q       <= '0;
      record_valid_q <= 1'b0;
      parse_error_q  <= 1'b0;
    end else begin
      record_valid_q <= 1'b0;
      parse_error_q  <= 1'b0;

      unique case (state_q)
        StIdle: begin
          if (byte_valid) begin
            int unsigned ml;
            ml = msg_len_bytes(byte_in);
            if (ml == 0) begin
              parse_error_q <= 1'b1;
            end else begin
              msg_type_q <= byte_in;
              msg_len_q  <= ml[5:0];
              msg_buf[7:0] <= byte_in;
              byte_cnt_q <= 6'd1;
              state_q    <= StCollect;
            end
          end
        end

        StCollect: begin
          if (byte_valid) begin
            msg_buf[byte_cnt_q*8 +: 8] <= byte_in;
            if (byte_cnt_q + 6'd1 == msg_len_q) begin
              state_q <= StDecode;
            end else begin
              byte_cnt_q <= byte_cnt_q + 6'd1;
            end
          end
        end

        StDecode: begin
          itch_record_t dec;
          logic [63:0] order_ref_be;
          logic [31:0] w_a, w_b;

          dec = '0;
          dec.timestamp_ns = {
              buf_byte(msg_buf, 5), buf_byte(msg_buf, 6), buf_byte(msg_buf, 7),
              buf_byte(msg_buf, 8), buf_byte(msg_buf, 9), buf_byte(msg_buf, 10)
          };
          order_ref_be = {
              buf_byte(msg_buf, 11), buf_byte(msg_buf, 12), buf_byte(msg_buf, 13),
              buf_byte(msg_buf, 14), buf_byte(msg_buf, 15), buf_byte(msg_buf, 16),
              buf_byte(msg_buf, 17), buf_byte(msg_buf, 18)
          };
          w_a = {
              buf_byte(msg_buf, 20), buf_byte(msg_buf, 21),
              buf_byte(msg_buf, 22), buf_byte(msg_buf, 23)
          };
          w_b = {
              buf_byte(msg_buf, 32), buf_byte(msg_buf, 33),
              buf_byte(msg_buf, 34), buf_byte(msg_buf, 35)
          };

          unique case (msg_from_char(msg_type_q))
            MsgAdd: begin
              dec.msg       = MsgAdd;
              dec.order_ref = order_ref_be;
              dec.stock     = {
                  buf_byte(msg_buf, 24), buf_byte(msg_buf, 25), buf_byte(msg_buf, 26),
                  buf_byte(msg_buf, 27), buf_byte(msg_buf, 28), buf_byte(msg_buf, 29),
                  buf_byte(msg_buf, 30), buf_byte(msg_buf, 31)
              };
              dec.side      = (buf_byte(msg_buf, 19) == 8'h42) ? SideBuy : SideSell;
              dec.shares    = w_a;
              dec.price     = w_b;
            end
            MsgExec: begin
              dec.msg        = MsgExec;
              dec.order_ref  = order_ref_be;
              dec.aux_shares = {
                  buf_byte(msg_buf, 19), buf_byte(msg_buf, 20),
                  buf_byte(msg_buf, 21), buf_byte(msg_buf, 22)
              };
            end
            MsgCancel: begin
              dec.msg        = MsgCancel;
              dec.order_ref  = order_ref_be;
              dec.aux_shares = {
                  buf_byte(msg_buf, 19), buf_byte(msg_buf, 20),
                  buf_byte(msg_buf, 21), buf_byte(msg_buf, 22)
              };
            end
            default: dec.msg = MsgNone;
          endcase

          if (dec.msg == MsgNone) begin
            parse_error_q <= 1'b1;
          end else begin
            record_q       <= dec;
            record_valid_q <= 1'b1;
          end
          state_q    <= StIdle;
          byte_cnt_q <= '0;
        end

        default: state_q <= StIdle;
      endcase
    end
  end

  assign record       = record_q;
  assign record_valid = record_valid_q;
  assign parse_error  = parse_error_q;

endmodule
