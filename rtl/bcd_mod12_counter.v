// =============================================================================
// Module      : bcd_mod12_counter
// Description : Modulo-12 BCD counter (00..11) with synchronous clamped load,
//               AM/PM toggle output, and 1-cycle rollover_pulse_o on 11->00.
// Standard    : Verilog-2001 (Synthesizable)
// =============================================================================

module bcd_mod12_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       inc_i,
    input  wire       load_en_i,
    input  wire [3:0] load_tens_i,
    input  wire [3:0] load_ones_i,
    output reg  [3:0] tens_o,
    output reg  [3:0] ones_o,
    output reg        am_pm_o,
    output reg        rollover_pulse_o
);

    wire [3:0] load_tens_clamped;
    wire [3:0] load_ones_clamped;

    assign load_tens_clamped = (load_tens_i >= 4'd1) ? 4'd1 : 4'd0;
    assign load_ones_clamped = (load_tens_i >= 4'd1)
                               ? ((load_ones_i > 4'd1) ? 4'd1 : load_ones_i)
                               : ((load_ones_i > 4'd9) ? 4'd9 : load_ones_i);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tens_o           <= 4'd0;
            ones_o           <= 4'd0;
            am_pm_o          <= 1'b0;
            rollover_pulse_o <= 1'b0;
        end else if (load_en_i) begin
            tens_o           <= load_tens_clamped;
            ones_o           <= load_ones_clamped;
            rollover_pulse_o <= 1'b0;
        end else if (inc_i) begin
            if ((tens_o == 4'd1) && (ones_o == 4'd1)) begin
                tens_o           <= 4'd0;
                ones_o           <= 4'd0;
                am_pm_o          <= ~am_pm_o;
                rollover_pulse_o <= 1'b1;
            end else if ((tens_o == 4'd0) && (ones_o == 4'd9)) begin
                tens_o           <= 4'd1;
                ones_o           <= 4'd0;
                rollover_pulse_o <= 1'b0;
            end else begin
                ones_o           <= ones_o + 4'd1;
                rollover_pulse_o <= 1'b0;
            end
        end else begin
            rollover_pulse_o <= 1'b0;
        end
    end

endmodule
