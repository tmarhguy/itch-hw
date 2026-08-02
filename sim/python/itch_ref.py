"""NASDAQ ITCH 5.0 subset encoders + reference order book (Python)."""

from __future__ import annotations

import struct
from dataclasses import dataclass
from enum import Enum
from typing import List, Tuple


class Side(str, Enum):
    BUY = "B"
    SELL = "S"


def be_u16(v: int) -> bytes:
    return struct.pack(">H", v)


def be_u32(v: int) -> bytes:
    return struct.pack(">I", v)


def be_u48(v: int) -> bytes:
    return v.to_bytes(6, "big")


def be_u64(v: int) -> bytes:
    return struct.pack(">Q", v)


def encode_add(
    stock_locate: int = 1,
    tracking: int = 1,
    ts: int = 0,
    order_ref: int = 1,
    side: Side = Side.BUY,
    shares: int = 100,
    stock: str = "AAPL    ",
    price: int = 10_0000,
) -> bytes:
    stock_b = stock.encode("ascii")[:8].ljust(8, b" ")
    return (
        b"A"
        + be_u16(stock_locate)
        + be_u16(tracking)
        + be_u48(ts)
        + be_u64(order_ref)
        + side.value.encode("ascii")
        + be_u32(shares)
        + stock_b
        + be_u32(price)
    )


def encode_execute(
    stock_locate: int = 1,
    tracking: int = 1,
    ts: int = 0,
    order_ref: int = 1,
    executed_shares: int = 10,
    match_number: int = 1,
) -> bytes:
    return (
        b"E"
        + be_u16(stock_locate)
        + be_u16(tracking)
        + be_u48(ts)
        + be_u64(order_ref)
        + be_u32(executed_shares)
        + be_u64(match_number)
    )


def encode_cancel(
    stock_locate: int = 1,
    tracking: int = 1,
    ts: int = 0,
    order_ref: int = 1,
    canceled_shares: int = 0,
) -> bytes:
    return (
        b"X"
        + be_u16(stock_locate)
        + be_u16(tracking)
        + be_u48(ts)
        + be_u64(order_ref)
        + be_u32(canceled_shares)
    )


@dataclass
class Order:
    order_ref: int
    side: Side
    price: int
    shares: int


class RefOrderBook:
    def __init__(self) -> None:
        self.orders: dict[int, Order] = {}

    def apply_bytes(self, msg: bytes) -> None:
        t = chr(msg[0])
        order_ref = int.from_bytes(msg[11:19], "big")
        if t == "A":
            side = Side.BUY if msg[19:20] == b"B" else Side.SELL
            shares = int.from_bytes(msg[20:24], "big")
            price = int.from_bytes(msg[32:36], "big")
            self.orders[order_ref] = Order(order_ref, side, price, shares)
        elif t == "E":
            ex = int.from_bytes(msg[19:23], "big")
            o = self.orders.get(order_ref)
            if o:
                o.shares -= ex
                if o.shares <= 0:
                    del self.orders[order_ref]
        elif t == "X":
            canceled = int.from_bytes(msg[19:23], "big")
            o = self.orders.get(order_ref)
            if o:
                if canceled == 0 or canceled >= o.shares:
                    del self.orders[order_ref]
                else:
                    o.shares -= canceled

    def bbo(self) -> Tuple[int, int]:
        bids = [o.price for o in self.orders.values() if o.side == Side.BUY]
        asks = [o.price for o in self.orders.values() if o.side == Side.SELL]
        return (max(bids) if bids else 0, min(asks) if asks else 0)


def mold_wrap(itch_messages: List[bytes]) -> bytes:
    out = bytearray()
    for m in itch_messages:
        out += struct.pack(">H", len(m))
        out += m
    return bytes(out)
