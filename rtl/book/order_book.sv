// Dual-sided order book: packed BRAM entries + incremental BBO + sequential rescan.
`timescale 1ns / 1ps

import itch_types::*;

module order_book (
    input  logic        clk,
    input  logic        rst,
    input  itch_record_t record,
    input  logic        record_valid,
    output logic [31:0] bbo_bid_price,
    output logic [31:0] bbo_ask_price,
    output logic [31:0] bbo_bid_shares,
    output logic [31:0] bbo_ask_shares,
    output logic        bbo_valid,
    output logic        book_error
);

  localparam int unsigned Slots = OrderSlots;
  localparam int unsigned IdxW  = OrderIdxW;
  // {valid, price[31:0], shares[31:0]}
  localparam int unsigned SlotW = 65;

  (* ram_style = "block" *) logic [SlotW-1:0] bid_mem[Slots];
  (* ram_style = "block" *) logic [SlotW-1:0] ask_mem[Slots];

  logic [IdxW-1:0] raddr;
  logic [SlotW-1:0] bid_rd_word, ask_rd_word;

  logic             bid_we, ask_we;
  logic [IdxW-1:0]  bid_waddr, ask_waddr;
  logic [SlotW-1:0] bid_wdata, ask_wdata;

  logic [31:0] best_bid_p, best_ask_p;
  logic [31:0] best_bid_sh, best_ask_sh;
  logic        best_bid_v, best_ask_v;

  logic        scan_active;
  logic        scan_warm;
  logic [IdxW-1:0] scan_idx;
  logic [31:0] run_bid_p, run_ask_p;
  logic [31:0] run_bid_sh, run_ask_sh;
  logic        run_bid_v, run_ask_v;

  logic        apply_d;
  itch_record_t rec_d;
  logic [IdxW-1:0] idx_d;

  logic        bbo_valid_q;
  logic        book_error_q;

  assign bbo_bid_price  = best_bid_p;
  assign bbo_ask_price  = best_ask_p;
  assign bbo_bid_shares = best_bid_sh;
  assign bbo_ask_shares = best_ask_sh;
  assign bbo_valid      = bbo_valid_q;
  assign book_error     = book_error_q;

  function automatic void unpack_slot(
      input  logic [SlotW-1:0] w,
      output logic             valid,
      output logic [31:0]      price,
      output logic [31:0]      shares
  );
    valid  = w[64];
    price  = w[63:32];
    shares = w[31:0];
  endfunction

  function automatic logic [SlotW-1:0] pack_slot(
      input logic valid, input logic [31:0] price, input logic [31:0] shares
  );
    pack_slot = {valid, price, shares};
  endfunction

  // One process per array: registered read + synchronous write (BRAM-friendly).
  always_ff @(posedge clk) begin
    bid_rd_word <= bid_mem[raddr];
    if (bid_we) bid_mem[bid_waddr] <= bid_wdata;
  end

  always_ff @(posedge clk) begin
    ask_rd_word <= ask_mem[raddr];
    if (ask_we) ask_mem[ask_waddr] <= ask_wdata;
  end

  always_ff @(posedge clk) begin
    bid_we <= 1'b0;
    ask_we <= 1'b0;

    if (rst) begin
      raddr        <= '0;
      best_bid_p   <= '0;
      best_ask_p   <= '0;
      best_bid_sh  <= '0;
      best_ask_sh  <= '0;
      best_bid_v   <= 1'b0;
      best_ask_v   <= 1'b0;
      scan_active  <= 1'b0;
      scan_warm    <= 1'b0;
      scan_idx     <= '0;
      run_bid_p    <= '0;
      run_ask_p    <= '0;
      run_bid_sh   <= '0;
      run_ask_sh   <= '0;
      run_bid_v    <= 1'b0;
      run_ask_v    <= 1'b0;
      apply_d      <= 1'b0;
      rec_d        <= '0;
      idx_d        <= '0;
      bbo_valid_q  <= 1'b0;
      book_error_q <= 1'b0;
    end else begin
      bbo_valid_q  <= 1'b0;
      book_error_q <= 1'b0;
      apply_d      <= 1'b0;

      if (scan_active) begin
        logic bid_v, ask_v;
        logic [31:0] bid_p, ask_p, bid_s, ask_s;

        if (!scan_warm) begin
          unpack_slot(bid_rd_word, bid_v, bid_p, bid_s);
          unpack_slot(ask_rd_word, ask_v, ask_p, ask_s);

          if (bid_v && (!run_bid_v || bid_p > run_bid_p)) begin
            run_bid_p  <= bid_p;
            run_bid_sh <= bid_s;
            run_bid_v  <= 1'b1;
          end
          if (ask_v && (!run_ask_v || ask_p < run_ask_p)) begin
            run_ask_p  <= ask_p;
            run_ask_sh <= ask_s;
            run_ask_v  <= 1'b1;
          end

          if (scan_idx == (Slots - 1)) begin
            logic [31:0] fb, fa, fbs, fas;
            logic        fvb, fva;
            fb  = run_bid_p;
            fbs = run_bid_sh;
            fvb = run_bid_v;
            fa  = run_ask_p;
            fas = run_ask_sh;
            fva = run_ask_v;
            if (bid_v && (!fvb || bid_p > fb)) begin
              fb  = bid_p;
              fbs = bid_s;
              fvb = 1'b1;
            end
            if (ask_v && (!fva || ask_p < fa)) begin
              fa  = ask_p;
              fas = ask_s;
              fva = 1'b1;
            end
            scan_active <= 1'b0;
            best_bid_p  <= fvb ? fb : '0;
            best_bid_sh <= fvb ? fbs : '0;
            best_bid_v  <= fvb;
            best_ask_p  <= fva ? fa : '0;
            best_ask_sh <= fva ? fas : '0;
            best_ask_v  <= fva;
            bbo_valid_q <= 1'b1;
          end else begin
            scan_idx <= scan_idx + 1'b1;
            raddr    <= scan_idx + 1'b1;
          end
        end else begin
          scan_warm <= 1'b0;
        end
      end else if (apply_d) begin
        logic        bid_v, ask_v;
        logic [31:0] bid_p, bid_s, ask_p, ask_s;
        logic        rescan;
        logic        n_bid_v, n_ask_v;
        logic [31:0] n_bid_p, n_bid_s, n_ask_p, n_ask_s;

        unpack_slot(bid_rd_word, bid_v, bid_p, bid_s);
        unpack_slot(ask_rd_word, ask_v, ask_p, ask_s);
        rescan = 1'b0;

        unique case (rec_d.msg)
          MsgAdd: begin
            if (rec_d.side == SideBuy) begin
              bid_we    <= 1'b1;
              bid_waddr <= idx_d;
              bid_wdata <= pack_slot(1'b1, rec_d.price, rec_d.shares);
              if (!best_bid_v || rec_d.price > best_bid_p) begin
                best_bid_p  <= rec_d.price;
                best_bid_sh <= rec_d.shares;
                best_bid_v  <= 1'b1;
              end
            end else begin
              ask_we    <= 1'b1;
              ask_waddr <= idx_d;
              ask_wdata <= pack_slot(1'b1, rec_d.price, rec_d.shares);
              if (!best_ask_v || rec_d.price < best_ask_p) begin
                best_ask_p  <= rec_d.price;
                best_ask_sh <= rec_d.shares;
                best_ask_v  <= 1'b1;
              end
            end
            bbo_valid_q <= 1'b1;
          end

          MsgExec: begin
            if (bid_v) begin
              n_bid_v = bid_v;
              n_bid_p = bid_p;
              n_bid_s = bid_s;
              if (rec_d.aux_shares >= n_bid_s) n_bid_v = 1'b0;
              else n_bid_s = n_bid_s - rec_d.aux_shares;
              bid_we    <= 1'b1;
              bid_waddr <= idx_d;
              bid_wdata <= pack_slot(n_bid_v, n_bid_p, n_bid_s);
              if (bid_p == best_bid_p) rescan = 1'b1;
            end else if (ask_v) begin
              n_ask_v = ask_v;
              n_ask_p = ask_p;
              n_ask_s = ask_s;
              if (rec_d.aux_shares >= n_ask_s) n_ask_v = 1'b0;
              else n_ask_s = n_ask_s - rec_d.aux_shares;
              ask_we    <= 1'b1;
              ask_waddr <= idx_d;
              ask_wdata <= pack_slot(n_ask_v, n_ask_p, n_ask_s);
              if (ask_p == best_ask_p) rescan = 1'b1;
            end else begin
              book_error_q <= 1'b1;
            end
          end

          MsgCancel: begin
            if (bid_v) begin
              n_bid_v = bid_v;
              n_bid_p = bid_p;
              n_bid_s = bid_s;
              if (rec_d.aux_shares == 0 || rec_d.aux_shares >= n_bid_s) n_bid_v = 1'b0;
              else n_bid_s = n_bid_s - rec_d.aux_shares;
              bid_we    <= 1'b1;
              bid_waddr <= idx_d;
              bid_wdata <= pack_slot(n_bid_v, n_bid_p, n_bid_s);
              if (bid_p == best_bid_p) rescan = 1'b1;
            end else if (ask_v) begin
              n_ask_v = ask_v;
              n_ask_p = ask_p;
              n_ask_s = ask_s;
              if (rec_d.aux_shares == 0 || rec_d.aux_shares >= n_ask_s) n_ask_v = 1'b0;
              else n_ask_s = n_ask_s - rec_d.aux_shares;
              ask_we    <= 1'b1;
              ask_waddr <= idx_d;
              ask_wdata <= pack_slot(n_ask_v, n_ask_p, n_ask_s);
              if (ask_p == best_ask_p) rescan = 1'b1;
            end else begin
              book_error_q <= 1'b1;
            end
          end

          default: book_error_q <= 1'b1;
        endcase

        if (rescan) begin
          scan_active <= 1'b1;
          scan_warm   <= 1'b1;
          scan_idx    <= '0;
          raddr       <= '0;
          run_bid_p   <= '0;
          run_ask_p   <= '0;
          run_bid_sh  <= '0;
          run_ask_sh  <= '0;
          run_bid_v   <= 1'b0;
          run_ask_v   <= 1'b0;
        end else if (rec_d.msg != MsgAdd) begin
          bbo_valid_q <= 1'b1;
        end
      end else if (record_valid) begin
        rec_d   <= record;
        idx_d   <= record.order_ref[IdxW-1:0];
        raddr   <= record.order_ref[IdxW-1:0];
        apply_d <= 1'b1;
      end
    end
  end

endmodule
