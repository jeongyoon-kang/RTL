//==============================================================================
// File name    : basic_tb.v
// Description  : Testbench for power-of-8 module (basic.v)
//
// Author       : [Jeongyoon Kang]
// Email        : [goneki9713@naver.com]
// Date         : 2025-12-13
// Version      : 1.0
//
// History:
//   2025-12-13 - [Jeongyoon Kang] - Initial version
//
// Test Cases:
//   1. Test vector verification using reference input/output files
//
// Notes:
//   - Reads test vectors from ref/input.txt
//   - Compares DUT output with ref/output.txt
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

module basic_tb;

//=============================================================================
// Parameters
//=============================================================================
parameter DATA_WIDTH = 8;
parameter CLK_PERIOD = 10;  // 100MHz clock
parameter NUM_TESTS  = 1000; // Number of test vectors


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
    repeat(20)begin
        @(posedge clk);
    end
    reset_n = 1;
    $display("[%0t] Reset released", $time);
end


//=============================================================================
// DUT Interface Signals
//=============================================================================

// Input Interface
reg                     m_valid_tb;
reg  [DATA_WIDTH-1:0]   m_data_tb;
wire                    m_ready_tb;


// Output Interface
wire                    s_valid_tb;
wire [63:0]             s_data_tb;
reg                     s_ready_tb;

reg [63:0] ref_data;

//=============================================================================
// DUT Instantiation
//=============================================================================
power #(
    .DATA_WIDTH(DATA_WIDTH)
) u_dut (
    .clk        (clk),
    .reset_n    (reset_n),

    .s_valid    (m_valid_tb),
    .s_data     (m_data_tb),
    .s_ready    (m_ready_tb),

    .m_ready    (s_ready_tb),
    .m_valid    (s_valid_tb),
    .m_data     (s_data_tb)
);


//=============================================================================
// Test Control Variables
//=============================================================================
integer test_count;
integer pass_count;
integer fail_count;

//=============================================================================
// Test Vector Storage
//=============================================================================
//
// Test Vector Range: 0 to 255
//
// This power-of-8 module outputs 64-bit results. To prevent overflow in the
// 64-bit output (2^64 - 1 max), the input must satisfy input^8 <= 2^64 - 1.
// Solving for the input gives a maximum value of (2^64 - 1)^(1/8) ≈ 255.
// As a result, all test vectors are generated in the range [0, 255].
//
reg [DATA_WIDTH-1:0] input_vectors  [0:NUM_TESTS-1];
reg [63:0]           output_vectors [0:NUM_TESTS-1];


//=============================================================================
// Load Test Vectors from Files
//=============================================================================
integer input_file, output_file;
integer scan_result;
integer idx;
reg vectors_loaded;
integer handshake_monitor_enable = 0;

initial begin
    vectors_loaded = 0;

    // Read input vectors (decimal format)
    input_file = $fopen("testbench/ref/input.txt", "r");
    if (input_file == 0) begin
        $display("[ERROR] Cannot open input.txt");
        $finish;
    end

    idx = 0;
    while (!$feof(input_file) && idx < NUM_TESTS) begin
        scan_result = $fscanf(input_file, "%d\n", input_vectors[idx]);
        if (scan_result == 1) idx = idx + 1;
    end
    $fclose(input_file);
    $display("[INFO] Loaded %0d input vectors", idx);

    // Read output vectors (decimal format)
    output_file = $fopen("testbench/ref/output.txt", "r");
    if (output_file == 0) begin
        $display("[ERROR] Cannot open output.txt");
        $finish;
    end

    idx = 0;
    while (!$feof(output_file) && idx < NUM_TESTS) begin
        scan_result = $fscanf(output_file, "%d\n", output_vectors[idx]);
        if (scan_result == 1) idx = idx + 1;
    end
    $fclose(output_file);
    $display("[INFO] Loaded %0d output vectors", idx);

    vectors_loaded = 1;
end


//=============================================================================
// Initial Setup
//=============================================================================
initial begin
    // Initialize test counters
    test_count = 0;
    pass_count = 0;
    fail_count = 0;

    // Initialize signals
    m_valid_tb = 0;
    m_data_tb  = 0;
    s_ready_tb = 0;

    // Wait for vectors to be loaded
    wait(vectors_loaded == 1);

    // Wait for reset
    wait(reset_n == 1);
    @(posedge clk);

    // Run test
    test_continuous_flow();

    // Display results
    #(CLK_PERIOD*10);
    display_test_summary();

    $finish;
end


//=============================================================================
// Task: Check Result
//=============================================================================
task check_result;
    input [63:0] expected;
    input [63:0] actual;
    input integer test_id;
    input [DATA_WIDTH-1:0] input_val;
    begin
        test_count = test_count + 1;
        if (expected == actual) begin
            pass_count = pass_count + 1;
            if (test_id % 100 == 0) begin  // Print every 100th test
                $display("[PASS] Test %0d: input=%0d, output=%0d", test_id, input_val, actual);
            end
        end else begin
            fail_count = fail_count + 1;
            $display("[FAIL] Test %0d: input=%0d", test_id, input_val);
            $display("       Expected: %0d (0x%h), Got: %0d (0x%h)", expected, expected, actual, actual);
        end
    end
endtask


//=============================================================================
// Test Case: Continuous Flow Test
//=============================================================================
task test_continuous_flow;
    integer cycle_cnt;
    integer input_idx;
    integer output_idx;
    integer max_cycles;
    begin
        $display("\n========================================");
        $display("  Testing Continuous Data Flow");
        $display("========================================\n");

        handshake_monitor_enable = 1;

        input_idx = 0;
        output_idx = 0;
        max_cycles = 20000;

        // m_valid_tb = 0;
        // m_data_tb = 0;
        // s_ready_tb = 1;

        m_valid_tb <= 0;
        m_data_tb <= 0;
        s_ready_tb <= 1;

        for (cycle_cnt = 0; cycle_cnt < max_cycles; cycle_cnt = cycle_cnt + 1) begin
            // Update input data before clock edge
            if (input_idx < NUM_TESTS) begin
                m_valid_tb <= 1;
                m_data_tb <= input_vectors[input_idx];
            end else begin
                m_valid_tb <= 0;
            end

            @(posedge clk);

            // Check input handshake
            if (m_valid_tb && m_ready_tb && input_idx < NUM_TESTS) begin
                input_idx = input_idx + 1;
            end

            // Check output handshake
            if (s_valid_tb && s_ready_tb && output_idx < NUM_TESTS) begin
                check_result(output_vectors[output_idx], s_data_tb, output_idx, input_vectors[output_idx]);
                ref_data <= output_vectors[output_idx];
                output_idx = output_idx + 1;
            end

            // Exit when done
            if (output_idx >= NUM_TESTS) begin
                break;
            end
        end

        m_valid_tb <= 0;
        s_ready_tb <= 0;

        $display("\n========================================");
        $display("  Test completed in %0d cycles", cycle_cnt);
        $display("  Sent %0d/%0d inputs", input_idx, NUM_TESTS);
        $display("  Received %0d/%0d outputs", output_idx, NUM_TESTS);
        $display("========================================\n");
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
    $dumpfile("basic_tb.vcd");
    $dumpvars(0, basic_tb);
end


//=============================================================================
// Handshake Monitor
//=============================================================================

always @(posedge clk) begin
    if (reset_n && handshake_monitor_enable) begin
        // Monitor input handshake (upstream -> DUT)
        if (m_valid_tb && m_ready_tb) begin
            $display("[%0t] [UPSTREAM->DUT] Handshake OK, Data=%0d accepted by DUT", $time, m_data_tb);
        end else if (m_valid_tb && !m_ready_tb) begin
            $display("[%0t] [UPSTREAM STALL] DUT not ready (m_ready=0), Data=%0d waiting", $time, m_data_tb);
        end

        // Monitor output handshake (DUT -> downstream)
        if (s_valid_tb && s_ready_tb) begin
            $display("[%0t] [DUT->DOWNSTREAM] Handshake OK, Data=%0d accepted by downstream", $time, s_data_tb);
        end else if (s_valid_tb && !s_ready_tb) begin
            $display("[%0t] [DOWNSTREAM STALL] Downstream not ready (s_ready=0), Data=%0d waiting", $time, s_data_tb);
        end
    end
end


//=============================================================================
// Timeout Watchdog
//=============================================================================
// initial begin
//     #(CLK_PERIOD*10000);  // Adjust timeout as needed
//     $display("\n[ERROR] Simulation timeout!");
//     display_test_summary();
//     $finish;
// end


//=============================================================================
// Assertions (SystemVerilog style - comment out if using Verilog)
//=============================================================================
`ifdef SIMULATION
    // Check for X/Z values on critical signals
    always @(posedge clk) begin
        if (reset_n) begin
            if (^s_valid_tb === 1'bx) $display("[WARNING] s_valid_tb has X/Z values at time %0t", $time);
            if (^o_valid === 1'bx) $display("[WARNING] o_valid has X/Z values at time %0t", $time);
        end
    end
`endif

endmodule

`default_nettype wire
