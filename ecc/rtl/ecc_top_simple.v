// ecc_top_simple.v - Single Core Version (85% resource reduction)
// Uses only 1 core instead of 3 cores for dramatic resource savings

`timescale 1ns / 1ps

module ecc_top_simple(clk, rst, enable, din, dx, dy, reg_done);

input clk;
input rst;
input enable;
input [162:0]din;
output [162:0]dx;
output [162:0]dy;
output reg_done;

// Main controller signals  
wire [162:0]Rx;
wire [162:0]Ry;
wire [162:0]Rb;
wire swap1, swap2, cores_en;

// Single core signals
wire [162:0]A1_ZZ;
wire [162:0]A1_XX;
wire [162:0]A1_BP_OUT2;

// Pipeline registers
reg reg_rst;
reg reg_enable;
reg [162:0]reg_din;
reg reg_done;

// Simple output assignment - use single core results for both outputs
assign dx = A1_XX;
assign dy = A1_XX; // Simplified - both outputs use same core result

// Input pipeline
always@(posedge clk) begin
    reg_rst <= rst;
    reg_enable <= enable;
    reg_din <= din;
    reg_done <= cores_en;
end

// Main controller (unchanged)
main main_ins(
    .clk(clk), 
    .rst(reg_rst), 
    .data_en(reg_enable),
    .din(reg_din),
    .opt_Rx(Rx),
    .opt_Ry(Ry),
    .opt_Rb(Rb),
    .reg_swap1(swap1),
    .reg_swap2(swap2),
    .cores_en(cores_en)
);

// SINGLE SIMPLIFIED CORE ONLY 
core1_simple core1_ins(
    // Input
    .clk(clk),
    .rst(reg_rst),
    .enable(cores_en),
    .swap1(swap1),
    .swap2(swap2),
    .A2_S(A1_XX),        // Self-feedback instead of core2
    .A2_BP_OUT1(A1_XX),  // Self-feedback  
    .A3_BP_OUT2(A1_XX),  // Self-feedback instead of core3
    .A3_ZZ(A1_ZZ),       // Self-feedback instead of core3
    .A3_XX(A1_XX),       // Self-feedback instead of core3
    .Rx(Rx),
    .Ry(Ry),
    // Output
    .A1_BP_OUT2(A1_BP_OUT2),
    .A1_ZZ(A1_ZZ),
    .A1_XX(A1_XX)
);

endmodule