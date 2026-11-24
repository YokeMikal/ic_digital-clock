# Testbench Verifikasi (`tb/`)

Folder ini berisi seluruh *testbench* untuk memverifikasi desain pada level **RTL**, **Python Golden Model (cocotb)**, dan **Post-P&R Sky130 Gate-Level Netlist**.

## Daftar File & Kegunaan

| File | Simulator / Framework | Fungsi & Cakupan Uji |
| :--- | :--- | :--- |
| [tb_jam_digital_top.v](tb_jam_digital_top.v) | Icarus Verilog (`iverilog` + `vvp`) | Testbench *self-checking* untuk RTL (`CLK_FREQ_HZ=10, SCAN_DIV=2`). Menguji **TC1** (reset), **TC2** (prescaler normal 1 Hz & pause), **TC3** (semua rollover kritis + `am_pm_o` & `rollover_pulse_o`), **TC4** (**sweep penuh 43.200 detik** kontinu `00:00:00 -> 11:59:59 -> 00:00:00`), **TC5** (synchronous load & clamping BCD), **TC6** (latensi 3 siklus tombol manual & anti-double-inc), dan **TC7** (scan 6-digit 7-segmen). |
| [test_jam_digital_cocotb.py](test_jam_digital_cocotb.py) | `cocotb 2.1.0` + Icarus Verilog | Suite uji Python (`test_reset_and_rollovers`, `test_clamping_and_manual_sync`, `test_seven_segment_mux`) yang membandingkan output RTL terhadap model referensi Python. |
| [tb_jam_digital_gls.v](tb_jam_digital_gls.v) | Icarus Verilog (`-DFUNCTIONAL -DUNIT_DELAY=#1`) | Testbench *Gate-Level Simulation* (GLS) yang mengeksekusi langsung netlist fisik `pnr/runs/jam_digital_sky130/final/nl/jam_digital_top.nl.v` bersama library sel standar `sky130_fd_sc_hd.v`, termasuk **sweep penuh 43.200 detik** pada gerbang Sky130. |

## Cara Menjalankan
Dari root proyek:
```bash
./scripts/run_rtl_sim.sh   # Menjalankan tb_jam_digital_top.v
./scripts/run_cocotb.sh    # Menjalankan test_jam_digital_cocotb.py
./scripts/run_gls.sh       # Menjalankan tb_jam_digital_gls.v (setelah P&R selesai)
```
