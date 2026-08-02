# Architecture

![ITCH 5.0](https://img.shields.io/badge/NASDAQ_ITCH-5.0-7C3AED?style=for-the-badge)
![RMII](https://img.shields.io/badge/Ingress-RMII_UDP-2ea043?style=for-the-badge)
![100 MHz](https://img.shields.io/badge/Core-100_MHz-2563EB?style=for-the-badge)
![512 slots](https://img.shields.io/badge/Order_book-512_slots-DC2626?style=for-the-badge)

RMII → UDP → Mold → ITCH → order book → LEDs / 7-seg. No host in the hot path.  
← [README](../README.md) · [metrics](metrics.md) · [board setup](board_eth_setup.md)

---

## Contents

- [Hierarchy](#hierarchy)
- [Behavior](#behavior)
- [Scope](#scope)

---

## Hierarchy

Top: [`nexys_a7_100t_top.sv`](../rtl/top/nexys_a7_100t_top.sv) · `USE_ETH=1` · UDP port **50000**

```
  eth_ingress → moldudp64_rx → itch_hw_core → seven_segment_ctrl
                  (Mold)         (parse + book)      (best bid)
```

<p align="center">
  <img src="../media/impl_design_diagram.png" alt="Implemented design hierarchy" width="560" />
</p>

| Block | Module | Notes |
|-------|--------|-------|
| Ingress | [`eth_ingress`](../rtl/eth/eth_ingress.sv) | RMII @ 50 MHz → CDC → [`udp_rx_minimal`](../rtl/eth/udp_rx_minimal.sv) @ 100 MHz; RX only |
| PHY link | [`lan8720_mdio`](../rtl/eth/lan8720_mdio.sv) | MDIO poll → **LED15** |
| Unwrap | [`moldudp64_rx`](../rtl/mold/moldudp64_rx.sv) | Mold length-prefix → ITCH bytes |
| Core | [`itch_hw_core`](../rtl/top/itch_hw_core.sv) | [`itch_byte_fsm`](../rtl/itch/itch_byte_fsm.sv) + [`order_book`](../rtl/book/order_book.sv) |
| Display | [`seven_segment_ctrl`](../rtl/display/seven_segment_ctrl.sv) | Best bid on 7-seg |

Types: [`itch_types.sv`](../rtl/itch/itch_types.sv). Cocotb tests stop at `itch_hw_core` (no PHY in sim).

---

## Behavior

**Parser** — streaming 8-bit FSM; Add (`A`), Execute (`E`), Cancel (`X`) → `itch_record_t` on `record_valid`.

**Book** — dual 512-slot BRAM (bid/ask), keyed by `order_ref[8:0]`. Incremental BBO on Add; sequential rescan (≤512 cycles) after Exec/Cancel at the current best. Price compare via [`lut3_price_cmp`](../rtl/book/lut3_price_cmp.sv) (LUT3 primitives, Tomato-style truth tables).

**Clocks** — 100 MHz system + 50 MHz `eth_refclk`; async groups in [`nexys_a7_100t.xdc`](../constraints/nexys_a7_100t.xdc).

**LEDs** — see [board_eth_setup.md](board_eth_setup.md) (LED15 link, LED0 parse, LED1 BBO, LED2/3 errors).

---

## Scope

| | v1 |
|---|---|
| Feed | Lab UDP / `send_itch_udp.py`, not production multicast |
| Ethernet | No ARP or TX — use broadcast from host |
| Book | Single symbol; A / E / X only |

---

*Numbers: [metrics.md](metrics.md). Build: [log](../log/2026-08-02%20-%20Successful%20Synthesis%20-%20Implementation%20-%20Bitstream.md).*
