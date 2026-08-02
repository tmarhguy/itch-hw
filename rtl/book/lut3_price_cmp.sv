// LUT3-based 32-bit unsigned compare (Tomato-style); behavioral in sim, LUT3 in synth.
`timescale 1ns / 1ps

module lut3_price_cmp (
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic        a_gt_b,
    output logic        a_lt_b,
    output logic        a_eq_b
);

`ifdef SYNTHESIS
  logic gt, lt, eq;
  logic [31:0] a_r, b_r;
  logic ai, bi, eqin, gt_out, lt_out;

  assign a_r = a;
  assign b_r = b;

  always_comb begin
    gt = 1'b0;
    lt = 1'b0;
    eq = 1'b1;
    for (int i = 31; i >= 0; i--) begin
      if (eq) begin
        if (a_r[i] > b_r[i]) begin
          gt = 1'b1;
          lt = 1'b0;
          eq = 1'b0;
        end else if (a_r[i] < b_r[i]) begin
          gt = 1'b0;
          lt = 1'b1;
          eq = 1'b0;
        end
      end
    end
  end

  assign ai   = a_r[31];
  assign bi   = b_r[31];
  assign eqin = 1'b1;
  LUT3 #(
      .INIT(8'b100_101_110)
  ) u_gt_top (
      .I0(ai),
      .I1(bi),
      .I2(eqin),
      .O (gt_out)
  );
  LUT3 #(
      .INIT(8'b011_010_001)
  ) u_lt_top (
      .I0(ai),
      .I1(bi),
      .I2(eqin),
      .O (lt_out)
  );

  assign a_gt_b = gt | gt_out;
  assign a_lt_b = lt | lt_out;
  assign a_eq_b = eq & (a_r == b_r);
`else
  assign a_gt_b = a > b;
  assign a_lt_b = a < b;
  assign a_eq_b = a == b;
`endif

endmodule
