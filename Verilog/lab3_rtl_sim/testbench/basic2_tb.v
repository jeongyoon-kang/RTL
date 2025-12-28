//==============================================================================
// File name    : basic2_tb.v
// Description  : Background Example 2 - @(posedge clk) OUTSIDE for-loop
//
// This testbench demonstrates @(posedge clk) placement OUTSIDE the for-loop:
//
//   for (i = 0; i < N; i = i + 1) begin
//       signal <= value;    // Non-blocking assignment
//   end
//   @(posedge clk);         // Wait for clock edge OUTSIDE loop (after loop)
//
// Result: Loop completes in ZERO time, only LAST value is captured!
// This is a COMMON BUG - only ONE clock cycle regardless of N iterations.
//
//==============================================================================

`timescale 1ns/1ps

module basic2_tb;

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
// Test Stimulus - Background Example 2: Assignment BEFORE @(posedge clk)
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
    $display("Background Example 2: @(posedge clk) OUTSIDE for-loop");
    $display("================================================================");
    $display("Pattern:");
    $display("  for (i = 0; i < 5; i = i + 1) begin");
    $display("      i_valid_tb <= 1;    // Non-blocking assignment");
    $display("      i_data_tb <= value; // Loop runs in ZERO time!");
    $display("  end");
    $display("  @(posedge clk);         // Wait OUTSIDE loop - only LAST value seen!");
    $display("================================================================");
    $display("WARNING: Only the LAST value (test_values[4]) will be captured!");
    $display("================================================================");
    $display("Time\t\tEvent");
    $display("----------------------------------------------------------------");

    // Pattern: @(posedge clk) OUTSIDE for-loop (COMMON BUG!)
    for (i = 0; i < 5; i = i + 1) begin
        i_valid_tb <= 1'b1;          // Non-blocking assignment
        i_data_tb <= test_values[i]; // Loop runs in ZERO simulation time!
        $display("%0t ns\tAssigned i_data_tb <= 0x%h (loop iteration %0d)", $time, test_values[i], i);
    end
    $display("%0t ns\tLoop finished - now waiting for @(posedge clk)", $time);
    @(posedge clk);                  // Wait OUTSIDE loop - only LAST value captured!
    $display("%0t ns\tAfter @(posedge clk) - DUT only sees LAST value!", $time);

    // Deassert valid
    i_valid_tb <= 1'b0;
    i_data_tb <= 32'h0;
    @(posedge clk);

    // Wait for pipeline to flush
    repeat(5) @(posedge clk);

    $display("================================================================");
    $display("Simulation completed");
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
    $dumpfile("basic2.vcd");
    $dumpvars(0, basic2_tb);
end

endmodule
