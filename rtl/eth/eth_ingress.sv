// Nexys A7 Ethernet ingress: RMII RX + CDC + UDP payload filter @ 100 MHz.
`timescale 1ns / 1ps

module eth_ingress #(
    parameter int UDP_DST_PORT = 50000
) (
    input  logic        clk100,
    input  logic        rst,
    input  logic        eth_refclk,
    input  logic [ 1:0] eth_rxd,
    input  logic        eth_crs_dv,
    output logic [ 1:0] eth_txd,
    output logic        eth_txen,
    inout  logic        eth_mdc,
    inout  logic        eth_mdio,
    output logic        eth_rstn,
    output logic [ 7:0] payload_out,
    output logic        payload_valid,
    input  logic        payload_ready,
    output logic        link_up
);

  logic [7:0] rx_byte;
  logic       rx_valid;
  logic [1:0] rmii_phase;

  logic [7:0] fifo_rd;
  logic       fifo_empty, fifo_rd_en;
  logic [7:0] mac_byte;
  logic       mac_valid;
  logic       frame_end_rmii;
  logic       crs_dv_d;

  logic       frame_toggle_rmii;
  logic [2:0] frame_toggle_sync;
  logic       frame_toggle_d;
  logic       frame_end;

  assign eth_txd   = '0;
  assign eth_txen  = 1'b0;
  assign eth_rstn  = ~rst;

  lan8720_mdio u_mdio (
      .clk      (clk100),
      .rst      (rst),
      .phy_rstn (eth_rstn),
      .mdc      (eth_mdc),
      .mdio     (eth_mdio),
      .link_up  (link_up)
  );

  always_ff @(posedge eth_refclk) begin
    if (rst) begin
      rmii_phase        <= 2'd0;
      rx_valid          <= 1'b0;
      rx_byte           <= '0;
      crs_dv_d          <= 1'b0;
      frame_toggle_rmii <= 1'b0;
    end else begin
      rx_valid <= 1'b0;
      crs_dv_d <= eth_crs_dv;

      if (crs_dv_d && !eth_crs_dv) frame_toggle_rmii <= ~frame_toggle_rmii;

      if (eth_crs_dv) begin
        unique case (rmii_phase)
          2'd0: rx_byte[1:0] <= eth_rxd;
          2'd1: rx_byte[3:2] <= eth_rxd;
          2'd2: rx_byte[5:4] <= eth_rxd;
          2'd3: begin
            rx_byte[7:6] <= eth_rxd;
            rx_valid     <= 1'b1;
          end
        endcase
        rmii_phase <= rmii_phase + 2'd1;
      end else begin
        rmii_phase <= 2'd0;
      end
    end
  end

  always_ff @(posedge clk100) begin
    frame_toggle_sync <= {frame_toggle_sync[1:0], frame_toggle_rmii};
    frame_toggle_d    <= frame_toggle_sync[2];
    frame_end         <= frame_toggle_sync[2] ^ frame_toggle_d;
  end

  byte_cdc_fifo u_cdc (
      .wr_clk   (eth_refclk),
      .rd_clk   (clk100),
      .rst      (rst),
      .wr_data  (rx_byte),
      .wr_en    (rx_valid),
      .wr_full  (),
      .rd_data  (fifo_rd),
      .rd_en    (fifo_rd_en),
      .rd_empty (fifo_empty)
  );

  assign fifo_rd_en = !fifo_empty;
  assign mac_byte   = fifo_rd;
  assign mac_valid  = fifo_rd_en;

  udp_rx_minimal #(
      .DST_PORT(UDP_DST_PORT)
  ) u_udp (
      .clk            (clk100),
      .rst            (rst),
      .frame_end      (frame_end),
      .mac_byte_in    (mac_byte),
      .mac_byte_valid (mac_valid),
      .mac_byte_ready (),
      .payload_out    (payload_out),
      .payload_valid  (payload_valid),
      .payload_ready  (payload_ready)
  );

endmodule
