// =============================================================================
// Module      : bcd_mod60_counter
// Description : Modulo-60 BCD counter (00..59) with synchronous clamped load
//               and terminal count indicator (is_max_o).
// Standard    : Verilog-2001 (Synthesizable)
// =============================================================================

module bcd_mod60_counter (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       inc_i,
    input  wire       load_en_i,
    input  wire [3:0] load_tens_i,
    input  wire [3:0] load_ones_i,
    output reg  [3:0] tens_o,
    output reg  [3:0] ones_o,
    output wire       is_max_o
);

    wire [3:0] load_tens_clamped;
    wire [3:0] load_ones_clamped;

    assign load_tens_clamped = (load_tens_i > 4'd5) ? 4'd5 : load_tens_i;
    assign load_ones_clamped = (load_ones_i > 4'd9) ? 4'd9 : load_ones_i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tens_o <= 4'd0;
            ones_o <= 4'd0;
        end else if (load_en_i) begin
            tens_o <= load_tens_clamped;
            ones_o <= load_ones_clamped;
        end else if (inc_i) begin
            if ((tens_o == 4'd5) && (ones_o == 4'd9)) begin
                tens_o <= 4'd0;
                ones_o <= 4'd0;
            end else if (ones_o == 4'd9) begin
                tens_o <= tens_o + 4'd1;
                ones_o <= 4'd0;
            end else begin
                ones_o <= ones_o + 4'd1;
            end
        end
    end

    assign is_max_o = (tens_o == 4'd5) && (ones_o == 4'd9);

endmodule
