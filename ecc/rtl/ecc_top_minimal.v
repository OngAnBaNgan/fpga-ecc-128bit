// ecc_top_minimal.v - Minimal bit-width version for resource constraints
// Reduced from 163-bit to 64-bit for testing

`timescale 1ns / 1ps

module ecc_top_minimal(clk, rst, enable, din, dx, dy, reg_done);

input clk;
input rst;
input enable;
input [63:0]din;  // Reduced from 163-bit to 64-bit
output [63:0]dx;
output [63:0]dy;
output reg_done;

// Simplified core signals
reg [63:0] result_x, result_y;
reg [63:0] input_buffer;
reg [2:0] state;
reg computation_done;

// Simple output assignment
assign dx = result_x;
assign dy = result_y;
assign reg_done = computation_done;

// Minimal state machine
localparam IDLE = 3'b000;
localparam LOAD = 3'b001; 
localparam COMPUTE = 3'b010;
localparam DONE = 3'b011;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        state <= IDLE;
        result_x <= 64'b0;
        result_y <= 64'b0;
        input_buffer <= 64'b0;
        computation_done <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                computation_done <= 1'b0;
                if (enable) begin
                    input_buffer <= din;
                    state <= LOAD;
                end
            end
            
            LOAD: begin
                state <= COMPUTE;
            end
            
            COMPUTE: begin
                // Simplified ECC computation (placeholder)
                result_x <= input_buffer ^ 64'h1234567890ABCDEF;
                result_y <= input_buffer ^ 64'hFEDCBA0987654321;
                state <= DONE;
            end
            
            DONE: begin
                computation_done <= 1'b1;
                if (!enable) begin
                    state <= IDLE;
                end
            end
        endcase
    end
end

endmodule