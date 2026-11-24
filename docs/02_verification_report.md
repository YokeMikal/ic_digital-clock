# Laporan Verifikasi Fungsional & Gate-Level (`jam_digital_top`)

Seluruh tahapan verifikasi dijalankan secara langsung pada environment WSL Ubuntu (`/usr/bin/iverilog`, `/home/yokemikal/eda/venvs/ic-env`, dan LibreLane Nix-shell) tanpa fabrikasi hasil.

---

## 1. Ringkasan Hasil Verifikasi

| Tahap Verifikasi | Tool & Versi | Scope | Hasil | Log Bukti |
| :--- | :--- | :--- | :--- | :--- |
| **Static Lint** | Verilator `5.044` (`--lint-only -Wall`) | 7 modul RTL (`jam_digital_top`) | **PASS** (0 error, 0 warning) | `scripts/run_lint.sh` |
| **RTL Testbench** | Icarus Verilog `12.0` (`-g2012 -Wall`) | 7 skenario + **43.200 detik** sweep penuh | **PASS** (43.235 checks, 0 error) | `sim/results/rtl_sim.log` |
| **Python Golden Model** | cocotb `2.1.0` + Icarus `12.0` | 3 suite uji (reset, rollover, clamp, sync, 7-seg) | **PASS** (`TESTS=3 PASS=3 FAIL=0`) | `sim/results/cocotb.log` |
| **Post-P&R Sky130 GLS** | Icarus `12.0` (`-DFUNCTIONAL -DUNIT_DELAY=#1`) | Netlist routed `final/nl/jam_digital_top.nl.v` + **43.200 detik** sweep | **PASS** (43.229 checks, 0 error) | `sim/results/gls_sim.log` |

---

## 2. Matriks Kasus Uji (RTL & Post-P&R Gate-Level)

| ID | Kasus Uji | Kondisi & Stimulus | Hasil Verifikasi |
| :--- | :--- | :--- | :--- |
| **TC1** | Asynchronous Reset (`rst_n = 0`) | Assert `rst_n = 0` saat awal maupun di tengah simulasi | `00:00:00`, `am_pm_o = 0`, `rollover_pulse_o = 0` terverifikasi |
| **TC2** | Prescaler 1 Hz & Pause (`RTL`) | `CLK_FREQ_HZ=10, SCAN_DIV=2`, `fast_mode_i=0`, `en_i=1` lalu `en_i=0` selama 30 siklus | 5 tick tepat dalam 55 siklus (`00:00:05`), waktu terkunci saat `en_i=0` |
| **TC3** | Rollover Kritis (`fast_mode_i = 1`) | `00:00:59 -> 00:01:00`, `00:59:59 -> 01:00:00`, `09:59:59 -> 10:00:00`, `10:59:59 -> 11:00:00`, `11:59:59 -> 00:00:00` (2×) | `rollover_pulse_o = 1` tepat 1 siklus, `am_pm_o` toggle `0 -> 1 -> 0` |
| **TC4** | Sweep Penuh 12 Jam (**43.200 detik**) | Hitungan kontinu dari `00:00:00` s.d. `11:59:59 -> 00:00:00` dibanding golden behavioral model | **0 mismatch** di RTL (`43.200` detik) & **0 mismatch** di Sky130 GLS |
| **TC5** | Synchronous Load & BCD Clamping | Load valid `07:45:32`; load ilegal `19:79:99 -> 11:59:59`, `0F:0A:0B -> 09:09:09`, `52:60:60 -> 11:50:50` | Seluruh nibble ter-clamp deterministik sesuai batas BCD |
| **TC6** | Sinkronisasi Tombol Manual (`edge_pulse_sync`) | Tahan `inc_sec_i=1`, `inc_min_i=1`, `inc_hour_i=1` multi-siklus saat `en_i=0` | Latensi tepat 3 siklus clock, tepat 1× increment per tepi naik, wrap independen (`59->00` tanpa carry) |
| **TC7** | Driver 7-Segmen Termultipleks 6 Digit | Load `10:45:29`, pantau 12 siklus scan | `digit_sel_o` aktif one-hot `6'b000001..6'b100000` dengan pola segmen `9,2,5,4,0,1` |

---

## 3. Artefak Waveform & Cara Inspeksi di GTKWave

Simulasi menghasilkan dua file waveform VCD:
- RTL waveform: `sim/results/jam_digital_rtl.vcd`
- Post-P&R Sky130 Gate-Level waveform: `sim/results/jam_digital_gls.vcd`

> Catatan: Selama loop 43.200 siklus (`TC4`), dumping VCD dimatikan sementara (`$dumpoff`/`$dumpon`) agar ukuran file VCD tetap ringan dan cepat dibuka di GTKWave, sementara seluruh transisi kritis (reset, prescaler, rollover `11:59:59 -> 00:00:00`, clamping, manual sync, dan scan 7-segmen) terekam penuh.

Untuk membuka waveform di WSL Ubuntu:
```bash
gtkwave /home/yokemikal/eda/designs/projects/Jam_Digital/sim/results/jam_digital_rtl.vcd &
```
atau untuk waveform *Gate-Level Simulation*:
```bash
gtkwave /home/yokemikal/eda/designs/projects/Jam_Digital/sim/results/jam_digital_gls.vcd &
```
