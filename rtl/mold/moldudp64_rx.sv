// Minimal MoldUDP64-style unblocker: length-prefixed ITCH message bytes to parser.
`timescale 1ns / 1ps

module moldudp64_rx (
    input  logic        clk,
    input  logic        rst,
    input  logic [ 7:0] udp_payload_in,
    input  logic        udp_payload_valid,
    output logic        udp_payload_ready,
    output logic [ 7:0] itch_byte_out,
    output logic        itch_byte_valid,
    input  logic        itch_byte_ready
);

  typedef enum logic [1:0] {
    StHdr,
    StMsg,
    StSkip
  } state_e;

  state_e state_q;
  logic [15:0] msg_cnt_q;
  logic [15:0] msg_rem_q;
  logic [7:0]  len_hi_q;

  assign udp_payload_ready = itch_byte_ready && (state_q != StSkip);

  always_ff @(posedge clk) begin
    if (rst) begin
      state_q    <= StHdr;
      msg_cnt_q  <= '0;
      msg_rem_q  <= '0;
      len_hi_q   <= '0;
      itch_byte_out   <= '0;
      itch_byte_valid <= 1'b0;
    end else begin
      itch_byte_valid <= 1'b0;

      if (udp_payload_valid && udp_payload_ready) begin
        unique case (state_q)
          StHdr: begin
            if (msg_cnt_q == 0) begin
              len_hi_q  <= udp_payload_in;
              msg_cnt_q <= 16'd1;
            end else if (msg_cnt_q == 1) begin
              msg_rem_q <= {len_hi_q, udp_payload_in};
              msg_cnt_q <= '0;
              state_q   <= StMsg;
            end
          end
          StMsg: begin
            itch_byte_out   <= udp_payload_in;
            itch_byte_valid <= 1'b1;
            if (msg_rem_q <= 16'd1) begin
              msg_rem_q <= '0;
              state_q   <= StHdr;
            end else begin
              msg_rem_q <= msg_rem_q - 16'd1;
            end
          end
          default: state_q <= StHdr;
        endcase
      end
    end
  end

endmodule
