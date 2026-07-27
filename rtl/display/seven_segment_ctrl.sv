// Multiplexed 8-digit hex display driver for Nexys A7 (active-low segments and anodes).
`timescale 1ns / 1ps

module seven_segment_ctrl (
    input  logic        clk,
    input  logic        rst,
    input  logic [31:0] display_val,
    output logic        ca,
    output logic        cb,
    output logic        cc,
    output logic        cd,
    output logic        ce,
    output logic        cf,
    output logic        cg,
    output logic [ 7:0] an
);

  localparam int REFRESH_DIV = 100_000; // 100 MHz / 100k = 1 kHz digit advance

  logic [16:0] refresh_cnt;
  logic [ 2:0] digit_sel;
  logic [ 3:0] hex_digit;
  logic [ 6:0] seg_code;

  always_ff @(posedge clk) begin
    if (rst) begin
      refresh_cnt <= '0;
      digit_sel   <= '0;
    end else if (refresh_cnt == REFRESH_DIV - 1) begin
      refresh_cnt <= '0;
      digit_sel   <= digit_sel + 3'd1;
    end else begin
      refresh_cnt <= refresh_cnt + 17'd1;
    end
  end

  always_comb begin
    unique case (digit_sel)
      3'd0: hex_digit = display_val[ 3: 0];
      3'd1: hex_digit = display_val[ 7: 4];
      3'd2: hex_digit = display_val[11: 8];
      3'd3: hex_digit = display_val[15:12];
      3'd4: hex_digit = display_val[19:16];
      3'd5: hex_digit = display_val[23:20];
      3'd6: hex_digit = display_val[27:24];
      default: hex_digit = display_val[31:28];
    endcase
  end

  // Active-low segment patterns {cg, cf, ce, cd, cc, cb, ca}
  always_comb begin
    unique case (hex_digit)
      4'h0: seg_code = 7'b1000000;
      4'h1: seg_code = 7'b1111001;
      4'h2: seg_code = 7'b0100100;
      4'h3: seg_code = 7'b0110000;
      4'h4: seg_code = 7'b0011001;
      4'h5: seg_code = 7'b0010010;
      4'h6: seg_code = 7'b0000010;
      4'h7: seg_code = 7'b1111000;
      4'h8: seg_code = 7'b0000000;
      4'h9: seg_code = 7'b0010000;
      4'ha: seg_code = 7'b0001000;
      4'hb: seg_code = 7'b0000011;
      4'hc: seg_code = 7'b1000110;
      4'hd: seg_code = 7'b0100001;
      4'he: seg_code = 7'b0000110;
      default: seg_code = 7'b0001110; // F
    endcase
  end

  assign {cg, cf, ce, cd, cc, cb, ca} = seg_code;

  always_comb begin
    an = 8'hFF;
    an[digit_sel] = 1'b0;
  end

endmodule
