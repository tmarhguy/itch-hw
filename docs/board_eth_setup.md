# Board Ethernet setup

![Nexys A7](https://img.shields.io/badge/Nexys_A7-100T-2563EB?style=for-the-badge)
![Direct cable](https://img.shields.io/badge/Link-PC_direct-2ea043?style=for-the-badge)
![UDP 50000](https://img.shields.io/badge/UDP-port_50000-2563EB?style=for-the-badge)
![Broadcast](https://img.shields.io/badge/Host-broadcast-7C3AED?style=for-the-badge)

Cat5e/Cat6 **PC ↔ Nexys** (no switch; LAN8720 auto-MDIX). FPGA is **RX only** — no ARP, so the host sends **UDP broadcast**.  
← [README](../README.md) · [architecture](architecture.md) · [metrics](metrics.md)

---

## Contents

- [Quick start](#quick-start)
- [LEDs](#leds)
- [Troubleshooting](#troubleshooting)

---

## Quick start

**1. Program** — `USE_ETH=1` bitstream from `vivado/build.tcl` → Hardware Manager.

**2. PC network** (adapter on the Nexys cable):

| Setting | Value |
|---------|-------|
| IP | `192.168.1.1` |
| Mask | `255.255.255.0` |
| Gateway | *(empty)* |

Ignore “no internet” — point-to-point link only.

**3. Cable & link** — RJ45 to board, power on, wait ~5 s. **LED15** = link up.

**4. Send traffic**

```text
pip install -r sim/requirements.txt
python tools/bench_check.py
```

Or: `python tools/send_itch_udp.py --repeat 10` (broadcast `255.255.255.255:50000`).

**5. Confirm** — **LED0** parse pulse, **LED1** BBO pulse, 7-seg shows best bid from test adds (price `500000` in script).

---

## LEDs

| LED | Meaning |
|-----|---------|
| **15** | PHY link up |
| **0** | ITCH message parsed (`record_valid`) |
| **1** | BBO updated (`bbo_valid`) |
| **2** | Parse error |
| **3** | Book error |
| **7-seg** | Best bid price |

Order: **LED15** first, then send, then **LED0** / **LED1**.

---

## Troubleshooting

| Symptom | Try |
|---------|-----|
| LED15 off | Reseat cable; enable adapter; use RJ45 not USB |
| LED15 on, no LED0 | Broadcast send; `--port 50000` |
| Wrong 7-seg | Center **reset**, send again |
| Synth missing `lan8720_mdio` | `vivado -mode batch -source vivado/add_sources.tcl` then rebuild |

---

*Lab replay only — not production MoldUDP64 multicast. Full architecture: [architecture.md](architecture.md).*
