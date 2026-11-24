# Konfigurasi & Hasil Simulasi (`sim/`)

Folder ini menyimpan daftar file kompilasi RTL serta seluruh log dan waveform hasil simulasi.

## Daftar File & Kegunaan

| Path | Isi & Kegunaan |
| :--- | :--- |
| [filelist.f](filelist.f) | Daftar berurutan 7 modul RTL di `../rtl/` yang dibaca oleh `iverilog` pada skrip simulasi RTL. |
| [results/compile.log](results/compile.log) | Log kompilasi `iverilog` untuk simulasi RTL. |
| [results/rtl_sim.log](results/rtl_sim.log) | Output teks simulasi RTL (`43.235` checks, `0` errors, penanda `[TB_INFO] Simulation Finished!`). |
| [results/jam_digital_rtl.vcd](results/jam_digital_rtl.vcd) | Waveform VCD simulasi RTL (`$dumpoff`/`$dumpon` dipakai selama loop 43.200 siklus agar ukuran file tetap ringkas). |
| [results/cocotb.log](results/cocotb.log) | Log eksekusi suite Python `cocotb 2.1.0` (`TESTS=3 PASS=3 FAIL=0`). |
| [results/cocotb_results.xml](results/cocotb_results.xml) | Hasil uji `cocotb` dalam format JUnit XML. |
| [results/gls_compile.log](results/gls_compile.log) | Log kompilasi *Post-P&R Sky130 Gate-Level Simulation*. |
| [results/gls_sim.log](results/gls_sim.log) | Output teks simulasi GLS pada netlist Sky130 (`43.229` checks, `0` errors). |
| [results/jam_digital_gls.vcd](results/jam_digital_gls.vcd) | Waveform VCD simulasi gate-level Sky130. |

> File biner sementara (`*.vvp` dan `results/cocotb_build/`) otomatis diabaikan oleh `.gitignore` dan dapat dibuat ulang kapan saja melalui `./scripts/run_rtl_sim.sh`, `./scripts/run_cocotb.sh`, dan `./scripts/run_gls.sh`.

## Inspeksi Waveform di GTKWave
```bash
gtkwave /home/yokemikal/eda/designs/projects/Jam_Digital/sim/results/jam_digital_rtl.vcd &
gtkwave /home/yokemikal/eda/designs/projects/Jam_Digital/sim/results/jam_digital_gls.vcd &
```
