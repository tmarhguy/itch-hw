// Clause-22 MDIO read for Nexys A7 LAN8720A (PHY address 1, BMSR link bit).
`timescale 1ns / 1ps

module lan8720_mdio #(
    parameter int PHY_ADDR = 1,
    parameter int CLK_HZ   = 100_000_000,
    parameter int MDC_HZ   = 1_000_000
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        phy_rstn,
    output logic        mdc,
    inout  logic        mdio,
    output logic        link_up
);

  localparam int MDC_DIV   = CLK_HZ / (2 * MDC_HZ);
  localparam int PREAMBLE  = 32;
  localparam int CMD_BITS  = 14;

  typedef enum logic [2:0] {
    StWait,
    StDrive,
    StRead,
    StGap
  } state_e;

  state_e      state_q;
  logic [31:0] mdc_cnt;
  logic        mdc_low;
  logic        mdio_out;
  logic        mdio_drive;
  logic        mdio_in;
  logic [6:0]  bit_idx;
  logic [13:0] cmd_bits;
  logic [15:0] read_data;
  logic [23:0] gap_cnt;
  logic        link_q;

  assign mdio     = mdio_drive ? mdio_out : 1'bz;
  assign mdio_in  = mdio;
  assign link_up  = link_q;
  assign mdc      = mdc_low;

  always_ff @(posedge clk) begin
    if (rst) mdc_cnt <= '0;
    else if (mdc_cnt == MDC_DIV - 1) mdc_cnt <= '0;
    else mdc_cnt <= mdc_cnt + 1;
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      state_q    <= StWait;
      mdc_low    <= 1'b0;
      mdio_out   <= 1'b1;
      mdio_drive <= 1'b1;
      bit_idx    <= '0;
      cmd_bits   <= '0;
      read_data  <= '0;
      gap_cnt    <= '0;
      link_q     <= 1'b0;
    end else if (mdc_cnt == MDC_DIV - 1) begin
      mdc_low <= ~mdc_low;

      if (mdc_low) begin
        unique case (state_q)
          StWait: begin
            if (!phy_rstn) gap_cnt <= '0;
            else if (gap_cnt < 24'd5_000_000) gap_cnt <= gap_cnt + 24'd1;
            else begin
              cmd_bits[13:12] <= 2'b01;
              cmd_bits[11:10] <= 2'b10;
              cmd_bits[9:5]   <= PHY_ADDR[4:0];
              cmd_bits[4:0]   <= 5'd1;
              bit_idx         <= PREAMBLE + CMD_BITS - 1;
              mdio_out        <= 1'b1;
              mdio_drive      <= 1'b1;
              state_q         <= StDrive;
              gap_cnt         <= '0;
            end
          end
          StDrive: begin
            if (bit_idx >= CMD_BITS) mdio_out <= 1'b1;
            else mdio_out <= cmd_bits[bit_idx];

            if (bit_idx == 0) begin
              mdio_drive <= 1'b0;
              bit_idx    <= 15;
              state_q    <= StRead;
            end else bit_idx <= bit_idx - 7'd1;
          end
          StRead: begin
            read_data[bit_idx] <= mdio_in;
            if (bit_idx == 2) link_q <= mdio_in;
            if (bit_idx == 0) begin
              mdio_drive <= 1'b1;
              mdio_out   <= 1'b1;
              state_q    <= StGap;
            end else bit_idx <= bit_idx - 7'd1;
          end
          StGap: begin
            if (gap_cnt < 24'd10_000_000) gap_cnt <= gap_cnt + 24'd1;
            else begin
              gap_cnt <= '0;
              state_q <= StWait;
            end
          end
          default: state_q <= StWait;
        endcase
      end
    end
  end

endmodule
