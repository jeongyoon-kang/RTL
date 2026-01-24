//==============================================================================
// File name    : case3a_tb.v
// Description  : Case 3A - Blocking assignment without time delay
//
// Case Study: Time Delay Effect on Race Conditions
//
// This testbench drives input signals using BLOCKING assignments immediately
// after @(posedge clk). This creates a race condition with the DUT as both
// execute in the Active region at the same simulation time.
//
// Compare with Case 3B which uses #1 delay to move assignment to next
// simulation time, avoiding the race condition.
//
//==============================================================================

`timescale 1ns/1ps

module case3a_tb;

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
// Test Stimulus - Case 3A: BLOCKING without delay (RACE CONDITION)
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
    $display("Case 3A: Blocking Assignment WITHOUT Time Delay");
    $display("================================================================");
    $display("Pattern:");
    $display("  @(posedge clk);");
    $display("  signal = value;  // NO DELAY - executes in Active Region");
    $display("");
    $display("Result: RACE CONDITION with DUT!");
    $display("================================================================");
    $display("Time\t\tEvent");
    $display("----------------------------------------------------------------");

    // Send test data using BLOCKING assignments WITHOUT delay
    for (i = 0; i < 5; i = i + 1) begin
        @(posedge clk);
        // NO DELAY - executes in Active Region, same as DUT!
        i_valid_tb = 1'b1;
        i_data_tb = test_values[i];
        $display("%0t ns\tAssigned i_data_tb = 0x%h (NO DELAY, Active Region)", $time, test_values[i]);
    end

    // Deassert valid
    @(posedge clk);
    i_valid_tb = 1'b0;
    i_data_tb = 32'h0;

    // Wait for pipeline to flush
    repeat(5) @(posedge clk);

    $display("================================================================");
    $display("Simulation completed");
    $display("================================================================");
    $display("NOTE: Race condition present - behavior is simulator-dependent!");
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
    $dumpfile("case3a.vcd");
    $dumpvars(0, case3a_tb);
end

endmodule
