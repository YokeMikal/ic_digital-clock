# Yosys Synthesis Report: `jam_digital_top`

## Configuration
| Field | Value |
| :--- | :--- |
| Top Module | `jam_digital_top` (7 RTL source files) |
| Backend | Yosys 0.62 (Open-Source ASIC Backend) |
| Target Liberty | `sky130_fd_sc_hd__tt_025C_1v80.lib` (`sky130A`, TT 25 °C, 1.80 V) |
| Structural Check | `hierarchy -check -top jam_digital_top` & `check -assert` **PASS** |
| Latch Inference | **0 inferred latches** |

## Post-Mapping Area Breakdown (Pre-P&R Yosys Estimate)
- **Total Chip Area (`jam_digital_top`)**: **4331.6544 µm²**
- **Sequential Area**: **2335.9904 µm²** (**53.93%**, 93 flip-flops: `86` × `dfrtp_1`, `7` × `dfstp_2`)
- **Per-Module Local Area**:
  - `clock_divider` (`CLK_FREQ_HZ=50000000`, `SCAN_DIV=50000`): `2001.92 µm²` (198 cells, 44 DFFs)
  - `bcd_mod60_counter` (×2 instances): `948.41 µm²` total (`474.205 µm²` each, 8 DFFs each)
  - `seven_seg_mux6` (incl. `bcd_to_7seg`): `679.402 µm²` (16 DFFs)
  - `bcd_mod12_counter`: `435.418 µm²` (45 cells, 8 DFFs)
  - `edge_pulse_sync` (`WIDTH=3`): `243.984 µm²` (12 cells, 9 DFFs)

> Note: Vivado LUT/BRAM/DSP/Fmax fields are `N/A (Yosys Sky130 ASIC backend)`. Full multi-corner STA, CTS, routing, DRC, and LVS results are reported in `docs/03_physical_design_report.md` from the LibreLane P&R flow.
