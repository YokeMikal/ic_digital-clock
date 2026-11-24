# Kode Sumber RTL (`rtl/`)

Folder ini berisi **7 modul Verilog-2001 sintetisabel** dengan satu domain clock sinkron `clk` (50 MHz nominal), reset asinkron aktif-rendah `rst_n`, bebas *latch*, bebas *gated clock*, dan lulus `verilator --lint-only -Wall` dengan `0` error / `0` warning.

## Hierarki Modul

```text
jam_digital_top
├── u_clock_divider      (clock_divider.v)
├── u_edge_pulse_sync    (edge_pulse_sync.v)
├── u_sec_counter        (bcd_mod60_counter.v)
├── u_min_counter        (bcd_mod60_counter.v)
├── u_hour_counter       (bcd_mod12_counter.v)
└── u_seven_seg_mux6     (seven_seg_mux6.v)
    └── u_bcd_to_7seg    (bcd_to_7seg.v)
```

## Daftar File & Kegunaan

| File | Modul | Fungsi |
| :--- | :--- | :--- |
| [jam_digital_top.v](jam_digital_top.v) | `jam_digital_top` | Modul *top-level* 72-pin yang menghubungkan prescaler, sinkronizer tombol manual, rantai carry detik→menit→jam, dan driver display 7-segmen. |
| [clock_divider.v](clock_divider.v) | `clock_divider` | Prescaler sinkron (`CLK_FREQ_HZ=50000000`, `SCAN_DIV=50000`) penghasil pulsa `tick_1hz_o` dan `tick_scan_o`, dengan bypass `fast_mode_i` untuk uji cepat. |
| [edge_pulse_sync.v](edge_pulse_sync.v) | `edge_pulse_sync` | Sinkronizer 2-FF + detektor *rising-edge* 1 siklus (latensi 3 siklus clock) untuk `inc_sec_i`, `inc_min_i`, dan `inc_hour_i`. |
| [bcd_mod60_counter.v](bcd_mod60_counter.v) | `bcd_mod60_counter` | Counter BCD `00..59` (detik dan menit) dengan *synchronous load* (clamping tens maks `5`, ones maks `9`) serta sinyal `is_max_o`. |
| [bcd_mod12_counter.v](bcd_mod12_counter.v) | `bcd_mod12_counter` | Counter BCD `00..11` (jam) dengan *clamped load*, rollover `11 -> 00`, pulsa 1 siklus `rollover_pulse_o`, dan toggle `am_pm_o`. |
| [seven_seg_mux6.v](seven_seg_mux6.v) | `seven_seg_mux6` | Driver 6-digit *time-multiplexed* (`digit_sel_o[5:0]` one-hot, `seg_o[6:0]` teregister bebas glitch). |
| [bcd_to_7seg.v](bcd_to_7seg.v) | `bcd_to_7seg` | Dekoder kombinasional BCD (0–9) ke segmen aktif-tinggi `{g, f, e, d, c, b, a}`. |

## Konvensi Desain
- Tidak menyertakan direktif `` `timescale `` di dalam file RTL sintetisabel agar lint LibreLane bersih (`0` warning `TIMESCALEMOD`); `timescale` didefinisikan di testbench.
- Untuk menjalankan lint atau simulasi dari root proyek:
  ```bash
  ./scripts/run_lint.sh
  ./scripts/run_rtl_sim.sh
  ```
