//==============================================================================
// File name    : basic.v
// Description  : [Brief description of what this module does]
//
// Author       : [Jeongyoon Kang]
// Email        : [goneki9713@naver.com]
// Date         : 2025-12-13
// Version      : 1.0
//
// History:
//   2025-12-13 - [Jeongyoon Kang] - Initial version: Simple Vaild interface example
//
// Parameters:
//   PARAM_NAME  - [Description]
//
// Notes:
//   - [Any important notes about this module]
//   - [Design decisions, limitations, or usage guidelines]
//==============================================================================

`timescale 1ns/1ps
`default_nettype none

module module_name #(
    parameter DATA_WIDTH = 32
)(
    // Clock and Reset
    input  wire                     clk,
    input  wire                     reset_n,

    // Input Interface
    input  wire                     i_valid,
    input  wire  [DATA_WIDTH-1:0]   i_data,

    // Output Interface
    output wire                     o_valid,
    output wire  [63:0]   o_data
);

//🟩: Stage
//🟧: Combinational logic
//🟦: Sequential logic


//=============================================================================
// Internal Signal Declarations
//=============================================================================

//-----------------------------------------------------------------------------
// 🟩Stage 0
//-----------------------------------------------------------------------------
// 🟧Combinational signals (intermediate values, NOT registers)

    wire power_of_2;

// 🟦Sequential signals (actual flip-flops)

    reg [2:0] r_valid;
    reg [63:0] r_power_of_2;

//-----------------------------------------------------------------------------
// 🟩Stage 1
//-----------------------------------------------------------------------------
// 🟧Combinational signals (intermediate values, NOT registers)

    wire power_of_4;

// 🟦Sequential signals (actual flip-flops)

    // reg [2:0] r_valid;
    reg [63:0] r_power_of_4;

//-----------------------------------------------------------------------------
// 🟩Stage 2
//-----------------------------------------------------------------------------
// 🟧Combinational signals (intermediate values, NOT registers)

    wire power_of_8;

// 🟦Sequential signals (actual flip-flops)

    // reg [2:0] r_valid;
    reg [63:0] r_power_of_8;



//=============================================================================
// 🟧Combinational Logic
//=============================================================================

// 🟩Stage 0

    assign power_of_2 = i_data * i_data;


// 🟩Stage 1

    assign power_of_4 = r_power_of_2 * r_power_of_2;


// 🟩Stage 2

    assign power_of_8 = r_power_of_8 * r_power_of_8;


//=============================================================================
// 🟦Sequential Logic (Registers)
//=============================================================================

// 🟩Stage 0

    //
    always@(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            r_valid[0] <= 1'b0; 
        end 
        else begin
            r_valid[0] <= i_valid;
        end
    end

    always@(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            r_power_of_2 <= 'b0;
        end
        else begin
            r_power_of_2 <= power_of_2;
        end
    end


// 🟩Stage 1

    always@(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            r_valid[1] <= 1'b0;
        end
        else begin
            r_valid[1] <= r_valid[0];
        end
    end

    always@(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            r_power_of_4 <= 'b0;
        end
        else begin
            r_power_of_4 <= power_of_4;
        end
    end


// 🟩Stage 2

    always@(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            r_valid[2] <= 1'b0;
        end
        else begin
            r_valid[2] <= r_valid[1];
        end
    end

    always@(posedge clk or negedge reset_n)begin
        if(!reset_n)begin
            r_power_of_8 <= 'b0;
        end
        else begin
            r_power_of_8 <= power_of_8;
        end
    end



//=============================================================================
// Output Assign(Must be registered output!)
//=============================================================================

    assign o_valid = r_valid[2];
    assign o_data = r_power_of_8;


//=============================================================================
// Assertions (for simulation/formal verification)
//=============================================================================
`ifdef FORMAL
    // Add formal properties here
`endif

`ifdef SIMULATION
    // Add simulation assertions here
`endif

endmodule

`default_nettype wire
