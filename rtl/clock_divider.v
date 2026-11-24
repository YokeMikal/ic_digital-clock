// =============================================================================
// Module      : clock_divider
// Description : Synchronous clock-enable prescaler generating 1 Hz timebase
//               and display multiplexing scan ticks, with fast_mode_i bypass
//               for exhaustive simulation and gate-level verification.
// Standard    : Verilog-2001 (Synthesizable)
// =============================================================================

module clock_divider #(
    parameter integer CLK_FREQ_HZ = 50000000,
    parameter integer SCAN_DIV    = 50000
) (
    input  wire clk,
    input  wire rst_n,
    input  wire en_i,
    input  wire fast_mode_i,
    input  wire clr_prescaler_i,
    output reg  tick_1hz_o,
    output reg  tick_scan_o
);

    localparam integer SEC_CNT_W  = 26;
    localparam integer SCAN_CNT_W = 16;

    localparam [31:0] SEC_MAX_32  = CLK_FREQ_HZ - 1;
    localparam [31:0] SCAN_MAX_32 = SCAN_DIV - 1;

    localparam [SEC_CNT_W-1:0]  SEC_MAX  = SEC_MAX_32[SEC_CNT_W-1:0];
    localparam [SCAN_CNT_W-1:0] SCAN_MAX = SCAN_MAX_32[SCAN_CNT_W-1:0];

    localparam [SEC_CNT_W-1:0]  SEC_ZERO  = {SEC_CNT_W{1'b0}};
    localparam [SEC_CNT_W-1:0]  SEC_ONE   = {{(SEC_CNT_W-1){1'b0}}, 1'b1};
    localparam [SCAN_CNT_W-1:0] SCAN_ZERO = {SCAN_CNT_W{1'b0}};
    localparam [SCAN_CNT_W-1:0] SCAN_ONE  = {{(SCAN_CNT_W-1){1'b0}}, 1'b1};

    reg [SEC_CNT_W-1:0]  sec_cnt;
    reg [SCAN_CNT_W-1:0] scan_cnt;

    // 1 Hz timebase prescaler (registered tick output)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sec_cnt    <= SEC_ZERO;
            tick_1hz_o <= 1'b0;
        end else if (clr_prescaler_i) begin
            sec_cnt    <= SEC_ZERO;
            tick_1hz_o <= 1'b0;
        end else if (fast_mode_i) begin
            sec_cnt    <= SEC_ZERO;
            tick_1hz_o <= en_i;
        end else if (en_i) begin
            if (sec_cnt == SEC_MAX) begin
                sec_cnt    <= SEC_ZERO;
                tick_1hz_o <= 1'b1;
            end else begin
                sec_cnt    <= sec_cnt + SEC_ONE;
                tick_1hz_o <= 1'b0;
            end
        end else begin
            tick_1hz_o <= 1'b0;
        end
    end

    // 7-segment display multiplex scan tick generator
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scan_cnt    <= SCAN_ZERO;
            tick_scan_o <= 1'b0;
        end else if (fast_mode_i) begin
            scan_cnt    <= SCAN_ZERO;
            tick_scan_o <= 1'b1;
        end else if (scan_cnt == SCAN_MAX) begin
            scan_cnt    <= SCAN_ZERO;
            tick_scan_o <= 1'b1;
        end else begin
            scan_cnt    <= scan_cnt + SCAN_ONE;
            tick_scan_o <= 1'b0;
        end
    end

endmodule
