// =============================================================================
// Testbench   : tb_jam_digital_top
// Description : Comprehensive self-checking RTL testbench for jam_digital_top
//               covering reset, normal 1 Hz prescaler & pause, critical
//               rollovers, 43,200-second exhaustive 12-hour sweep, synchronous
//               load & BCD clamping, synchronized manual increment buttons,
//               and 6-digit multiplexed 7-segment display encoding.
// =============================================================================
`timescale 1ns / 1ps

module tb_jam_digital_top;

    localparam integer TB_CLK_FREQ_HZ = 10;
    localparam integer TB_SCAN_DIV    = 2;
    localparam integer CLK_HALF_NS    = 10; // 50 MHz (20 ns period)

    reg        clk;
    reg        rst_n;
    reg        en_i;
    reg        fast_mode_i;
    reg        load_en_i;
    reg        inc_sec_i;
    reg        inc_min_i;
    reg        inc_hour_i;
    reg  [3:0] load_hour_tens_i;
    reg  [3:0] load_hour_ones_i;
    reg  [3:0] load_min_tens_i;
    reg  [3:0] load_min_ones_i;
    reg  [3:0] load_sec_tens_i;
    reg  [3:0] load_sec_ones_i;

    wire [3:0] hour_tens_o;
    wire [3:0] hour_ones_o;
    wire [3:0] min_tens_o;
    wire [3:0] min_ones_o;
    wire [3:0] sec_tens_o;
    wire [3:0] sec_ones_o;
    wire       am_pm_o;
    wire       rollover_pulse_o;
    wire       tick_1hz_o;
    wire [6:0] seg_o;
    wire [5:0] digit_sel_o;

    integer err_cnt;
    integer total_checks;

    // Golden behavioral variables for 43,200-second sweep
    integer g_sec;
    integer g_min;
    integer g_hour;
    reg     g_am_pm;
    reg     g_rollover;
    integer i;
    integer tick_count;

    // DUT instantiation
    jam_digital_top #(
        .CLK_FREQ_HZ (TB_CLK_FREQ_HZ),
        .SCAN_DIV    (TB_SCAN_DIV)
    ) dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .en_i             (en_i),
        .fast_mode_i      (fast_mode_i),
        .load_en_i        (load_en_i),
        .inc_sec_i        (inc_sec_i),
        .inc_min_i        (inc_min_i),
        .inc_hour_i       (inc_hour_i),
        .load_hour_tens_i (load_hour_tens_i),
        .load_hour_ones_i (load_hour_ones_i),
        .load_min_tens_i  (load_min_tens_i),
        .load_min_ones_i  (load_min_ones_i),
        .load_sec_tens_i  (load_sec_tens_i),
        .load_sec_ones_i  (load_sec_ones_i),
        .hour_tens_o      (hour_tens_o),
        .hour_ones_o      (hour_ones_o),
        .min_tens_o       (min_tens_o),
        .min_ones_o       (min_ones_o),
        .sec_tens_o       (sec_tens_o),
        .sec_ones_o       (sec_ones_o),
        .am_pm_o          (am_pm_o),
        .rollover_pulse_o (rollover_pulse_o),
        .tick_1hz_o       (tick_1hz_o),
        .seg_o            (seg_o),
        .digit_sel_o      (digit_sel_o)
    );

    // 50 MHz clock generation
    initial clk = 1'b0;
    always #CLK_HALF_NS clk = ~clk;

    // Helper function: expected 7-seg active-high code {g,f,e,d,c,b,a}
    function [6:0] expected_7seg;
        input [3:0] bcd;
        begin
            case (bcd)
                4'd0:    expected_7seg = 7'b011_1111;
                4'd1:    expected_7seg = 7'b000_0110;
                4'd2:    expected_7seg = 7'b101_1011;
                4'd3:    expected_7seg = 7'b100_1111;
                4'd4:    expected_7seg = 7'b110_0110;
                4'd5:    expected_7seg = 7'b110_1101;
                4'd6:    expected_7seg = 7'b111_1101;
                4'd7:    expected_7seg = 7'b000_0111;
                4'd8:    expected_7seg = 7'b111_1111;
                4'd9:    expected_7seg = 7'b110_1111;
                default: expected_7seg = 7'b000_0000;
            endcase
        end
    endfunction

    // Helper task: check current BCD time & flags
    task check_time;
        input [3:0] exp_ht;
        input [3:0] exp_ho;
        input [3:0] exp_mt;
        input [3:0] exp_mo;
        input [3:0] exp_st;
        input [3:0] exp_so;
        input       exp_am_pm;
        input       exp_rollover;
        input [8*40-1:0] label;
        begin
            total_checks = total_checks + 1;
            if ({hour_tens_o, hour_ones_o, min_tens_o, min_ones_o, sec_tens_o, sec_ones_o} !==
                {exp_ht, exp_ho, exp_mt, exp_mo, exp_st, exp_so} ||
                am_pm_o !== exp_am_pm ||
                rollover_pulse_o !== exp_rollover) begin
                $display("[TB_ERROR] %0s | Got %0d%0d:%0d%0d:%0d%0d am_pm=%b roll=%b | Exp %0d%0d:%0d%0d:%0d%0d am_pm=%b roll=%b",
                         label,
                         hour_tens_o, hour_ones_o, min_tens_o, min_ones_o, sec_tens_o, sec_ones_o,
                         am_pm_o, rollover_pulse_o,
                         exp_ht, exp_ho, exp_mt, exp_mo, exp_st, exp_so,
                         exp_am_pm, exp_rollover);
                err_cnt = err_cnt + 1;
            end
        end
    endtask

    // Helper task: load a time synchronously cleanly on negedge
    task sync_load_time;
        input [3:0] ht;
        input [3:0] ho;
        input [3:0] mt;
        input [3:0] mo;
        input [3:0] st;
        input [3:0] so;
        begin
            @(negedge clk);
            load_hour_tens_i = ht;
            load_hour_ones_i = ho;
            load_min_tens_i  = mt;
            load_min_ones_i  = mo;
            load_sec_tens_i  = st;
            load_sec_ones_i  = so;
            load_en_i        = 1'b1;
            @(posedge clk);
            @(negedge clk);
            load_en_i        = 1'b0;
        end
    endtask

    // Helper task: advance 1 second in fast_mode_i=1 starting from settled state where tick_1hz==0
    task fast_step_from_load;
        begin
            // First posedge primes tick_1hz <= 1 while counters hold loaded value
            @(posedge clk);
            // Second posedge increments counters
            @(posedge clk);
            @(negedge clk);
        end
    endtask

    // Helper task: check all 6 multiplexed digits against current expected BCD time
    task check_7seg_scan;
        input [3:0] exp_ht;
        input [3:0] exp_ho;
        input [3:0] exp_mt;
        input [3:0] exp_mo;
        input [3:0] exp_st;
        input [3:0] exp_so;
        reg [5:0] seen_digits;
        integer   cyc;
        begin
            seen_digits = 6'b000000;
            for (cyc = 0; cyc < 12; cyc = cyc + 1) begin
                @(negedge clk);
                total_checks = total_checks + 1;
                case (digit_sel_o)
                    6'b000_001: begin
                        seen_digits[0] = 1'b1;
                        if (seg_o !== expected_7seg(exp_so)) begin
                            $display("[TB_ERROR] 7-seg digit 0 (sec_ones) mismatch: got %b exp %b", seg_o, expected_7seg(exp_so));
                            err_cnt = err_cnt + 1;
                        end
                    end
                    6'b000_010: begin
                        seen_digits[1] = 1'b1;
                        if (seg_o !== expected_7seg(exp_st)) begin
                            $display("[TB_ERROR] 7-seg digit 1 (sec_tens) mismatch: got %b exp %b", seg_o, expected_7seg(exp_st));
                            err_cnt = err_cnt + 1;
                        end
                    end
                    6'b000_100: begin
                        seen_digits[2] = 1'b1;
                        if (seg_o !== expected_7seg(exp_mo)) begin
                            $display("[TB_ERROR] 7-seg digit 2 (min_ones) mismatch: got %b exp %b", seg_o, expected_7seg(exp_mo));
                            err_cnt = err_cnt + 1;
                        end
                    end
                    6'b001_000: begin
                        seen_digits[3] = 1'b1;
                        if (seg_o !== expected_7seg(exp_mt)) begin
                            $display("[TB_ERROR] 7-seg digit 3 (min_tens) mismatch: got %b exp %b", seg_o, expected_7seg(exp_mt));
                            err_cnt = err_cnt + 1;
                        end
                    end
                    6'b010_000: begin
                        seen_digits[4] = 1'b1;
                        if (seg_o !== expected_7seg(exp_ho)) begin
                            $display("[TB_ERROR] 7-seg digit 4 (hour_ones) mismatch: got %b exp %b", seg_o, expected_7seg(exp_ho));
                            err_cnt = err_cnt + 1;
                        end
                    end
                    6'b100_000: begin
                        seen_digits[5] = 1'b1;
                        if (seg_o !== expected_7seg(exp_ht)) begin
                            $display("[TB_ERROR] 7-seg digit 5 (hour_tens) mismatch: got %b exp %b", seg_o, expected_7seg(exp_ht));
                            err_cnt = err_cnt + 1;
                        end
                    end
                    default: begin
                        $display("[TB_ERROR] Invalid one-hot digit_sel_o=%b", digit_sel_o);
                        err_cnt = err_cnt + 1;
                    end
                endcase
            end
            total_checks = total_checks + 1;
            if (seen_digits !== 6'b111111) begin
                $display("[TB_ERROR] Not all 6 digits scanned: seen_digits=%b", seen_digits);
                err_cnt = err_cnt + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("results/jam_digital_rtl.vcd");
        $dumpvars(0, tb_jam_digital_top);

        err_cnt          = 0;
        total_checks     = 0;
        rst_n            = 1'b0;
        en_i             = 1'b0;
        fast_mode_i      = 1'b0;
        load_en_i        = 1'b0;
        inc_sec_i        = 1'b0;
        inc_min_i        = 1'b0;
        inc_hour_i       = 1'b0;
        load_hour_tens_i = 4'd0;
        load_hour_ones_i = 4'd0;
        load_min_tens_i  = 4'd0;
        load_min_ones_i  = 4'd0;
        load_sec_tens_i  = 4'd0;
        load_sec_ones_i  = 4'd0;

        // ---------------------------------------------------------------------
        // TC1: Reset verification
        // ---------------------------------------------------------------------
        $display("[TB_MONITOR] TC1: Asynchronous reset check");
        #35;
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b0, "TC1_RESET_LOW");
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        @(negedge clk);
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b0, "TC1_RESET_RELEASE");

        // ---------------------------------------------------------------------
        // TC2: Normal prescaler (CLK_FREQ_HZ=10) & Pause (en_i=0)
        // ---------------------------------------------------------------------
        $display("[TB_MONITOR] TC2: Normal prescaler 10-cycle 1Hz & pause");
        en_i        = 1'b1;
        fast_mode_i = 1'b0;
        tick_count  = 0;
        for (i = 0; i < 55; i = i + 1) begin
            @(posedge clk);
            if (tick_1hz_o) begin
                tick_count = tick_count + 1;
            end
        end
        @(negedge clk);
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd5, 1'b0, 1'b0, "TC2_PRESCALER_5S");
        total_checks = total_checks + 1;
        if (tick_count !== 5) begin
            $display("[TB_ERROR] TC2 expected 5 ticks in 55 cycles, got %0d", tick_count);
            err_cnt = err_cnt + 1;
        end

        // Pause check: disable en_i for 30 cycles
        en_i = 1'b0;
        repeat (30) @(posedge clk);
        @(negedge clk);
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd5, 1'b0, 1'b0, "TC2_PAUSE_HOLD");

        // ---------------------------------------------------------------------
        // TC3: All critical rollover boundaries (fast_mode_i=1)
        // ---------------------------------------------------------------------
        $display("[TB_MONITOR] TC3: Critical rollover boundaries");
        fast_mode_i = 1'b1;
        en_i        = 1'b1;

        // 00:00:59 -> 00:01:00
        sync_load_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd5, 4'd9);
        fast_step_from_load();
        check_time(4'd0, 4'd0, 4'd0, 4'd1, 4'd0, 4'd0, 1'b0, 1'b0, "TC3_00_00_59_TO_00_01_00");

        // 00:59:59 -> 01:00:00
        sync_load_time(4'd0, 4'd0, 4'd5, 4'd9, 4'd5, 4'd9);
        fast_step_from_load();
        check_time(4'd0, 4'd1, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b0, "TC3_00_59_59_TO_01_00_00");

        // 09:59:59 -> 10:00:00
        sync_load_time(4'd0, 4'd9, 4'd5, 4'd9, 4'd5, 4'd9);
        fast_step_from_load();
        check_time(4'd1, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b0, "TC3_09_59_59_TO_10_00_00");

        // 10:59:59 -> 11:00:00
        sync_load_time(4'd1, 4'd0, 4'd5, 4'd9, 4'd5, 4'd9);
        fast_step_from_load();
        check_time(4'd1, 4'd1, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b0, "TC3_10_59_59_TO_11_00_00");

        // 11:59:59 -> 00:00:00 (rollover #1: am_pm 0 -> 1, rollover_pulse_o == 1 for 1 cycle)
        sync_load_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd5, 4'd9);
        fast_step_from_load();
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b1, 1'b1, "TC3_11_59_59_ROLLOVER_1");
        @(posedge clk);
        @(negedge clk);
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd1, 1'b1, 1'b0, "TC3_POST_ROLLOVER_1");

        // Second 11:59:59 -> 00:00:00 (rollover #2: am_pm 1 -> 0)
        sync_load_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd5, 4'd9);
        fast_step_from_load();
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b1, "TC3_11_59_59_ROLLOVER_2");
        $display("[TB_DATA] TC3 critical rollovers verified cleanly.");

        // ---------------------------------------------------------------------
        // TC4: Exhaustive 12-Hour Continuous Sweep (43,200 seconds)
        // ---------------------------------------------------------------------
        $display("[TB_MONITOR] TC4: Exhaustive 43,200-second continuous sweep");
        // Reset cleanly so am_pm_o = 0 and time = 00:00:00
        @(negedge clk);
        rst_n = 1'b0;
        @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;

        // Prime tick_1hz <= 1
        @(posedge clk);
        @(negedge clk);

        g_sec      = 0;
        g_min      = 0;
        g_hour     = 0;
        g_am_pm    = 1'b0;
        g_rollover = 1'b0;

        // Disable VCD dumping during massive 43,200-cycle sweep to keep VCD fast & small
        $dumpoff;
        for (i = 1; i <= 43200; i = i + 1) begin
            @(posedge clk);
            @(negedge clk);

            // Advance golden model by 1 second
            g_rollover = 1'b0;
            if (g_sec == 59) begin
                g_sec = 0;
                if (g_min == 59) begin
                    g_min = 0;
                    if (g_hour == 11) begin
                        g_hour     = 0;
                        g_am_pm    = ~g_am_pm;
                        g_rollover = 1'b1;
                    end else begin
                        g_hour = g_hour + 1;
                    end
                end else begin
                    g_min = g_min + 1;
                end
            end else begin
                g_sec = g_sec + 1;
            end

            total_checks = total_checks + 1;
            if ((hour_tens_o * 10 + hour_ones_o) !== g_hour ||
                (min_tens_o  * 10 + min_ones_o)  !== g_min  ||
                (sec_tens_o  * 10 + sec_ones_o)  !== g_sec  ||
                am_pm_o !== g_am_pm ||
                rollover_pulse_o !== g_rollover) begin
                $display("[TB_ERROR] TC4 mismatch at second %0d: Got %0d%0d:%0d%0d:%0d%0d am_pm=%b roll=%b | Exp %02d:%02d:%02d am_pm=%b roll=%b",
                         i,
                         hour_tens_o, hour_ones_o, min_tens_o, min_ones_o, sec_tens_o, sec_ones_o,
                         am_pm_o, rollover_pulse_o,
                         g_hour, g_min, g_sec, g_am_pm, g_rollover);
                err_cnt = err_cnt + 1;
            end
        end
        $dumpon;
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b1, 1'b1, "TC4_END_43200S");
        $display("[TB_DATA] TC4 completed 43,200 consecutive states with 0 mismatches.");

        // ---------------------------------------------------------------------
        // TC5: Synchronous Load & Illegal BCD Clamping
        // ---------------------------------------------------------------------
        $display("[TB_MONITOR] TC5: Synchronous load & illegal BCD clamping");
        en_i = 1'b0;

        sync_load_time(4'd0, 4'd7, 4'd4, 4'd5, 4'd3, 4'd2);
        check_time(4'd0, 4'd7, 4'd4, 4'd5, 4'd3, 4'd2, 1'b1, 1'b0, "TC5_VALID_07_45_32");

        sync_load_time(4'd1, 4'd9, 4'd7, 4'd9, 4'd9, 4'd9);
        check_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd5, 4'd9, 1'b1, 1'b0, "TC5_CLAMP_19_79_99");

        sync_load_time(4'h0, 4'hF, 4'h0, 4'hA, 4'h0, 4'hB);
        check_time(4'd0, 4'd9, 4'd0, 4'd9, 4'd0, 4'd9, 1'b1, 1'b0, "TC5_CLAMP_0F_0A_0B");

        sync_load_time(4'd5, 4'd2, 4'd6, 4'd0, 4'd6, 4'd0);
        check_time(4'd1, 4'd1, 4'd5, 4'd0, 4'd5, 4'd0, 1'b1, 1'b0, "TC5_CLAMP_52_60_60");

        // ---------------------------------------------------------------------
        // TC6: Manual Increment Pushbuttons (2-FF sync + rising-edge)
        // ---------------------------------------------------------------------
        $display("[TB_MONITOR] TC6: Manual increment buttons & 2-FF sync");
        // Test 59 -> 00 on sec without disturbing min/hour
        sync_load_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd5, 4'd9);
        @(negedge clk);
        inc_sec_i = 1'b1;
        // Cycle 1 & 2: synchronizer pipeline filling -> value must still be 11:59:59
        repeat (2) @(posedge clk);
        @(negedge clk);
        check_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd5, 4'd9, 1'b1, 1'b0, "TC6_SEC_SYNC_WAIT");
        // Cycle 3: pulse detected -> sec wraps 59 -> 00 independently!
        @(posedge clk);
        @(negedge clk);
        check_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd0, 4'd0, 1'b1, 1'b0, "TC6_SEC_WRAP_NO_CARRY");
        // Hold inc_sec_i high 4 more cycles -> must NOT double-increment!
        repeat (4) @(posedge clk);
        @(negedge clk);
        check_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd0, 4'd0, 1'b1, 1'b0, "TC6_SEC_NO_DOUBLE_INC");
        inc_sec_i = 1'b0;
        repeat (3) @(posedge clk);

        // Manual inc_min_i: 59 -> 00 without disturbing hour
        @(negedge clk);
        inc_min_i = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        check_time(4'd1, 4'd1, 4'd0, 4'd0, 4'd0, 4'd0, 1'b1, 1'b0, "TC6_MIN_WRAP_NO_CARRY");
        inc_min_i = 1'b0;
        repeat (3) @(posedge clk);

        // Manual inc_hour_i: 11 -> 00 toggles am_pm_o (1 -> 0) and pulses rollover
        @(negedge clk);
        inc_hour_i = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b1, "TC6_HOUR_WRAP_11_TO_00");
        inc_hour_i = 1'b0;
        repeat (3) @(posedge clk);

        // ---------------------------------------------------------------------
        // TC7: 6-digit multiplexed 7-segment display verification
        // ---------------------------------------------------------------------
        $display("[TB_MONITOR] TC7: 6-digit multiplexed 7-segment display");
        sync_load_time(4'd1, 4'd0, 4'd4, 4'd5, 4'd2, 4'd9);
        fast_mode_i = 1'b1;
        en_i        = 1'b0;
        repeat (2) @(posedge clk);
        check_7seg_scan(4'd1, 4'd0, 4'd4, 4'd5, 4'd2, 4'd9);
        $display("[TB_DATA] TC7 7-segment scan verified for 10:45:29.");

        $display("[TB_MONITOR] Total Checks=%0d, Errors=%0d", total_checks, err_cnt);
        if (err_cnt == 0) begin
            $display("[TB_INFO] Simulation Finished!");
        end else begin
            $display("[TB_ERROR] Simulation finished with %0d errors!", err_cnt);
        end
        $finish;
    end

endmodule
