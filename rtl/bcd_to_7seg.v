// =============================================================================
// Module      : bcd_to_7seg
// Description : Combinational BCD-to-7-segment decoder, active-high output
//               ordered as seg_o = {g, f, e, d, c, b, a}.
// Standard    : Verilog-2001 (Synthesizable)
// =============================================================================

module bcd_to_7seg (
    input  wire [3:0] bcd_i,
    output reg  [6:0] seg_o
);

    always @(*) begin
        case (bcd_i)
            4'd0:    seg_o = 7'b011_1111;
            4'd1:    seg_o = 7'b000_0110;
            4'd2:    seg_o = 7'b101_1011;
            4'd3:    seg_o = 7'b100_1111;
            4'd4:    seg_o = 7'b110_0110;
            4'd5:    seg_o = 7'b110_1101;
            4'd6:    seg_o = 7'b111_1101;
            4'd7:    seg_o = 7'b000_0111;
            4'd8:    seg_o = 7'b111_1111;
            4'd9:    seg_o = 7'b110_1111;
            default: seg_o = 7'b000_0000;
        endcase
    end

endmodule
