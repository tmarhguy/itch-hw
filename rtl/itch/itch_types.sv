// NASDAQ ITCH 5.0 subset types (Add / Execute / Cancel).
`ifndef ITCH_TYPES_SV
`define ITCH_TYPES_SV

package itch_types;

  localparam int unsigned OrderSlots = 512;
  localparam int unsigned OrderIdxW  = 9;

  typedef enum logic [2:0] {
    MsgNone   = 3'd0,
    MsgAdd    = 3'd1,
    MsgExec   = 3'd2,
    MsgCancel = 3'd3
  } itch_msg_e;

  typedef enum logic {
    SideBuy  = 1'b0,
    SideSell = 1'b1
  } itch_side_e;

  localparam int unsigned LenAdd    = 36;
  localparam int unsigned LenExec   = 31;
  localparam int unsigned LenCancel = 23;

  typedef struct packed {
    itch_msg_e   msg;
    logic [47:0] timestamp_ns;
    logic [63:0] order_ref;
    logic [63:0] stock;
    itch_side_e  side;
    logic [31:0] price;
    logic [31:0] shares;
    logic [31:0] aux_shares;
  } itch_record_t;

  function automatic int unsigned msg_len_bytes(input logic [7:0] msg_type);
    case (msg_type)
      8'h41: msg_len_bytes = LenAdd;    // 'A'
      8'h45: msg_len_bytes = LenExec;   // 'E'
      8'h58: msg_len_bytes = LenCancel; // 'X'
      default: msg_len_bytes = 0;
    endcase
  endfunction

  function automatic itch_msg_e msg_from_char(input logic [7:0] c);
    case (c)
      8'h41: msg_from_char = MsgAdd;
      8'h45: msg_from_char = MsgExec;
      8'h58: msg_from_char = MsgCancel;
      default: msg_from_char = MsgNone;
    endcase
  endfunction

endpackage

`endif