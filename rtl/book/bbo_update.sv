// Pipelined BBO publish (<= 6 cycles from record_valid).
`timescale 1ns / 1ps

module bbo_update (    input  logic        clk,
    input  logic        rst,
    input  logic        record_valid,
    input  logic [31:0] comb_bid,
    input  logic [31:0] comb_ask,
    input  logic [31:0] comb_bid_sh,
    input  logic [31:0] comb_ask_sh,
    output logic [31:0] bbo_bid_price,
    output logic [31:0] bbo_ask_price,
    output logic [31:0] bbo_bid_shares,
    output logic [31:0] bbo_ask_shares,
    output logic        bbo_valid
);

  localparam int unsigned Stages = 6;

  logic [31:0] bid_pipe[Stages];
  logic [31:0] ask_pipe[Stages];
  logic [31:0] bidsh_pipe[Stages];
  logic [31:0] asksh_pipe[Stages];
  logic        valid_pipe[Stages];

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < Stages; i++) begin
        bid_pipe[i]   <= '0;
        ask_pipe[i]   <= '0;
        bidsh_pipe[i] <= '0;
        asksh_pipe[i] <= '0;
        valid_pipe[i] <= 1'b0;
      end
    end else begin
      valid_pipe[0] <= record_valid;
      bid_pipe[0]   <= comb_bid;
      ask_pipe[0]   <= comb_ask;
      bidsh_pipe[0] <= comb_bid_sh;
      asksh_pipe[0] <= comb_ask_sh;

      for (int i = 1; i < Stages; i++) begin
        valid_pipe[i] <= valid_pipe[i - 1];
        bid_pipe[i]   <= bid_pipe[i - 1];
        ask_pipe[i]   <= ask_pipe[i - 1];
        bidsh_pipe[i] <= bidsh_pipe[i - 1];
        asksh_pipe[i] <= asksh_pipe[i - 1];
      end
    end
  end

  assign bbo_bid_price  = bid_pipe[Stages - 1];
  assign bbo_ask_price  = ask_pipe[Stages - 1];
  assign bbo_bid_shares = bidsh_pipe[Stages - 1];
  assign bbo_ask_shares = asksh_pipe[Stages - 1];
  assign bbo_valid      = valid_pipe[Stages - 1];

endmodule