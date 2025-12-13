//==============================================================================
// File name    : tb_module_name.v
// Description  : Testbench for module_name
//
// Author       : [Your Name]
// Email        : [your.email@example.com]
// Date         : YYYY-MM-DD
// Version      : 1.0
//
// History:
//   YYYY-MM-DD - [Author] - Initial version
//   YYYY-MM-DD - [Author] - [Change description]
//
// Test Cases:
//   1. Basic functionality test
//   2. Edge case testing
//   3. Reset behavior verification
//   4. Back-pressure handling (if applicable)
//
// Notes:
//   - [Any important notes about this testbench]
//   - [Coverage goals, known issues, or limitations]
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

module tb_module_name;

//=============================================================================
// Parameters
//=============================================================================
parameter DATA_WIDTH = 32;
parameter CLK_PERIOD = 10;  // 100MHz clock


//=============================================================================
// Clock and Reset Generation
//=============================================================================
reg clk;
reg reset_n;

// Clock generation
initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// Reset generation
initial begin
    reset_n = 0;
    #(CLK_PERIOD*5);
    reset_n = 1;
    $display("[%0t] Reset released", $time);
end


//=============================================================================
// DUT Interface Signals
//=============================================================================

// Input Interface
reg                     i_valid;
reg  [DATA_WIDTH-1:0]   i_data;
wire                    i_ready;

// Output Interface
wire                    o_valid;
wire [DATA_WIDTH-1:0]   o_data;
reg                     o_ready;


//=============================================================================
// DUT Instantiation
//=============================================================================
module_name #(
    .DATA_WIDTH(DATA_WIDTH)
) u_dut (
    .clk        (clk),
    .reset_n    (reset_n),

    .i_valid    (i_valid),
    .i_data     (i_data),
    .i_ready    (i_ready),

    .o_valid    (o_valid),
    .o_data     (o_data),
    .o_ready    (o_ready)
);


//=============================================================================
// Test Control Variables
//=============================================================================
integer test_count;
integer pass_count;
integer fail_count;


//=============================================================================
// Initial Setup
//=============================================================================
initial begin
    // Initialize test counters
    test_count = 0;
    pass_count = 0;
    fail_count = 0;

    // Initialize signals
    i_valid = 0;
    i_data  = 0;
    o_ready = 0;

    // Wait for reset
    wait(reset_n == 1);
    @(posedge clk);

    // Run test cases
    test_basic_functionality();
    test_back_pressure();
    test_edge_cases();

    // Display results
    #(CLK_PERIOD*10);
    display_test_summary();

    $finish;
end


//=============================================================================
// Task: Send Data
//=============================================================================
task send_data;
    input [DATA_WIDTH-1:0] data;
    begin
        @(posedge clk);
        i_valid = 1;
        i_data  = data;

        // Wait for handshake
        while (!i_ready) begin
            @(posedge clk);
        end

        @(posedge clk);
        i_valid = 0;
        i_data  = 0;

        $display("[%0t] Sent data: 0x%h", $time, data);
    end
endtask


//=============================================================================
// Task: Receive Data
//=============================================================================
task receive_data;
    output [DATA_WIDTH-1:0] data;
    begin
        o_ready = 1;

        // Wait for valid output
        while (!o_valid) begin
            @(posedge clk);
        end

        data = o_data;
        @(posedge clk);
        o_ready = 0;

        $display("[%0t] Received data: 0x%h", $time, data);
    end
endtask


//=============================================================================
// Task: Check Result
//=============================================================================
task check_result;
    input [DATA_WIDTH-1:0] expected;
    input [DATA_WIDTH-1:0] actual;
    input [256*8-1:0] test_name;  // String parameter
    begin
        test_count = test_count + 1;
        if (expected == actual) begin
            pass_count = pass_count + 1;
            $display("[PASS] Test %0d: %s", test_count, test_name);
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] Test %0d: %s", test_count, test_name);
            $display("       Expected: 0x%h, Got: 0x%h", expected, actual);
        end
    end
endtask


//=============================================================================
// Test Case 1: Basic Functionality
//=============================================================================
task test_basic_functionality;
    reg [DATA_WIDTH-1:0] received_data;
    begin
        $display("\n=== Test 1: Basic Functionality ===");

        // Enable receiver
        o_ready = 1;

        // Send test data
        send_data(32'hDEADBEEF);

        // Wait for output
        @(posedge clk);
        while (!o_valid) @(posedge clk);

        received_data = o_data;

        // Check result (modify expected value based on your module's function)
        check_result(32'hDEADBEEF, received_data, "Basic data transfer");

        o_ready = 0;
        repeat(5) @(posedge clk);
    end
endtask


//=============================================================================
// Test Case 2: Back Pressure Handling
//=============================================================================
task test_back_pressure;
    integer i;
    begin
        $display("\n=== Test 2: Back Pressure Handling ===");

        // Set o_ready to 0 (apply back pressure)
        o_ready = 0;

        // Try to send data
        fork
            begin
                send_data(32'h12345678);
            end
            begin
                // Release back pressure after some delay
                repeat(10) @(posedge clk);
                o_ready = 1;
                $display("[%0t] Back pressure released", $time);
            end
        join

        // Verify data was received correctly
        @(posedge clk);
        while (!o_valid) @(posedge clk);

        check_result(32'h12345678, o_data, "Back pressure handling");

        o_ready = 0;
        repeat(5) @(posedge clk);
    end
endtask


//=============================================================================
// Test Case 3: Edge Cases
//=============================================================================
task test_edge_cases;
    reg [DATA_WIDTH-1:0] test_vectors [0:3];
    reg [DATA_WIDTH-1:0] received_data;
    integer i;
    begin
        $display("\n=== Test 3: Edge Cases ===");

        // Define test vectors
        test_vectors[0] = {DATA_WIDTH{1'b0}};  // All zeros
        test_vectors[1] = {DATA_WIDTH{1'b1}};  // All ones
        test_vectors[2] = {{(DATA_WIDTH/2){1'b0}}, {(DATA_WIDTH/2){1'b1}}};  // Pattern
        test_vectors[3] = {{(DATA_WIDTH/2){1'b1}}, {(DATA_WIDTH/2){1'b0}}};  // Inverse pattern

        o_ready = 1;

        for (i = 0; i < 4; i = i + 1) begin
            send_data(test_vectors[i]);

            @(posedge clk);
            while (!o_valid) @(posedge clk);

            received_data = o_data;
            check_result(test_vectors[i], received_data, "Edge case pattern");

            repeat(2) @(posedge clk);
        end

        o_ready = 0;
    end
endtask


//=============================================================================
// Display Test Summary
//=============================================================================
task display_test_summary;
    begin
        $display("\n");
        $display("========================================");
        $display("       TEST SUMMARY");
        $display("========================================");
        $display("Total Tests : %0d", test_count);
        $display("Passed      : %0d", pass_count);
        $display("Failed      : %0d", fail_count);
        $display("========================================");

        if (fail_count == 0) begin
            $display("✓ ALL TESTS PASSED!");
        end else begin
            $display("✗ SOME TESTS FAILED!");
        end
        $display("========================================\n");
    end
endtask


//=============================================================================
// Waveform Dump (for GTKWave, Verdi, etc.)
//=============================================================================
initial begin
    $dumpfile("tb_module_name.vcd");
    $dumpvars(0, tb_module_name);
end


//=============================================================================
// Timeout Watchdog
//=============================================================================
initial begin
    #(CLK_PERIOD*10000);  // Adjust timeout as needed
    $display("\n[ERROR] Simulation timeout!");
    display_test_summary();
    $finish;
end


//=============================================================================
// Assertions (SystemVerilog style - comment out if using Verilog)
//=============================================================================
`ifdef SIMULATION
    // Check for X/Z values on critical signals
    always @(posedge clk) begin
        if (reset_n) begin
            if (^i_valid === 1'bx) $display("[WARNING] i_valid has X/Z values at time %0t", $time);
            if (^o_valid === 1'bx) $display("[WARNING] o_valid has X/Z values at time %0t", $time);
        end
    end
`endif

endmodule

`default_nettype wire
