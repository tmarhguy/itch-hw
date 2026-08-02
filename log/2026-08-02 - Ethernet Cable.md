# Ethernet cable — lab bring-up

**Date:** 2026-08-02

## Context

In my understanding of ITCH, market data should flow continuously into the system so the FPGA can act on it. The end-to-end path matters: **data in → decision → data out**, without shortcuts that skip real ingress.

## Update

Ordered an Ethernet cable for the Nexys A7; it arrived and is ready for testing.

## Goal

Exercise the full workflow on hardware:

1. **Data in** — live UDP / Mold-wrapped ITCH over the RJ45 link
2. **Decision** — parse messages, maintain the order book, update BBO
3. **Data out** — visible feedback on the board (LEDs, 7-segment) as proof the pipeline ran

Next step: build with `USE_ETH=1`, program the board, and send test traffic with `tools/send_itch_udp.py` (see `docs/board_eth_setup.md`).
