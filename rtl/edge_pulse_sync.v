// =============================================================================
// Module      : edge_pulse_sync
// Description : 2-FF metastability synchronizer followed by single-cycle
//               rising-edge pulse detector for asynchronous button inputs.
// Standard    : Verilog-2001 (Synthesizable)
// =============================================================================

module edge_pulse_sync #(
    parameter integer WIDTH = 3
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] async_i,
    output wire [WIDTH-1:0] pulse_o
);

    reg [WIDTH-1:0] sync_ff1;
    reg [WIDTH-1:0] sync_ff2;
    reg [WIDTH-1:0] prev_ff;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= {WIDTH{1'b0}};
            sync_ff2 <= {WIDTH{1'b0}};
            prev_ff  <= {WIDTH{1'b0}};
        end else begin
            sync_ff1 <= async_i;
            sync_ff2 <= sync_ff1;
            prev_ff  <= sync_ff2;
        end
    end

    assign pulse_o = sync_ff2 & ~prev_ff;

endmodule
