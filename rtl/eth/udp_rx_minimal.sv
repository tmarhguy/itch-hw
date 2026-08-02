// Minimal IPv4/UDP RX: extracts UDP payload bytes (lab / point-to-point).
`timescale 1ns / 1ps

module udp_rx_minimal #(
    parameter int DST_PORT = 50000
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        frame_end,
    input  logic [ 7:0] mac_byte_in,
    input  logic        mac_byte_valid,
    output logic        mac_byte_ready,
    output logic [ 7:0] payload_out,
    output logic        payload_valid,
    input  logic        payload_ready
);

  typedef enum logic [2:0] {
    StIdle,
    StEth,
    StIp,
    StUdp,
    StPay
  } state_e;

  state_e state_q;
  logic [15:0] eth_rem_q;
  logic [15:0] ip_rem_q;
  logic [7:0]  ip_proto_q;
  logic [15:0] udp_rem_q;
  logic [15:0] dst_port_q;

  assign mac_byte_ready = payload_ready || (state_q != StPay);

  always_ff @(posedge clk) begin
    if (rst) begin
      state_q       <= StIdle;
      eth_rem_q     <= '0;
      ip_rem_q      <= '0;
      udp_rem_q     <= '0;
      dst_port_q    <= '0;
      ip_proto_q    <= '0;
      payload_out   <= '0;
      payload_valid <= 1'b0;
    end else begin
      payload_valid <= 1'b0;

      if (frame_end && state_q != StIdle) begin
        state_q <= StIdle;
      end else if (mac_byte_valid && mac_byte_ready) begin
        unique case (state_q)
          StIdle: begin
            eth_rem_q <= 16'd13;
            state_q   <= StEth;
          end
          StEth: begin
            if (eth_rem_q == 0) begin
              ip_rem_q <= 16'd19;
              state_q  <= StIp;
            end else eth_rem_q <= eth_rem_q - 16'd1;
          end
          StIp: begin
            if (ip_rem_q == 16'd10) ip_proto_q <= mac_byte_in;
            if (ip_rem_q == 0) begin
              if (ip_proto_q == 8'd17) begin
                udp_rem_q <= 16'd7;
                dst_port_q <= '0;
                state_q    <= StUdp;
              end else state_q <= StIdle;
            end else ip_rem_q <= ip_rem_q - 16'd1;
          end
          StUdp: begin
            if (udp_rem_q == 16'd5) dst_port_q[15:8] <= mac_byte_in;
            if (udp_rem_q == 16'd4) dst_port_q[7:0] <= mac_byte_in;
            if (udp_rem_q == 0) begin
              if (dst_port_q == DST_PORT[15:0]) state_q <= StPay;
              else state_q <= StIdle;
            end else udp_rem_q <= udp_rem_q - 16'd1;
          end
          StPay: begin
            payload_out   <= mac_byte_in;
            payload_valid <= 1'b1;
          end
          default: state_q <= StIdle;
        endcase
      end
    end
  end

endmodule
