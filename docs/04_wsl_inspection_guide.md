# Panduan Pengecekan & Analisis Hasil Desain IC di WSL Ubuntu

Panduan langkah demi langkah untuk memeriksa seluruh hasil desain IC **`jam_digital_top`** — mulai dari *waveform* simulasi RTL & Gate-Level, inspeksi layout fisik GDSII di KLayout & OpenROAD GUI, hingga pengecekan metrik *signoff* (area, STA, power, DRC, LVS) di **WSL Ubuntu**.

---

## 1. Masuk ke Direktori Proyek

Buka terminal **WSL Ubuntu**, lalu masuk ke direktori proyek:

```bash
cd /home/yokemikal/eda/designs/projects/Jam_Digital
```

---

## 2. Mengecek Hasil Lint & Simulasi RTL (Waveform GTKWave)

1. **Jalankan / verifikasi ulang Lint & Simulasi RTL** (opsional jika ingin membangkitkan ulang log dan file `.vcd`):

   ```bash
   ./scripts/run_lint.sh
   ./scripts/run_rtl_sim.sh
   ./scripts/run_cocotb.sh
   ```

2. **Lihat ringkasan log simulasi langsung di terminal**:

   ```bash
   cat sim/results/rtl_sim.log
   cat sim/results/cocotb.log
   ```

3. **Buka Waveform RTL di GTKWave**:

   ```bash
   gtkwave sim/results/jam_digital_rtl.vcd &
   ```

   **Sinyal penting untuk ditambahkan ke panel waveform** (`tb_jam_digital_top` → `dut`):
   - **Clock & Kontrol**: `clk`, `rst_n`, `en_i`, `fast_mode_i`, `load_en_i`, `tick_1hz_o`
   - **Tombol Manual**: `inc_sec_i`, `inc_min_i`, `inc_hour_i`
   - **Digit Waktu** *(ubah Data Format ke **Decimal** atau **Hex**)*: `hour_tens_o`, `hour_ones_o`, `min_tens_o`, `min_ones_o`, `sec_tens_o`, `sec_ones_o`
   - **Rollover (`11:59:59 -> 00:00:00`)**: `rollover_pulse_o`, `am_pm_o`
   - **Display 7-Segmen** *(ubah Data Format ke **Binary**)*: `digit_sel_o[5:0]`, `seg_o[6:0]`

---

## 3. Mengecek Simulasi Gate-Level Post-P&R (Gerbang Fisik Sky130)

Untuk memastikan netlist hasil *Place & Route* (`pnr/runs/jam_digital_sky130/final/nl/jam_digital_top.nl.v`) bekerja identik dengan RTL di atas sel standar `sky130_fd_sc_hd`:

```bash
./scripts/run_gls.sh
cat sim/results/gls_sim.log
gtkwave sim/results/jam_digital_gls.vcd &
```

---

## 4. Mengecek & Menganalisis Layout Fisik GDSII (KLayout & OpenROAD GUI)

### A. Membuka Layout GDSII di KLayout (dengan Layer Sky130A)

Jalankan skrip berikut untuk langsung membuka `pnr/runs/jam_digital_sky130/final/gds/jam_digital_top.gds` dengan palet warna resmi `sky130A.lyp`:

```bash
./scripts/open_klayout.sh
```

**Tips navigasi di KLayout**:
- Di panel **Hierarchy** (kiri), klik kanan pada `jam_digital_top` → **Show As New Top**, lalu tekan **`Shift + F`** (atau menu *Display → Full Hierarchy*) agar seluruh struktur *standard cell* (`dfrtp`, `nand`, `clkbuf`, dll.) di bagian dalam terlihat jelas.
- Gunakan panel **Layers** (kanan) untuk menyalakan/mematikan layer metal (`li1`, `met1`–`met5`, `via`–`via4`) saat memeriksa jalur *routing*, pin I/O, atau *power grid* (`VPWR`/`VGND`).

### B. Membuka Layout Interaktif + Analisis Timing/Congestion di OpenROAD GUI

Untuk mengecek *Clock Tree (CTS)*, *Routing Congestion heatmap*, *IR Drop*, dan *Critical Timing Paths* secara visual di **OpenROAD GUI**:

```bash
cd /home/yokemikal/eda/tools/librelane
nix-shell --run "librelane --last-run --flow OpenInOpenROAD /home/yokemikal/eda/designs/projects/Jam_Digital/pnr/config.json"
```

---

## 5. Mengecek Metrik Signoff (Area, STA 9-Corner, Power, DRC, LVS) dari Terminal

1. **Baca laporan analisis lengkap**:
   - [01_spec_architecture.md](01_spec_architecture.md) — Spesifikasi & arsitektu
   - [02_verification_report.md](02_verification_report.md) — Laporan verifikasi fungsional & GLS
   - [03_physical_design_report.md](03_physical_design_report.md) — Laporan analisis physical design
   - [../synth/yosys_synth_report.md](../synth/yosys_synth_report.md) — Laporan sintesis Yosys standalone

2. **Filter metrik utama langsung dari `pnr/runs/jam_digital_sky130/final/metrics.json`**:

   ```bash
   cd /home/yokemikal/eda/designs/projects/Jam_Digital
   grep -E "die__area|core__area|utilization|wirelength\"|setup__ws\"|hold__ws\"|power__total|drc_error|lvs_error|xor_difference" pnr/runs/jam_digital_sky130/final/metrics.json
   ```

3. **Lihat jalur kritis (*critical path* STA) dan rincian daya**:

   ```bash
   less pnr/runs/jam_digital_sky130/55-openroad-stapostpnr/nom_tt_025C_1v80/checks.rpt
   cat pnr/runs/jam_digital_sky130/55-openroad-stapostpnr/nom_tt_025C_1v80/power.rpt
   ```

   *(Catatan: Folder `55-openroad-stapostpnr/` merupakan hasil run lokal di WSL Ubuntu; di repositori Git hanya folder `final/` dan log ringkasan utama yang disimpan sesuai `.gitignore`.)*
