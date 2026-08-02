// Top-level Nexys A7-100T: optional GbE ingress + ITCH core + display.
`timescale 1ns / 1ps

module nexys_a7_100t_top #(
    parameter bit USE_ETH = 1'b1,
    parameter int UDP_DST_PORT = 50000
) (
    input  logic        CLK100MHZ,
    input  logic        rst,
    output logic        ca,
    output logic        cb,
    output logic        cc,
    output logic        cd,
    output logic        ce,
    output logic        cf,
    output logic        cg,
    output logic [ 7:0] an,
    output logic [15:0] LED,
    // RMII to SMSC LAN8720A (used when USE_ETH=1)
    input  logic        eth_refclk,
    input  logic [ 1:0] eth_rxd,
    input  logic        eth_crs_dv,
    output logic [ 1:0] eth_txd,
    output logic        eth_txen,
    inout  logic        eth_mdc,
    inout  logic        eth_mdio,
    output logic        eth_rstn
);

  logic        rst_sync;
  logic [ 1:0] rst_pipe;

  logic [ 7:0] byte_in;
  logic        byte_valid;
  logic        byte_ready;

  logic [31:0] bbo_bid_price, bbo_ask_price;
  logic [31:0] bbo_bid_shares, bbo_ask_shares;
  logic        record_valid, bbo_valid, parse_error, book_error;

  logic [23:0] pulse_stretch;
  logic [23:0] bbo_stretch;
  logic        link_up_led;

  always_ff @(posedge CLK100MHZ) begin
    rst_pipe <= {rst_pipe[0], rst};
    rst_sync <= rst_pipe[1];
  end

  generate
    if (USE_ETH) begin : gen_eth
      logic [7:0] udp_payload;
      logic       udp_valid, udp_ready;
      logic [7:0] mold_byte;
      logic       mold_valid;

      eth_ingress #(
          .UDP_DST_PORT(UDP_DST_PORT)
      ) u_eth (
          .clk100       (CLK100MHZ),
          .rst          (rst_sync),
          .eth_refclk   (eth_refclk),
          .eth_rxd      (eth_rxd),
          .eth_crs_dv   (eth_crs_dv),
          .eth_txd      (eth_txd),
          .eth_txen     (eth_txen),
          .eth_mdc      (eth_mdc),
          .eth_mdio     (eth_mdio),
          .eth_rstn     (eth_rstn),
          .payload_out  (udp_payload),
          .payload_valid(udp_valid),
          .payload_ready(udp_ready),
          .link_up      (link_up_led)
      );

      moldudp64_rx u_mold (
          .clk               (CLK100MHZ),
          .rst               (rst_sync),
          .udp_payload_in    (udp_payload),
          .udp_payload_valid (udp_valid),
          .udp_payload_ready (udp_ready),
          .itch_byte_out     (mold_byte),
          .itch_byte_valid   (mold_valid),
          .itch_byte_ready   (byte_ready)
      );

      assign byte_in    = mold_byte;
      assign byte_valid = mold_valid;
    end else begin : gen_no_eth
      assign byte_in     = '0;
      assign byte_valid  = 1'b0;
      assign eth_txd     = '0;
      assign eth_txen    = 1'b0;
      assign eth_rstn    = 1'b1;
      assign link_up_led = 1'b0;
    end
  endgenerate

  itch_hw_core u_core (
      .clk            (CLK100MHZ),
      .rst            (rst_sync),
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

  seven_segment_ctrl u_display (
      .clk         (CLK100MHZ),
      .rst         (rst_sync),
      .display_val (bbo_bid_price),
      .ca          (ca),
      .cb          (cb),
      .cc          (cc),
      .cd          (cd),
      .ce          (ce),
      .cf          (cf),
      .cg          (cg),
      .an          (an)
  );

  always_ff @(posedge CLK100MHZ) begin
    if (rst_sync) begin
      pulse_stretch <= '0;
      bbo_stretch   <= '0;
    end else begin
      if (record_valid) pulse_stretch <= 24'hFF_FFFF;
      else if (|pulse_stretch) pulse_stretch <= pulse_stretch - 24'd1;
      if (bbo_valid) bbo_stretch <= 24'hFF_FFFF;
      else if (|bbo_stretch) bbo_stretch <= bbo_stretch - 24'd1;
    end
  end

  assign LED[0]  = |pulse_stretch;
  assign LED[1]  = |bbo_stretch;
  assign LED[2]  = parse_error;
  assign LED[3]  = book_error;
  assign LED[14:4] = bbo_bid_price[10:0];
  assign LED[15]   = link_up_led;

endmodule
