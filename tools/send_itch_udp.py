#!/usr/bin/env python3
"""Send Mold-wrapped ITCH test messages over UDP to the Nexys lab port."""

from __future__ import annotations

import argparse
import socket
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "sim" / "python"))

from itch_ref import Side, encode_add, encode_execute, mold_wrap  # noqa: E402


def main() -> None:
    p = argparse.ArgumentParser(
        description="Send Mold/ITCH UDP payloads to the Nexys board (port 50000)."
    )
    p.add_argument(
        "--host",
        default="255.255.255.255",
        help="Destination IP (default broadcast for direct cable; no ARP needed)",
    )
    p.add_argument("--port", type=int, default=50000)
    p.add_argument(
        "--repeat",
        type=int,
        default=1,
        help="Send the test burst N times",
    )
    args = p.parse_args()

    msgs = [
        encode_add(order_ref=1, side=Side.BUY, shares=100, price=50_0000),
        encode_add(order_ref=2, side=Side.SELL, shares=50, price=50_1000),
        encode_execute(order_ref=1, executed_shares=25),
    ]
    payload = mold_wrap(msgs)

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)

    for i in range(args.repeat):
        sock.sendto(payload, (args.host, args.port))
        print(f"[{i + 1}/{args.repeat}] Sent {len(payload)} bytes to {args.host}:{args.port}")

    if args.host == "255.255.255.255":
        print("Tip: broadcast avoids ARP when the board does not reply to 192.168.1.10.")


if __name__ == "__main__":
    main()
