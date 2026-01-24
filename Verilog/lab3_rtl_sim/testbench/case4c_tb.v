//==============================================================================
// File name    : case4c_tb.v
// Description  : Case 4C - Using $monitor (Monitor Region, Automatic)
//
// Case Study: Monitor Region - System Task Execution Timing
//
// This testbench demonstrates $monitor which executes in the MONITOR REGION
// and AUTOMATICALLY prints whenever any monitored signal changes.
//
// Key Differences:
//   - $display: Active Region, manual call each time
//   - $strobe: Monitor Region, manual call each time
//   - $monitor: Monitor Region, AUTOMATIC on signal change
//
// Compare with:
//   - Case 4A: $display (executes in Active Region, before NBA)
//   - Case 4B: $strobe (executes in Monitor Region, manual)
//
//==============================================================================

`timescale 1ns/1ps

module case4c_tb;

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
// Monitoring with $monitor - Monitor Region, Automatic
//=============================================================================
initial begin
    $display("================================================================");
    $display("Case 4C: Using $monitor (Monitor Region, Automatic)");
    $display("================================================================");
    $display("Key Points:");
    $display("  - $monitor executes in MONITOR REGION");
    $display("  - Prints values AFTER NBA updates");
    $display("  - AUTOMATICALLY prints when monitored signals change");
    $display("  - Set up ONCE, prints continuously");
    $display("================================================================");
    $display("");

    // Set up $monitor ONCE - it will automatically print on changes
    $monitor("[MONITOR] Time=%0t, i_valid=%b, i_data=%h, r_valid[0]=%b (Monitor Region)",
             $time, i_valid_tb, i_data_tb, u_dut.r_valid[0]);
end

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

    // Send test data using NON-BLOCKING assignments (safe)
    for (i = 0; i < 5; i = i + 1) begin
        @(posedge clk);
        i_valid_tb <= 1'b1;
        i_data_tb <= test_values[i];
        // NO explicit print needed - $monitor automatically prints!
    end

    // Deassert valid
    @(posedge clk);
    i_valid_tb <= 1'b0;
    i_data_tb <= 32'h0;

    // Wait for pipeline to flush
    repeat(5) @(posedge clk);

    $display("");
    $display("================================================================");
    $display("Simulation completed");
    $display("================================================================");
    $display("Notice: $monitor printed automatically on every signal change!");
    $display("================================================================");
    $finish;
end

//=============================================================================
// Waveform Dump
//=============================================================================
initial begin
    $dumpfile("case4c.vcd");
    $dumpvars(0, case4c_tb);
end

endmodule
