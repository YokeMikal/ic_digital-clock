# Physical Design RTL-to-GDSII (`pnr/`)

Folder ini menampung konfigurasi **LibreLane v3.0.17** dan seluruh artefak signoff fisik akhir pada PDK **SkyWater 130nm (`sky130A`)**.

## Daftar File & Sub-Direktori

| Path | Isi & Kegunaan |
| :--- | :--- |
| [config.json](config.json) | Konfigurasi alur LibreLane: top module `jam_digital_top`, daftar 7 file RTL, `CLOCK_PORT = clk`, `CLOCK_PERIOD = 20.0` ns (50 MHz), `FP_CORE_UTIL = 40%`, `PL_TARGET_DENSITY_PCT = 55%`, dan `RSZ_CORNERS` multi-corner. |
| `runs/jam_digital_sky130/final/` | Direktori output signoff akhir dari run `jam_digital_sky130` (tahap perantara `01-` s.d. `76-` dan `tmp/` dikecualikan di `.gitignore` agar ukuran repo tetap ringkas). |

### Isi `runs/jam_digital_sky130/final/`

| Sub-Folder / File | Kegunaan |
| :--- | :--- |
| `gds/jam_digital_top.gds` | Layout fisik GDSII final hasil Magic streamout (`0` Magic DRC, `0` illegal overlap). |
| `klayout_gds/jam_digital_top.klayout.gds` | Layout GDSII hasil KLayout streamout (`0` KLayout DRC, `0` XOR diff terhadap Magic GDS). |
| `nl/jam_digital_top.nl.v` | Netlist Verilog post-P&R (logical, tanpa pin power) yang dipakai pada `tb_jam_digital_gls.v`. |
| `pnl/jam_digital_top.pnl.v` | Netlist Verilog post-P&R lengkap dengan pin power `VPWR`/`VGND`. |
| `def/` & `lef/` & `odb/` | File physical layout (`DEF`), macro abstract (`LEF`), dan database OpenROAD (`ODB`). |
| `spef/` & `sdf/` & `sdc/` & `lib/` | Ekstraksi parasitik RC (`SPEF`), timing delay (`SDF`), constraint (`SDC`), dan Liberty (`LIB`) multi-corner (`nom`/`min`/`max` × `tt`/`ss`/`ff`). |
| `mag/`, `mag_gds/`, `spice/`, `vh/` | Database layout Magic, netlist SPICE hasil ekstraksi untuk Netgen LVS, dan header Verilog. |
| `render/jam_digital_top.png` | Gambar render 2D layout GDSII dari KLayout. |
| `metrics.json` & `metrics.csv` | Seluruh metrik signoff (area, utilisasi, wirelength, via, STA 9 corner, power, IR-drop, DRC, LVS). |

## Cara Menjalankan Ulang P&R atau Membuka Layout
```bash
./scripts/run_pnr_librelane.sh   # Menjalankan ulang seluruh alur RTL-to-GDSII (~1-2 menit)
./scripts/open_klayout.sh        # Membuka jam_digital_top.gds di KLayout dengan layer sky130A
```
