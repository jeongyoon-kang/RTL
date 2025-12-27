//==============================================================================
// File name    : case4b_tb.v
// Description  : Case 4B - Non-blocking in always @(posedge clk) - Correct
//
// Case Study: Clocked Always Block - Non-blocking (CORRECT)
//
// This testbench uses a clocked always block with NON-BLOCKING assignments to
// drive input signals. This avoids race conditions because updates are
// scheduled to the NBA region, which occurs after the DUT reads inputs in
// the Active region.
//
//==============================================================================

`timescale 1ns/1ps

module case4b_tb;

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
// Test Stimulus - Case 4B: NON-BLOCKING in clocked always block (CORRECT)
//=============================================================================

// CORRECT: Clocked always block with NON-BLOCKING assignment
// This avoids race conditions with the DUT
always @(posedge clk) begin
    if (!reset_n) begin
        i_valid_tb <= 1'b0;
        i_data_tb <= 32'h0;
        test_count <= 4'h0;
    end
    else begin
        if (test_count < 5) begin
            // NON-BLOCKING assignment scheduled to NBA region
            // DUT reads i_valid in Active region (sees old value)
            // Input updates in NBA region (after DUT read)
            // ORDER IS WELL-DEFINED!
            i_valid_tb <= 1'b1;
            i_data_tb <= test_count + 2;  // 2, 3, 4, 5, 6
            test_count <= test_count + 1;
        end
        else begin
            i_valid_tb <= 1'b0;
            i_data_tb <= 32'h0;
        end
    end
end

//=============================================================================
// Test Control
//=============================================================================
initial begin
    $display("================================================================");
    $display("Case 4B: Non-blocking in Clocked Always Block (CORRECT)");
    $display("================================================================");
    $display("This testbench avoids race conditions!");
    $display("The TB and DUT both use @(posedge clk) triggers.");
    $display("TB uses non-blocking (<=) which schedules to NBA region.");
    $display("DUT reads inputs in Active region (sees old values).");
    $display("TB updates occur in NBA region (after DUT read).");
    $display("The order is WELL-DEFINED by Verilog standard!");
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
// Monitor inputs
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
    $dumpfile("case4b.vcd");
    $dumpvars(0, case4b_tb);
end

endmodule
