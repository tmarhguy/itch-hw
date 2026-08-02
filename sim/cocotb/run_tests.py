"""Run cocotb tests without GNU make (Windows-friendly)."""

import os
import subprocess
import sys
from pathlib import Path

from cocotb_tools.runner import get_runner


def _prime_oss_cad_path() -> None:
    if sys.platform != "win32":
        return
    oss_bin = Path(r"C:\Tools\oss-cad-suite\bin")
    if oss_bin.is_dir():
        os.environ["PATH"] = str(oss_bin) + os.pathsep + os.environ.get("PATH", "")


def main() -> None:
    _prime_oss_cad_path()
    sim = os.environ.get("SIM", "icarus")

    root = Path(__file__).resolve().parents[1]
    rtl = root.parent / "rtl"

    sources = [
        root / "hdl" / "itch_hw_tb.sv",
        rtl / "itch" / "itch_types.sv",
        rtl / "itch" / "itch_byte_fsm.sv",
        rtl / "itch" / "itch_pipeline.sv",
        rtl / "book" / "lut3_price_cmp.sv",
        rtl / "book" / "order_book.sv",
        rtl / "top" / "itch_hw_core.sv",
    ]

    build_args = ["-g2012"] if sim == "icarus" else ["--timing", "-Wno-fatal"]
    runner = get_runner(sim)
    runner.build(
        sources=sources,
        hdl_toplevel="itch_hw_tb",
        always=True,
        build_args=build_args,
        defines={"SYNTHESIS": 0},
    )
    runner.test(hdl_toplevel="itch_hw_tb", test_module="test_itch_hw")


if __name__ == "__main__":
    main()

