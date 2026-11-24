"""Cocotb golden-model verification suite for jam_digital_top."""

import os
from pathlib import Path
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer

SEVEN_SEG_MAP = {
    0: 0b0111111,
    1: 0b0000110,
    2: 0b1011011,
    3: 0b1001111,
    4: 0b1100110,
    5: 0b1101101,
    6: 0b1111101,
    7: 0b0000111,
    8: 0b1111111,
    9: 0b1101111,
}


def read_time(dut):
    hour = int(dut.hour_tens_o.value) * 10 + int(dut.hour_ones_o.value)
    minute = int(dut.min_tens_o.value) * 10 + int(dut.min_ones_o.value)
    sec = int(dut.sec_tens_o.value) * 10 + int(dut.sec_ones_o.value)
    return hour, minute, sec


async def reset_dut(dut):
    dut.rst_n.value = 0
    dut.en_i.value = 0
    dut.fast_mode_i.value = 0
    dut.load_en_i.value = 0
    dut.inc_sec_i.value = 0
    dut.inc_min_i.value = 0
    dut.inc_hour_i.value = 0
    dut.load_hour_tens_i.value = 0
    dut.load_hour_ones_i.value = 0
    dut.load_min_tens_i.value = 0
    dut.load_min_ones_i.value = 0
    dut.load_sec_tens_i.value = 0
    dut.load_sec_ones_i.value = 0
    await Timer(35, unit="ns")
    await FallingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)


async def sync_load(dut, hour, minute, sec):
    await FallingEdge(dut.clk)
    dut.load_hour_tens_i.value = hour // 10
    dut.load_hour_ones_i.value = hour % 10
    dut.load_min_tens_i.value = minute // 10
    dut.load_min_ones_i.value = minute % 10
    dut.load_sec_tens_i.value = sec // 10
    dut.load_sec_ones_i.value = sec % 10
    dut.load_en_i.value = 1
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.load_en_i.value = 0


@cocotb.test()
async def test_reset_and_rollovers(dut):
    """Verify reset, all critical rollovers, and AM/PM toggle against Python model."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    await reset_dut(dut)

    assert read_time(dut) == (0, 0, 0)
    assert int(dut.am_pm_o.value) == 0
    assert int(dut.rollover_pulse_o.value) == 0

    dut.fast_mode_i.value = 1
    dut.en_i.value = 1

    boundaries = [
        ((0, 0, 59), (0, 1, 0), 0, 0),
        ((0, 59, 59), (1, 0, 0), 0, 0),
        ((9, 59, 59), (10, 0, 0), 0, 0),
        ((10, 59, 59), (11, 0, 0), 0, 0),
        ((11, 59, 59), (0, 0, 0), 1, 1),
    ]

    for start_t, exp_t, exp_am_pm, exp_roll in boundaries:
        await sync_load(dut, *start_t)
        await RisingEdge(dut.clk)  # primes tick_1hz
        await RisingEdge(dut.clk)  # increments counter
        await FallingEdge(dut.clk)
        assert read_time(dut) == exp_t, f"Boundary {start_t} -> got {read_time(dut)}, exp {exp_t}"
        assert int(dut.am_pm_o.value) == exp_am_pm
        assert int(dut.rollover_pulse_o.value) == exp_roll


@cocotb.test()
async def test_clamping_and_manual_sync(dut):
    """Verify illegal BCD clamping and 3-cycle synchronized manual increments."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    await reset_dut(dut)

    # Illegal BCD load: 19:79:99 -> clamped to 11:59:59
    await FallingEdge(dut.clk)
    dut.load_hour_tens_i.value = 1
    dut.load_hour_ones_i.value = 9
    dut.load_min_tens_i.value = 7
    dut.load_min_ones_i.value = 9
    dut.load_sec_tens_i.value = 9
    dut.load_sec_ones_i.value = 9
    dut.load_en_i.value = 1
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.load_en_i.value = 0
    assert read_time(dut) == (11, 59, 59)

    # Manual increment sec wraps 59 -> 00 without carry
    dut.inc_sec_i.value = 1
    for _ in range(3):
        await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    assert read_time(dut) == (11, 59, 0)
    dut.inc_sec_i.value = 0

    # Manual increment hour wraps 11 -> 00 and toggles am_pm
    dut.inc_hour_i.value = 1
    for _ in range(3):
        await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    assert read_time(dut) == (0, 59, 0)
    assert int(dut.am_pm_o.value) == 1
    assert int(dut.rollover_pulse_o.value) == 1


@cocotb.test()
async def test_seven_segment_mux(dut):
    """Verify all 6 multiplexed digits output correct active-high 7-seg patterns."""
    cocotb.start_soon(Clock(dut.clk, 20, unit="ns").start())
    await reset_dut(dut)
    await sync_load(dut, 10, 45, 29)  # digits: 9,2,5,4,0,1

    dut.fast_mode_i.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    expected_by_sel = {
        0b000001: SEVEN_SEG_MAP[9],
        0b000010: SEVEN_SEG_MAP[2],
        0b000100: SEVEN_SEG_MAP[5],
        0b001000: SEVEN_SEG_MAP[4],
        0b010000: SEVEN_SEG_MAP[0],
        0b100000: SEVEN_SEG_MAP[1],
    }

    seen = set()
    for _ in range(12):
        await FallingEdge(dut.clk)
        sel = int(dut.digit_sel_o.value)
        seg = int(dut.seg_o.value)
        assert sel in expected_by_sel, f"Unexpected digit_sel_o: {bin(sel)}"
        assert seg == expected_by_sel[sel], f"Seg mismatch for sel {bin(sel)}: got {bin(seg)}, exp {bin(expected_by_sel[sel])}"
        seen.add(sel)

    assert len(seen) == 6, f"Expected all 6 digits scanned, saw {seen}"


def run_cocotb_suite():
    from cocotb_tools.runner import get_runner

    proj_dir = Path("/home/yokemikal/eda/designs/projects/Jam_Digital")
    rtl_sources = [
        proj_dir / "rtl/clock_divider.v",
        proj_dir / "rtl/edge_pulse_sync.v",
        proj_dir / "rtl/bcd_mod60_counter.v",
        proj_dir / "rtl/bcd_mod12_counter.v",
        proj_dir / "rtl/bcd_to_7seg.v",
        proj_dir / "rtl/seven_seg_mux6.v",
        proj_dir / "rtl/jam_digital_top.v",
    ]
    runner = get_runner("icarus")
    runner.build(
        sources=rtl_sources,
        hdl_toplevel="jam_digital_top",
        build_dir=str(proj_dir / "sim/results/cocotb_build"),
        parameters={"CLK_FREQ_HZ": 10, "SCAN_DIV": 2},
        timescale=("1ns", "1ps"),
        always=True,
    )
    runner.test(
        hdl_toplevel="jam_digital_top",
        test_module="test_jam_digital_cocotb",
        test_dir=str(proj_dir / "tb"),
        results_xml=str(proj_dir / "sim/results/cocotb_results.xml"),
    )


if __name__ == "__main__":
    run_cocotb_suite()
