// Dual-clock byte FIFO (gray-pointer, BRAM-backed).
`timescale 1ns / 1ps

module byte_cdc_fifo #(
    parameter int DEPTH = 512,
    parameter int ADDR_W = 9
) (
    input  logic       wr_clk,
    input  logic       rd_clk,
    input  logic       rst,
    input  logic [7:0] wr_data,
    input  logic       wr_en,
    output logic       wr_full,
    output logic [7:0] rd_data,
    input  logic       rd_en,
    output logic       rd_empty
);

  logic [ADDR_W:0] wr_ptr, rd_ptr;
  logic [ADDR_W:0] wr_ptr_gray, rd_ptr_gray;
  logic [ADDR_W:0] wr_ptr_gray_rd, rd_ptr_gray_wr;

  (* ram_style = "block" *) logic [7:0] mem[DEPTH];

  function automatic logic [ADDR_W:0] bin2gray(input logic [ADDR_W:0] b);
    bin2gray = (b >> 1) ^ b;
  endfunction

  assign wr_full  = bin2gray(wr_ptr + 1) == rd_ptr_gray_wr;
  assign rd_empty = wr_ptr_gray_rd == rd_ptr_gray;

  always_ff @(posedge wr_clk) begin
    if (rst) begin
      wr_ptr      <= '0;
      wr_ptr_gray <= '0;
    end else if (wr_en && !wr_full) begin
      mem[wr_ptr[ADDR_W-1:0]] <= wr_data;
      wr_ptr      <= wr_ptr + 1;
      wr_ptr_gray <= bin2gray(wr_ptr + 1);
    end
  end

  always_ff @(posedge rd_clk) begin
    if (rst) begin
      rd_ptr      <= '0;
      rd_ptr_gray <= '0;
    end else if (rd_en && !rd_empty) begin
      rd_ptr      <= rd_ptr + 1;
      rd_ptr_gray <= bin2gray(rd_ptr + 1);
    end
  end

  always_comb begin
    rd_data = mem[rd_ptr[ADDR_W-1:0]];
  end

  always_ff @(posedge wr_clk) rd_ptr_gray_wr <= rd_ptr_gray;

  always_ff @(posedge rd_clk) wr_ptr_gray_rd <= wr_ptr_gray;

endmodule
