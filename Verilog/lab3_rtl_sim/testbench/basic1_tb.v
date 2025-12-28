//==============================================================================
// File name    : basic1_tb.v
// Description  : Background Example 1 - @(posedge clk) INSIDE for-loop
//
// This testbench demonstrates @(posedge clk) placement INSIDE the for-loop:
//
//   for (i = 0; i < N; i = i + 1) begin
//       @(posedge clk);      // Wait for clock edge INSIDE loop
//       signal <= value;     // Non-blocking assignment
//   end
//
// Result: Each value is applied on a separate clock cycle (N cycles total)
// This is the CORRECT pattern for driving stimulus to DUT.
//
//==============================================================================

`timescale 1ns/1ps

module basic1_tb;

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
// Test Stimulus - Background Example 1: @(posedge clk) BEFORE assignment
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
    $display("Background Example 1: @(posedge clk) INSIDE for-loop");
    $display("================================================================");
    $display("Pattern:");
    $display("  for (i = 0; i < 5; i = i + 1) begin");
    $display("      @(posedge clk);     // Wait for clock edge INSIDE loop");
    $display("      i_valid_tb <= 1;    // Non-blocking assignment");
    $display("      i_data_tb <= value;");
    $display("  end");
    $display("================================================================");
    $display("Time\t\tEvent");
    $display("----------------------------------------------------------------");

    // Pattern: @(posedge clk) INSIDE for-loop with non-blocking assignment
    for (i = 0; i < 5; i = i + 1) begin
        @(posedge clk);              // Wait for clock edge INSIDE loop
        i_valid_tb <= 1'b1;          // Non-blocking assignment (scheduled to NBA region)
        i_data_tb <= test_values[i];
        $display("%0t ns\tAfter @(posedge clk), assigned i_data_tb = 0x%h", $time, test_values[i]);
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
    $dumpfile("basic1.vcd");
    $dumpvars(0, basic1_tb);
end

endmodule
