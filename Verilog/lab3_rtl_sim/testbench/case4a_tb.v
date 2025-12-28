//==============================================================================
// File name    : case4a_tb.v
// Description  : Case 4A - Using $display (Active Region)
//
// Case Study: Monitor Region - System Task Execution Timing
//
// This testbench demonstrates $display which executes in the ACTIVE REGION.
// When called at the same time as non-blocking assignments, $display may
// print values BEFORE the NBA region updates occur.
//
// Compare with:
//   - Case 4B: $strobe (executes in Monitor Region, after NBA)
//   - Case 4C: $monitor (executes in Monitor Region, automatic)
//
//==============================================================================

`timescale 1ns/1ps

module case4a_tb;

//=============================================================================
// Parameters
//=============================================================================
parameter DATA_WIDTH = 32;
parameter CLK_PERIOD = 10;

//=============================================================================
// Clock and Reset
//=============================================================================
reg clk;
reg reset_n;

//=============================================================================
// DUT Signals
//=============================================================================
reg                     i_valid_tb;
reg  [DATA_WIDTH-1:0]   i_data_tb;
wire                    o_valid_tb;
wire [63:0]             o_data_tb;

//=============================================================================
// Test Vectors
//=============================================================================
reg [DATA_WIDTH-1:0] test_values [0:4];
integer i;

//=============================================================================
// Clock Generation
//=============================================================================
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

//=============================================================================
// DUT Instantiation
//=============================================================================
power #(
    .DATA_WIDTH(DATA_WIDTH)
) u_dut (
    .clk        (clk),
    .reset_n    (reset_n),
    .i_valid    (i_valid_tb),
    .i_data     (i_data_tb),
    .o_valid    (o_valid_tb),
    .o_data     (o_data_tb)
);

//=============================================================================
// Test Stimulus - Using NON-BLOCKING (safe from race conditions)
//=============================================================================
initial begin
    // Initialize test vectors
    test_values[0] = 32'h00000002;
    test_values[1] = 32'h00000003;
    test_values[2] = 32'h00000005;
    test_values[3] = 32'h00000007;
    test_values[4] = 32'h0000000A;

    // Initialize signals
    i_valid_tb = 1'b0;
    i_data_tb = 32'h0;
    reset_n = 1'b0;

    // Wait for reset
    repeat(2) @(posedge clk);
    reset_n = 1'b1;
    repeat(1) @(posedge clk);

    $display("================================================================");
    $display("Case 4A: Using $display (Active Region)");
    $display("================================================================");
    $display("Key Point:");
    $display("  - $display executes in ACTIVE REGION");
    $display("  - Prints values BEFORE NBA updates");
    $display("  - May show 'old' values for non-blocking assignments");
    $display("================================================================");

    // Send test data using NON-BLOCKING assignments (safe)
    for (i = 0; i < 5; i = i + 1) begin
        @(posedge clk);
        i_valid_tb <= 1'b1;
        i_data_tb <= test_values[i];
    end

    // Deassert valid
    @(posedge clk);
    i_valid_tb <= 1'b0;
    i_data_tb <= 32'h0;

    // Wait for pipeline to flush
    repeat(5) @(posedge clk);

    $display("================================================================");
    $display("Simulation completed");
    $display("================================================================");
    $finish;
end

//=============================================================================
// Monitoring with $display - Active Region
//=============================================================================
always @(posedge clk) begin
    // $display executes in ACTIVE region
    // It may print BEFORE non-blocking assignments update in NBA region
    $display("[DISPLAY] Time=%0t, i_valid=%b, r_valid[0]=%b (Active Region)",
             $time, i_valid_tb, u_dut.r_valid[0]);
end

//=============================================================================
// Waveform Dump
//=============================================================================
initial begin
    $dumpfile("case4a.vcd");
    $dumpvars(0, case4a_tb);
end

endmodule
