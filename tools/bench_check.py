#!/usr/bin/env python3
"""PC-side checks before / during Nexys Ethernet bench bring-up."""

from __future__ import annotations

import argparse
import socket
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "sim" / "python"))

from itch_ref import Side, encode_add, encode_execute, mold_wrap  # noqa: E402


def check_windows_ip() -> bool:
    try:
        out = subprocess.check_output(["ipconfig"], text=True, errors="replace")
    except OSError as exc:
        print(f"ipconfig failed: {exc}")
        return False

    ok = "192.168.1." in out
    if ok:
        print("OK: found 192.168.1.x on a host adapter (check it is the Nexys link).")
    else:
        print(
            "WARN: no 192.168.1.x address seen. Set the direct-cable adapter to "
            "192.168.1.1 / 255.255.255.0 (see docs/board_eth_setup.md)."
        )
    return ok


def send_burst(repeat: int) -> None:
    msgs = [
        encode_add(order_ref=1, side=Side.BUY, shares=100, price=50_0000),
        encode_add(order_ref=2, side=Side.SELL, shares=50, price=50_1000),
        encode_execute(order_ref=1, executed_shares=25),
    ]
    payload = mold_wrap(msgs)
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    host, port = "255.255.255.255", 50000
    for i in range(repeat):
        sock.sendto(payload, (host, port))
        print(f"[{i + 1}/{repeat}] Sent {len(payload)} bytes to {host}:{port}")


def print_led_guide() -> None:
    print(
        """
On the board after programming (USE_ETH=1 bitstream):
  LED15  ON  = PHY link up (wait ~5 s after cable connect)
  LED0   pulse = ITCH record parsed
  LED1   pulse = BBO updated
  LED2   ON  = parse error
  LED3   ON  = book error
  7-seg       = best bid price from test traffic

Order: confirm LED15 first, then run this script, then watch LED0/LED1/7-seg.
"""
    )


def main() -> None:
    p = argparse.ArgumentParser(description="Bench bring-up helper for itch-hw.")
    p.add_argument("--repeat", type=int, default=3, help="UDP bursts to send")
    p.add_argument("--skip-send", action="store_true")
    args = p.parse_args()

    print("=== itch-hw bench check ===\n")
    check_windows_ip()
    print_led_guide()
    if not args.skip_send:
        print(f"Sending {args.repeat} Mold/ITCH UDP burst(s) to 255.255.255.255:50000 ...")
        send_burst(args.repeat)
        print("Done. Watch LED0 / LED1 on the board.")


if __name__ == "__main__":
    main()
