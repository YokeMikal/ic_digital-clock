// =============================================================================
// Module      : seven_seg_mux6
// Description : Glitch-free registered 6-digit time-multiplexed 7-segment
//               display driver. digit_sel_o[0] = sec_ones .. [5] = hour_tens.
// Standard    : Verilog-2001 (Synthesizable)
// =============================================================================

module seven_seg_mux6 (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tick_scan_i,
    input  wire [3:0] sec_ones_i,
    input  wire [3:0] sec_tens_i,
    input  wire [3:0] min_ones_i,
    input  wire [3:0] min_tens_i,
    input  wire [3:0] hour_ones_i,
    input  wire [3:0] hour_tens_i,
    output reg  [6:0] seg_o,
    output reg  [5:0] digit_sel_o
);

    reg  [2:0] digit_idx;
    reg  [3:0] cur_bcd;
    reg  [5:0] next_digit_sel;
    wire [6:0] decoded_seg;

    always @(*) begin
        case (digit_idx)
            3'd0: begin
                cur_bcd        = sec_ones_i;
                next_digit_sel = 6'b000_001;
            end
            3'd1: begin
                cur_bcd        = sec_tens_i;
                next_digit_sel = 6'b000_010;
            end
            3'd2: begin
                cur_bcd        = min_ones_i;
                next_digit_sel = 6'b000_100;
            end
            3'd3: begin
                cur_bcd        = min_tens_i;
                next_digit_sel = 6'b001_000;
            end
            3'd4: begin
                cur_bcd        = hour_ones_i;
                next_digit_sel = 6'b010_000;
            end
            3'd5: begin
                cur_bcd        = hour_tens_i;
                next_digit_sel = 6'b100_000;
            end
            default: begin
                cur_bcd        = 4'd0;
                next_digit_sel = 6'b000_001;
            end
        endcase
    end

    bcd_to_7seg u_bcd_to_7seg (
        .bcd_i (cur_bcd),
        .seg_o (decoded_seg)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            digit_idx   <= 3'd0;
            seg_o       <= 7'b011_1111;
            digit_sel_o <= 6'b000_001;
        end else begin
            seg_o       <= decoded_seg;
            digit_sel_o <= next_digit_sel;
            if (tick_scan_i) begin
                if (digit_idx == 3'd5) begin
                    digit_idx <= 3'd0;
                end else begin
                    digit_idx <= digit_idx + 3'd1;
                end
            end
        end
    end

endmodule
