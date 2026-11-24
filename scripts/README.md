# Skrip Otomasi Alur EDA (`scripts/`)

Folder ini berisi skrip bash siap pakai untuk menjalankan seluruh alur kerja desain IC secara terurut dari WSL Ubuntu.

## Daftar Skrip & Urutan Eksekusi

| Urutan | Skrip | Tool yang Dipanggil | Fungsi & Output Utama |
| :---: | :--- | :--- | :--- |
| 1 | [run_lint.sh](run_lint.sh) | Verilator (`nix-shell`) | Lint ketat `--lint-only -Wall` pada ke-7 modul RTL (`0` error, `0` warning). |
| 2 | [run_rtl_sim.sh](run_rtl_sim.sh) | `iverilog` & `vvp` | Kompilasi & simulasi `tb/tb_jam_digital_top.v` -> `sim/results/rtl_sim.log` & `jam_digital_rtl.vcd`. |
| 3 | [run_cocotb.sh](run_cocotb.sh) | `cocotb 2.1.0` (`ic-env`) | Verifikasi golden model Python (`tb/test_jam_digital_cocotb.py`) -> `sim/results/cocotb.log`. |
| 4 | [run_yosys.sh](run_yosys.sh) | Yosys (`nix-shell`) | Sintesis & cek latch Sky130 TT (`synth/synth_yosys.ys`) -> `synth/yosys_run.log`. |
| 5 | [run_pnr_librelane.sh](run_pnr_librelane.sh) | LibreLane (`nix-shell`) | Alur penuh 80 tahap RTL-to-GDSII (`pnr/config.json`) -> `pnr/runs/jam_digital_sky130/final/`. |
| 6 | [run_gls.sh](run_gls.sh) | `iverilog` & `vvp` | Simulasi Gate-Level Sky130 (`tb/tb_jam_digital_gls.v`) -> `sim/results/gls_sim.log` & `jam_digital_gls.vcd`. |
| 7 | [open_klayout.sh](open_klayout.sh) | KLayout (`nix-shell`) | Membuka `jam_digital_top.gds` di KLayout lengkap dengan file layer `sky130A.lyp`. |

> Catatan: Skrip yang memanggil `nix-shell` sudah menyertakan `export PATH="/nix/var/nix/profiles/default/bin:..."` sehingga tetap berjalan meski dijalankan dari non-login shell. Pastikan izin eksekusi aktif (`chmod +x scripts/*.sh`).
