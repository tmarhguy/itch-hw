// Top-level Nexys A7-100T wrapper for itch-hw.
`timescale 1ns / 1ps

module nexys_a7_100t_top (
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
    output logic [15:0] LED
);

  logic        rst_sync;
  logic [ 1:0] rst_pipe;

  logic [31:0] stock_price_hex;
  logic        msg_valid;
  logic        error_flag;

  logic [23:0] msg_valid_stretch;

  // Synchronize board reset into the 100 MHz domain (active-high).
  always_ff @(posedge CLK100MHZ) begin
    rst_pipe <= {rst_pipe[0], rst};
    rst_sync <= rst_pipe[1];
  end

  itch_parser u_itch_parser (
      .clk             (CLK100MHZ),
      .rst             (rst_sync),
      .stock_price_hex (stock_price_hex),
      .msg_valid       (msg_valid),
      .error_flag      (error_flag)
  );

  seven_segment_ctrl u_display (
      .clk         (CLK100MHZ),
      .rst         (rst_sync),
      .display_val (stock_price_hex),
      .ca          (ca),
      .cb          (cb),
      .cc          (cc),
      .cd          (cd),
      .ce          (ce),
      .cf          (cf),
      .cg          (cg),
      .an          (an)
  );

  // Stretch msg_valid so activity is visible on LED[0].
  always_ff @(posedge CLK100MHZ) begin
    if (rst_sync) begin
      msg_valid_stretch <= '0;
    end else if (msg_valid) begin
      msg_valid_stretch <= 24'hFF_FFFF;
    end else if (|msg_valid_stretch) begin
      msg_valid_stretch <= msg_valid_stretch - 24'd1;
    end
  end

  assign LED[0]  = |msg_valid_stretch;
  assign LED[1]  = error_flag;
  assign LED[15:2] = stock_price_hex[13:0];

endmodule
