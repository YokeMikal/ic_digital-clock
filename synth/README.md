# Sintesis Standalone Yosys (`synth/`)

Folder ini digunakan untuk pemeriksaan sintesis RTL awal dan pemetaan cepat ke standard cell **Sky130 (`sky130_fd_sc_hd__tt_025C_1v80.lib`)** sebelum menjalankan alur Place & Route penuh di LibreLane.

## Daftar File & Kegunaan

| File | Isi & Kegunaan |
| :--- | :--- |
| [synth_yosys.ys](synth_yosys.ys) | Skrip Yosys yang membaca ke-7 file RTL, memeriksa hierarki (`hierarchy -check -top jam_digital_top`), menjalankan `proc/opt/fsm/memory/techmap`, memverifikasi `check -assert`, lalu memetakan DFF & logika kombinasional ke `sky130_fd_sc_hd__tt_025C_1v80.lib`. |
| [yosys_run.log](yosys_run.log) | Log lengkap eksekusi Yosys 0.62, termasuk verifikasi `0` latch terinferensi dan rincian area/sel per modul. |
| [yosys_synth_report.md](yosys_synth_report.md) | Ringkasan laporan sintesis (total area pre-P&R `4.331,65 µm²`, `93` flip-flop, rincian area tiap submodul). |
| [jam_digital_top_yosys.v](jam_digital_top_yosys.v) | Netlist gate-level hasil sintesis Yosys standalone (sebelum CTS dan buffering fisik). |

## Cara Menjalankan Ulang
Dari root proyek:
```bash
./scripts/run_yosys.sh
```
