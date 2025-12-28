//==============================================================================
// File name    : case3b_tb.v
// Description  : Case 3B - Blocking assignment WITH #0 delay (Inactive Region)
//
// Case Study: Inactive Region - Zero Delay Effect
//
// This testbench drives input signals using BLOCKING assignments WITH
// a #0 delay after @(posedge clk). The #0 delay moves execution to the
// INACTIVE REGION, but still at the SAME simulation time!
//
// IMPORTANT: #0 does NOT avoid race conditions!
// - Execution moves to Inactive Region (same time T)
// - DUT has already sampled inputs in Active Region
// - Race condition STILL EXISTS because execution order is undefined
//
//==============================================================================

`timescale 1ns/1ps

module case3b_tb;

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
// Test Stimulus - Case 3B: BLOCKING with #0 delay (STILL RACE!)
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
    $display("Case 3B: Blocking Assignment WITH #0 Delay (Inactive Region)");
    $display("================================================================");
    $display("Pattern:");
    $display("  @(posedge clk);");
    $display("  #0;              // Zero delay - move to Inactive Region");
    $display("  signal = value;  // Executes at SAME simulation time T!");
    $display("");
    $display("Result: STILL RACE - #0 does NOT avoid race condition!");
    $display("        Inactive Region is still at the same time T");
    $display("================================================================");
    $display("Time\t\tEvent");
    $display("----------------------------------------------------------------");

    // Send test data using BLOCKING assignments WITH #0 delay
    for (i = 0; i < 5; i = i + 1) begin
        @(posedge clk);
        #0;  // Zero delay - moves to Inactive Region (SAME time T!)
        i_valid_tb = 1'b1;
        i_data_tb = test_values[i];
        $display("%0t ns\tAssigned i_data_tb = 0x%h (WITH #0 DELAY - Inactive Region)", $time, test_values[i]);
    end

    // Deassert valid
    @(posedge clk);
    #0;
    i_valid_tb = 1'b0;
    i_data_tb = 32'h0;

    // Wait for pipeline to flush
    repeat(5) @(posedge clk);

    $display("================================================================");
    $display("Simulation completed");
    $display("================================================================");
    $display("WARNING: #0 delay does NOT prevent race conditions!");
    $display("  - #0 moves execution to Inactive Region");
    $display("  - But Inactive Region is still at the SAME simulation time");
    $display("  - DUT may have already sampled old values in Active Region");
    $display("");
    $display("Use non-blocking assignments (<=) or #n (n>0) instead!");
    $display("================================================================");
    $finish;
end

//=============================================================================
// Monitor outputs
//=============================================================================
initial begin
    $display("\nOutput Monitor:");
    $display("Time\t\to_valid\to_data");
    $display("----------------------------------------------------------------");
end

always @(posedge clk) begin
    if (o_valid_tb) begin
        $display("%0t ns\t%b\t0x%h", $time, o_valid_tb, o_data_tb);
    end
end

//=============================================================================
// Waveform Dump
//=============================================================================
initial begin
    $dumpfile("case3b_zero_delay.vcd");
    $dumpvars(0, case3b_tb);
end

endmodule
