//==============================================================================
// File name    : case3c_tb.v
// Description  : Case 3C - Blocking assignment WITH #1 time delay (SAFE)
//
// Case Study: Time Delay Effect - Different Simulation Time
//
// This testbench drives input signals using BLOCKING assignments WITH
// a #1 delay after @(posedge clk). The #1 delay moves the assignment to
// a DIFFERENT simulation time (T+1ns), completely avoiding race conditions.
//
// IMPORTANT: #1 (or any #n where n > 0) DOES avoid race conditions!
// - Execution moves to time T+1ns (different from clock edge at time T)
// - DUT samples inputs at time T, TB updates at T+1ns
// - No overlap = NO RACE CONDITION
//
// However, non-blocking assignments are still the preferred solution
// as they are more idiomatic and self-documenting.
//
//==============================================================================

`timescale 1ns/1ps

module case3c_tb;

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
// Test Stimulus - Case 3C: BLOCKING with #1 delay (RACE-FREE)
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
    $display("Case 3C: Blocking Assignment WITH #1 Time Delay (SAFE)");
    $display("================================================================");
    $display("Pattern:");
    $display("  @(posedge clk);");
    $display("  #1;              // Real time delay - move to T+1ns");
    $display("  signal = value;  // Executes at DIFFERENT simulation time");
    $display("");
    $display("Result: NO RACE - TB updates at T+1, DUT samples at T");
    $display("        Different simulation time = no race condition");
    $display("================================================================");
    $display("Time\t\tEvent");
    $display("----------------------------------------------------------------");

    // Send test data using BLOCKING assignments WITH #1 delay
    for (i = 0; i < 5; i = i + 1) begin
        @(posedge clk);
        #1;  // CRITICAL: Real time delay moves to T+1ns (different time!)
        i_valid_tb = 1'b1;
        i_data_tb = test_values[i];
        $display("%0t ns\tAssigned i_data_tb = 0x%h (WITH #1 DELAY - T+1ns)", $time, test_values[i]);
    end

    // Deassert valid
    @(posedge clk);
    #1;
    i_valid_tb = 1'b0;
    i_data_tb = 32'h0;

    // Wait for pipeline to flush
    repeat(5) @(posedge clk);

    $display("================================================================");
    $display("Simulation completed");
    $display("================================================================");
    $display("SUCCESS: #1 delay prevents race conditions!");
    $display("  - Clock edge occurs at time T (e.g., 30ns, 40ns, ...)");
    $display("  - TB updates at time T+1 (e.g., 31ns, 41ns, ...)");
    $display("  - DUT samples PREVIOUS value at T, sees NEW value at T+1");
    $display("");
    $display("Note: While this works, non-blocking (<=) is still preferred");
    $display("      for better code clarity and maintainability.");
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
    $dumpfile("case3c_time_delay.vcd");
    $dumpvars(0, case3c_tb);
end

endmodule
