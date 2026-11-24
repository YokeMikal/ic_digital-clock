# Dokumentasi Desain (`docs/`)

Folder ini berisi dokumentasi arsitektur, hasil verifikasi fungsional, analisis *physical design*, dan render visual layout akhir.

| File | Isi & Kegunaan |
| :--- | :--- |
| [01_spec_architecture.md](01_spec_architecture.md) | Spesifikasi fungsional `00:00:00–11:59:59`, arsitektur modul, diagram alir Mermaid, tabel pinout 72-pin `jam_digital_top`, aturan clamping BCD, dan latensi 2-FF synchronizer. |
| [02_verification_report.md](02_verification_report.md) | Ringkasan bukti Verilator lint, simulasi RTL (`43.235` checks), cocotb (`3/3` pass), Sky130 GLS (`43.229` checks), tabel skenario TC1–TC7, dan perintah GTKWave. |
| [03_physical_design_report.md](03_physical_design_report.md) | Analisis lengkap hasil P&R LibreLane pada `sky130A`: geometri die/core, komposisi sel, wirelength & via, tabel STA 9 corner & Fmax, konsumsi daya, IR-drop, serta status DRC/LVS/XOR. |
| [layout_render.png](layout_render.png) | Render 2D layout GDSII final hasil KLayout untuk inspeksi visual cepat. |
