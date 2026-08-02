import json
import os
import sys

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "python"))
from itch_ref import RefOrderBook, Side, encode_add, encode_cancel, encode_execute


def core(dut):
    return dut.dut


async def reset_dut(dut):
    c = core(dut)
    dut.rst.value = 1
    c.byte_in.value = 0
    c.byte_valid.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)


async def send_msg(dut, msg: bytes):
    c = core(dut)
    for b in msg:
        while True:
            c.byte_in.value = b
            c.byte_valid.value = 1
            await RisingEdge(dut.clk)
            if int(c.byte_ready.value):
                break
        c.byte_valid.value = 0
        await RisingEdge(dut.clk)


async def wait_bbo(dut, max_cycles=600):
    c = core(dut)
    for _ in range(max_cycles):
        await RisingEdge(dut.clk)
        if int(c.bbo_valid.value):
            return
    raise AssertionError("bbo_valid timeout")


@cocotb.test()
async def test_e2e_latency(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    msg = encode_add(order_ref=5, side=Side.BUY, shares=50, price=12345)
    ref = RefOrderBook()
    ref.apply_bytes(msg)

    last_byte_cycle = None
    record_cycle = None
    bbo_cycle = None
    cycle = 0

    async def monitor():
        nonlocal record_cycle, bbo_cycle, cycle
        while True:
            await RisingEdge(dut.clk)
            cycle += 1
            c = core(dut)
            if int(c.record_valid.value):
                record_cycle = cycle
            if int(c.bbo_valid.value):
                bbo_cycle = cycle

    cocotb.start_soon(monitor())

    for i, b in enumerate(msg):
        if i == len(msg) - 1:
            last_byte_cycle = cycle
        while True:
            c = core(dut)
            c.byte_in.value = b
            c.byte_valid.value = 1
            await RisingEdge(dut.clk)
            cycle += 1
            if int(c.byte_ready.value):
                break
        c.byte_valid.value = 0

    await wait_bbo(dut, max_cycles=30)

    assert record_cycle is not None, "record_valid never asserted"
    parse_cycles = record_cycle - last_byte_cycle
    assert parse_cycles <= 5, f"parse latency {parse_cycles} cycles > 5"

    assert bbo_cycle is not None, "bbo_valid never asserted"
    bbo_cycles = bbo_cycle - record_cycle
    assert bbo_cycles <= 6, f"bbo latency {bbo_cycles} cycles > 6"

    c = core(dut)
    bid = int(c.bbo_bid_price.value)
    assert bid == ref.bbo()[0], f"bid {bid} != ref {ref.bbo()[0]}"

    results = {
        "parse_max_cycles": parse_cycles,
        "bbo_max_cycles": bbo_cycles,
        "parse_max_ns": parse_cycles * 10,
        "bbo_max_ns": bbo_cycles * 10,
    }
    out_dir = os.path.join(os.path.dirname(__file__), "..", "results")
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "latency_summary.json"), "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2)


@cocotb.test()
async def test_stress_replay(dut):
    """Replay synthetic ITCH against Python golden model (resume-scale via STRESS_MSGS)."""
    stress_msgs = int(os.environ.get("STRESS_MSGS", "10000"))
    check_stride = max(1, stress_msgs // 1000)

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    ref = RefOrderBook()
    rng = __import__("random").Random(0)

    for n in range(stress_msgs):
        op = rng.randint(0, 2)
        order_ref = rng.randint(1, 400)
        if op == 0:
            msg = encode_add(
                order_ref=order_ref,
                side=Side.BUY if rng.random() < 0.5 else Side.SELL,
                shares=rng.randint(1, 500),
                price=rng.randint(10_000, 90_000),
                ts=n,
            )
        elif op == 1 and order_ref in ref.orders:
            msg = encode_execute(
                order_ref=order_ref,
                executed_shares=min(rng.randint(1, 50), ref.orders[order_ref].shares),
                ts=n,
            )
        elif order_ref in ref.orders:
            msg = encode_cancel(order_ref=order_ref, ts=n)
        else:
            msg = encode_add(
                order_ref=order_ref,
                side=Side.BUY,
                shares=rng.randint(1, 100),
                price=rng.randint(10_000, 90_000),
                ts=n,
            )

        ref.apply_bytes(msg)
        await send_msg(dut, msg)
        await wait_bbo(dut, max_cycles=600)

        if n % check_stride == 0 or n == stress_msgs - 1:
            c = core(dut)
            bid, ask = ref.bbo()
            assert int(c.bbo_bid_price.value) == bid
            assert int(c.bbo_ask_price.value) == ask

    assert not int(core(dut).parse_error.value)
    assert not int(core(dut).book_error.value)


@cocotb.test()
async def test_add_exec_cancel(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    ref = RefOrderBook()
    msgs = [
        encode_add(order_ref=1, side=Side.BUY, shares=100, price=5000),
        encode_add(order_ref=2, side=Side.SELL, shares=80, price=5100),
        encode_execute(order_ref=1, executed_shares=30),
        encode_cancel(order_ref=2, canceled_shares=0),
    ]
    for m in msgs:
        ref.apply_bytes(m)
        await send_msg(dut, m)
        await wait_bbo(dut, max_cycles=600)

    await RisingEdge(dut.clk)
    bid, ask = ref.bbo()
    c = core(dut)
    assert int(c.bbo_bid_price.value) == bid
    assert int(c.bbo_ask_price.value) == ask
