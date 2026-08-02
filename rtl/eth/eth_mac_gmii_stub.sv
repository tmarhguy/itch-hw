// GMII byte source stub — replace with Xilinx TEMAC/RGMII IP via vivado/create_eth_ip.tcl.
`timescale 1ns / 1ps

module eth_mac_gmii_stub (
    input  logic        clk125,
    input  logic        rst,
    output logic [ 7:0] gmii_txd,
    output logic        gmii_tx_en,
    input  logic [ 7:0] gmii_rxd,
    input  logic        gmii_rx_dv,
    output logic        link_up
);

  assign gmii_txd  = '0;
  assign gmii_tx_en = 1'b0;
  assign link_up   = gmii_rx_dv;

endmodule
