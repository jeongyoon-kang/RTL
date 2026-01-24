//==============================================================================
// File name    : case1b_tb.v
// Description  : Case 1B - Non-blocking assignment after @(posedge clk)
//
// Case Study: Assignment After Clock Edge - Non-blocking
//
// This testbench drives input signals using NON-BLOCKING assignments immediately
// after waiting for the clock edge. The assignments are scheduled to the NBA
// region of the delta cycle, occurring after the DUT reads the input values.
//
//==============================================================================

`timescale 1ns/1ps

module case1b_tb;

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
// Test Stimulus - Case 1B: NON-BLOCKING after @(posedge clk)
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
    $display("Case 1B: Non-blocking Assignment After Clock Edge");
    $display("================================================================");
    $display("Time\t\tEvent");
    $display("----------------------------------------------------------------");

    // Send test data using NON-BLOCKING assignments AFTER @(posedge clk)
    for (i = 0; i < 5; i = i + 1) begin
        @(posedge clk);
        // NON-BLOCKING assignments - scheduled to NBA region
        i_valid_tb <= 1'b1;
        i_data_tb <= test_values[i];
        $display("%0t ns\tScheduled i_data_tb = 0x%h (NON-BLOCKING)", $time, test_values[i]);
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
    $dumpfile("case1b.vcd");
    $dumpvars(0, case1b_tb);
end

endmodule
