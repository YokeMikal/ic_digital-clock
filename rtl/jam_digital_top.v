// =============================================================================
// Module      : jam_digital_top
// Description : Top-level 6-digit BCD Digital Clock IC (HH:MM:SS, 00:00:00 to
//               11:59:59) with prescaler, synchronized manual increment
//               buttons, synchronous clamped load, AM/PM rollover indicator,
//               fast DFT test mode, and 6-digit multiplexed 7-segment driver.
// Standard    : Verilog-2001 (Synthesizable)
// =============================================================================

module jam_digital_top #(
    parameter integer CLK_FREQ_HZ = 50000000,
    parameter integer SCAN_DIV    = 50000
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       en_i,
    input  wire       fast_mode_i,
    input  wire       load_en_i,
    input  wire       inc_sec_i,
    input  wire       inc_min_i,
    input  wire       inc_hour_i,
    input  wire [3:0] load_hour_tens_i,
    input  wire [3:0] load_hour_ones_i,
    input  wire [3:0] load_min_tens_i,
    input  wire [3:0] load_min_ones_i,
    input  wire [3:0] load_sec_tens_i,
    input  wire [3:0] load_sec_ones_i,
    output wire [3:0] hour_tens_o,
    output wire [3:0] hour_ones_o,
    output wire [3:0] min_tens_o,
    output wire [3:0] min_ones_o,
    output wire [3:0] sec_tens_o,
    output wire [3:0] sec_ones_o,
    output wire       am_pm_o,
    output wire       rollover_pulse_o,
    output wire       tick_1hz_o,
    output wire [6:0] seg_o,
    output wire [5:0] digit_sel_o
);

    wire       tick_1hz;
    wire       tick_scan;
    wire [2:0] btn_pulses;

    wire       inc_sec_pulse;
    wire       inc_min_pulse;
    wire       inc_hour_pulse;

    wire       sec_is_max;
    wire       min_is_max;

    wire       sec_auto_carry;
    wire       min_auto_carry;

    wire       sec_inc;
    wire       min_inc;
    wire       hour_inc;

    // Clock divider & display scan tick generator
    clock_divider #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .SCAN_DIV    (SCAN_DIV)
    ) u_clock_divider (
        .clk             (clk),
        .rst_n           (rst_n),
        .en_i            (en_i),
        .fast_mode_i     (fast_mode_i),
        .clr_prescaler_i (load_en_i),
        .tick_1hz_o      (tick_1hz),
        .tick_scan_o     (tick_scan)
    );

    // 2-FF synchronizer + rising-edge detector for manual pushbuttons
    edge_pulse_sync #(
        .WIDTH (3)
    ) u_edge_pulse_sync (
        .clk     (clk),
        .rst_n   (rst_n),
        .async_i ({inc_hour_i, inc_min_i, inc_sec_i}),
        .pulse_o (btn_pulses)
    );

    assign inc_sec_pulse  = btn_pulses[0];
    assign inc_min_pulse  = btn_pulses[1];
    assign inc_hour_pulse = btn_pulses[2];

    // Automatic carry chain (only driven by 1 Hz timebase)
    assign sec_auto_carry = tick_1hz && sec_is_max;
    assign min_auto_carry = sec_auto_carry && min_is_max;

    // Combined increment enables (manual button wraps only its own field)
    assign sec_inc  = tick_1hz || inc_sec_pulse;
    assign min_inc  = sec_auto_carry || inc_min_pulse;
    assign hour_inc = min_auto_carry || inc_hour_pulse;

    // Seconds counter: 00..59
    bcd_mod60_counter u_sec_counter (
        .clk         (clk),
        .rst_n       (rst_n),
        .inc_i       (sec_inc),
        .load_en_i   (load_en_i),
        .load_tens_i (load_sec_tens_i),
        .load_ones_i (load_sec_ones_i),
        .tens_o      (sec_tens_o),
        .ones_o      (sec_ones_o),
        .is_max_o    (sec_is_max)
    );

    // Minutes counter: 00..59
    bcd_mod60_counter u_min_counter (
        .clk         (clk),
        .rst_n       (rst_n),
        .inc_i       (min_inc),
        .load_en_i   (load_en_i),
        .load_tens_i (load_min_tens_i),
        .load_ones_i (load_min_ones_i),
        .tens_o      (min_tens_o),
        .ones_o      (min_ones_o),
        .is_max_o    (min_is_max)
    );

    // Hours counter: 00..11
    bcd_mod12_counter u_hour_counter (
        .clk              (clk),
        .rst_n            (rst_n),
        .inc_i            (hour_inc),
        .load_en_i        (load_en_i),
        .load_tens_i      (load_hour_tens_i),
        .load_ones_i      (load_hour_ones_i),
        .tens_o           (hour_tens_o),
        .ones_o           (hour_ones_o),
        .am_pm_o          (am_pm_o),
        .rollover_pulse_o (rollover_pulse_o)
    );

    // 6-digit multiplexed 7-segment display driver
    seven_seg_mux6 u_seven_seg_mux6 (
        .clk         (clk),
        .rst_n       (rst_n),
        .tick_scan_i (tick_scan),
        .sec_ones_i  (sec_ones_o),
        .sec_tens_i  (sec_tens_o),
        .min_ones_i  (min_ones_o),
        .min_tens_i  (min_tens_o),
        .hour_ones_i (hour_ones_o),
        .hour_tens_i (hour_tens_o),
        .seg_o       (seg_o),
        .digit_sel_o (digit_sel_o)
    );

    assign tick_1hz_o = tick_1hz;

endmodule
