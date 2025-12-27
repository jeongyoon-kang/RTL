//==============================================================================
// File name    : case4a_tb.v
// Description  : Case 4A - Blocking in always @(posedge clk) - Race Condition
//
// Case Study: Clocked Always Block - Blocking (DANGEROUS!)
//
// This testbench uses a clocked always block with BLOCKING assignments to
// drive input signals. This creates a RACE CONDITION because both the TB
// and DUT trigger on the same clock edge, and the order of execution in
// the Active region is undefined.
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
// Test Control
//=============================================================================
reg [3:0] test_count;

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
// Test Stimulus - Case 4A: BLOCKING in clocked always block (RACE!)
//=============================================================================

// DANGEROUS: Clocked always block with BLOCKING assignment
// This creates a race condition with the DUT!
always @(posedge clk) begin
    if (!reset_n) begin
        i_valid_tb = 1'b0;
        i_data_tb = 32'h0;
        test_count = 4'h0;
    end
    else begin
        if (test_count < 5) begin
            // BLOCKING assignment in Active region
            // DUT also reads i_valid in Active region
            // ORDER IS UNDEFINED!
            i_valid_tb = 1'b1;
            i_data_tb = test_count + 2;  // 2, 3, 4, 5, 6
            test_count = test_count + 1;
        end
        else begin
            i_valid_tb = 1'b0;
            i_data_tb = 32'h0;
        end
    end
end

//=============================================================================
// Test Control
//=============================================================================
initial begin
    $display("================================================================");
    $display("Case 4A: Blocking in Clocked Always Block (RACE CONDITION)");
    $display("================================================================");
    $display("WARNING: This testbench has a race condition!");
    $display("The TB and DUT both use @(posedge clk) triggers.");
    $display("TB uses blocking (=) which executes in Active region.");
    $display("DUT reads inputs in Active region.");
    $display("The order is UNDEFINED by Verilog standard!");
    $display("================================================================");
    $display("Time\t\tEvent");
    $display("----------------------------------------------------------------");

    reset_n = 1'b0;
    repeat(2) @(posedge clk);
    reset_n = 1'b1;

    // Wait for test to complete
    wait(test_count >= 5);
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
// Monitor inputs to see race condition effects
//=============================================================================
always @(posedge clk) begin
    #1;  // Small delay to observe the settled values
    if (i_valid_tb) begin
        $display("%0t ns\tInput: i_valid_tb=%b, i_data_tb=0x%h", $time-1, i_valid_tb, i_data_tb);
    end
end

//=============================================================================
// Waveform Dump
//=============================================================================
initial begin
    $dumpfile("case4a.vcd");
    $dumpvars(0, case4a_tb);
end

endmodule
