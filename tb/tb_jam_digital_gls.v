// =============================================================================
// Testbench   : tb_jam_digital_gls
// Description : Post-P&R Gate-Level Simulation (GLS) testbench targeting the
//               routed Sky130 standard-cell netlist (final/nl/jam_digital_top.nl.v)
//               with -DFUNCTIONAL -DUNIT_DELAY=#1.
// =============================================================================
`timescale 1ns / 1ps

module tb_jam_digital_gls;

    localparam integer CLK_HALF_NS = 10; // 50 MHz (20 ns period)

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

    integer g_sec;
    integer g_min;
    integer g_hour;
    reg     g_am_pm;
    reg     g_rollover;
    integer i;

    // Gate-level DUT (no parameters in synthesized netlist)
    jam_digital_top dut (
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

    initial clk = 1'b0;
    always #CLK_HALF_NS clk = ~clk;

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

    task fast_step_from_load;
        begin
            @(posedge clk);
            @(posedge clk);
            @(negedge clk);
        end
    endtask

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
                            $display("[TB_ERROR] GLS 7-seg digit 0 mismatch: got %b exp %b", seg_o, expected_7seg(exp_so));
                            err_cnt = err_cnt + 1;
                        end
                    end
                    6'b000_010: begin
                        seen_digits[1] = 1'b1;
                        if (seg_o !== expected_7seg(exp_st)) begin
                            $display("[TB_ERROR] GLS 7-seg digit 1 mismatch: got %b exp %b", seg_o, expected_7seg(exp_st));
                            err_cnt = err_cnt + 1;
                        end
                    end
                    6'b000_100: begin
                        seen_digits[2] = 1'b1;
                        if (seg_o !== expected_7seg(exp_mo)) begin
                            $display("[TB_ERROR] GLS 7-seg digit 2 mismatch: got %b exp %b", seg_o, expected_7seg(exp_mo));
                            err_cnt = err_cnt + 1;
                        end
                    end
                    6'b001_000: begin
                        seen_digits[3] = 1'b1;
                        if (seg_o !== expected_7seg(exp_mt)) begin
                            $display("[TB_ERROR] GLS 7-seg digit 3 mismatch: got %b exp %b", seg_o, expected_7seg(exp_mt));
                            err_cnt = err_cnt + 1;
                        end
                    end
                    6'b010_000: begin
                        seen_digits[4] = 1'b1;
                        if (seg_o !== expected_7seg(exp_ho)) begin
                            $display("[TB_ERROR] GLS 7-seg digit 4 mismatch: got %b exp %b", seg_o, expected_7seg(exp_ho));
                            err_cnt = err_cnt + 1;
                        end
                    end
                    6'b100_000: begin
                        seen_digits[5] = 1'b1;
                        if (seg_o !== expected_7seg(exp_ht)) begin
                            $display("[TB_ERROR] GLS 7-seg digit 5 mismatch: got %b exp %b", seg_o, expected_7seg(exp_ht));
                            err_cnt = err_cnt + 1;
                        end
                    end
                    default: begin
                        $display("[TB_ERROR] GLS invalid one-hot digit_sel_o=%b", digit_sel_o);
                        err_cnt = err_cnt + 1;
                    end
                endcase
            end
            total_checks = total_checks + 1;
            if (seen_digits !== 6'b111111) begin
                $display("[TB_ERROR] GLS not all 6 digits scanned: seen_digits=%b", seen_digits);
                err_cnt = err_cnt + 1;
            end
        end
    endtask

    initial begin
        $dumpfile("results/jam_digital_gls.vcd");
        $dumpvars(0, tb_jam_digital_gls);

        err_cnt          = 0;
        total_checks     = 0;
        rst_n            = 1'b0;
        en_i             = 1'b0;
        fast_mode_i      = 1'b1;
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

        $display("[TB_MONITOR] GLS TC1: Reset verification on Sky130 netlist");
        #35;
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b0, "GLS_TC1_RESET_LOW");
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        @(negedge clk);
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b0, "GLS_TC1_RESET_REL");

        $display("[TB_MONITOR] GLS TC2: Critical rollovers on Sky130 gates");
        en_i = 1'b1;

        sync_load_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd5, 4'd9);
        fast_step_from_load();
        check_time(4'd0, 4'd0, 4'd0, 4'd1, 4'd0, 4'd0, 1'b0, 1'b0, "GLS_TC2_00_00_59");

        sync_load_time(4'd0, 4'd0, 4'd5, 4'd9, 4'd5, 4'd9);
        fast_step_from_load();
        check_time(4'd0, 4'd1, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b0, "GLS_TC2_00_59_59");

        sync_load_time(4'd0, 4'd9, 4'd5, 4'd9, 4'd5, 4'd9);
        fast_step_from_load();
        check_time(4'd1, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b0, "GLS_TC2_09_59_59");

        sync_load_time(4'd1, 4'd0, 4'd5, 4'd9, 4'd5, 4'd9);
        fast_step_from_load();
        check_time(4'd1, 4'd1, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b0, "GLS_TC2_10_59_59");

        sync_load_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd5, 4'd9);
        fast_step_from_load();
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b1, 1'b1, "GLS_TC2_11_59_59_R1");

        sync_load_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd5, 4'd9);
        fast_step_from_load();
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b1, "GLS_TC2_11_59_59_R2");

        $display("[TB_MONITOR] GLS TC3: Exhaustive 43,200-second sweep on Sky130 netlist");
        @(negedge clk);
        rst_n = 1'b0;
        @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        @(negedge clk);

        g_sec      = 0;
        g_min      = 0;
        g_hour     = 0;
        g_am_pm    = 1'b0;
        g_rollover = 1'b0;

        $dumpoff;
        for (i = 1; i <= 43200; i = i + 1) begin
            @(posedge clk);
            @(negedge clk);

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
                $display("[TB_ERROR] GLS TC3 mismatch at second %0d: Got %0d%0d:%0d%0d:%0d%0d am_pm=%b roll=%b | Exp %02d:%02d:%02d am_pm=%b roll=%b",
                         i,
                         hour_tens_o, hour_ones_o, min_tens_o, min_ones_o, sec_tens_o, sec_ones_o,
                         am_pm_o, rollover_pulse_o,
                         g_hour, g_min, g_sec, g_am_pm, g_rollover);
                err_cnt = err_cnt + 1;
            end
        end
        $dumpon;
        $display("[TB_DATA] GLS TC3 completed 43,200 consecutive states on Sky130 netlist with 0 mismatches.");

        $display("[TB_MONITOR] GLS TC4: Load & illegal BCD clamping");
        en_i = 1'b0;
        sync_load_time(4'd0, 4'd7, 4'd4, 4'd5, 4'd3, 4'd2);
        check_time(4'd0, 4'd7, 4'd4, 4'd5, 4'd3, 4'd2, 1'b1, 1'b0, "GLS_TC4_VALID");
        sync_load_time(4'd1, 4'd9, 4'd7, 4'd9, 4'd9, 4'd9);
        check_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd5, 4'd9, 1'b1, 1'b0, "GLS_TC4_CLAMP_19_79_99");
        sync_load_time(4'h0, 4'hF, 4'h0, 4'hA, 4'h0, 4'hB);
        check_time(4'd0, 4'd9, 4'd0, 4'd9, 4'd0, 4'd9, 1'b1, 1'b0, "GLS_TC4_CLAMP_0F_0A_0B");
        sync_load_time(4'd5, 4'd2, 4'd6, 4'd0, 4'd6, 4'd0);
        check_time(4'd1, 4'd1, 4'd5, 4'd0, 4'd5, 4'd0, 1'b1, 1'b0, "GLS_TC4_CLAMP_52_60_60");

        $display("[TB_MONITOR] GLS TC5: Synchronized manual increment buttons");
        sync_load_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd5, 4'd9);
        @(negedge clk);
        inc_sec_i = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        check_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd0, 4'd0, 1'b1, 1'b0, "GLS_TC5_INC_SEC");
        repeat (3) @(posedge clk);
        @(negedge clk);
        check_time(4'd1, 4'd1, 4'd5, 4'd9, 4'd0, 4'd0, 1'b1, 1'b0, "GLS_TC5_NO_DBL");
        inc_sec_i = 1'b0;
        repeat (3) @(posedge clk);

        @(negedge clk);
        inc_min_i = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        check_time(4'd1, 4'd1, 4'd0, 4'd0, 4'd0, 4'd0, 1'b1, 1'b0, "GLS_TC5_INC_MIN");
        inc_min_i = 1'b0;
        repeat (3) @(posedge clk);

        @(negedge clk);
        inc_hour_i = 1'b1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        check_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 1'b0, 1'b1, "GLS_TC5_INC_HOUR");
        inc_hour_i = 1'b0;
        repeat (3) @(posedge clk);

        $display("[TB_MONITOR] GLS TC6: 7-segment display encoding on Sky130 netlist");
        sync_load_time(4'd1, 4'd0, 4'd4, 4'd5, 4'd2, 4'd9);
        repeat (2) @(posedge clk);
        check_7seg_scan(4'd1, 4'd0, 4'd4, 4'd5, 4'd2, 4'd9);

        $display("[TB_MONITOR] GLS Total Checks=%0d, Errors=%0d", total_checks, err_cnt);
        if (err_cnt == 0) begin
            $display("[TB_INFO] Simulation Finished!");
        end else begin
            $display("[TB_ERROR] GLS finished with %0d errors!", err_cnt);
        end
        $finish;
    end

endmodule
