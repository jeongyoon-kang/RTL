//==============================================================================
// File name    : case2a_tb.v
// Description  : Case 2A - Blocking assignment before @(posedge clk)
//
// Case Study: Assignment Before Clock Edge - Blocking
//
// This testbench drives input signals using BLOCKING assignments BEFORE
// waiting for the clock edge. Signals change immediately and are stable
// before the clock arrives, ensuring proper setup time.
//
//==============================================================================

`timescale 1ns/1ps

module case2a_tb;

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
// Test Stimulus - Case 2A: BLOCKING before @(posedge clk)
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
    $display("Case 2A: Blocking Assignment Before Clock Edge");
    $display("================================================================");
    $display("Time\t\tEvent");
    $display("----------------------------------------------------------------");

    // Send test data using BLOCKING assignments BEFORE @(posedge clk)
    for (i = 0; i < 5; i = i + 1) begin
        // BLOCKING assignments - occur immediately, BEFORE waiting for clock
        i_valid_tb = 1'b1;
        i_data_tb = test_values[i];
        $display("%0t ns\tAssigned i_data_tb = 0x%h (BLOCKING, before clock)", $time, test_values[i]);
        @(posedge clk);
    end

    // Deassert valid
    i_valid_tb = 1'b0;
    i_data_tb = 32'h0;
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
    $dumpfile("case2a.vcd");
    $dumpvars(0, case2a_tb);
end

endmodule
