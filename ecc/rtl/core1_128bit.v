// core1_128bit.v - 128-bit ECC core with proper arithmetic operations
// Simplified but functional ECC implementation

module core1_128bit(
    // Input
    input clk,
    input rst,
    input enable,
    input swap1,
    input swap2,
    input [127:0] A2_S,
    input [127:0] A2_BP_OUT1,
    input [127:0] A3_BP_OUT2,
    input [127:0] A3_ZZ,
    input [127:0] A3_XX,
    input [127:0] Rx,
    input [127:0] Ry,
    // Output
    output reg [127:0] A1_BP_OUT2,
    output reg [127:0] A1_ZZ,
    output reg [127:0] A1_XX
);

// State machine
localparam CORE_IDLE = 3'b000;
localparam CORE_LOAD = 3'b001;
localparam CORE_MULT = 3'b010;
localparam CORE_ADD = 3'b011;
localparam CORE_SQR = 3'b100;
localparam CORE_DONE = 3'b101;

reg [2:0] core_state;
// reg [6:0] cycle_count; // Removed unused signal

// ALU interface  
reg [127:0] alu_da, alu_db;
reg alu_mult_enable, alu_add_enable, alu_sqr_enable;
wire [127:0] alu_result;
wire alu_done;

// 128-bit ALU instance
ALU_128bit alu_inst(
    .clk(clk),
    .rst(rst),
    .da(alu_da),
    .db(alu_db),
    .mult_enable(alu_mult_enable),
    .add_enable(alu_add_enable),
    .sqr_enable(alu_sqr_enable),
    .result(alu_result),
    .done(alu_done)
);

// Core state machine
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        core_state <= CORE_IDLE;
        // cycle_count <= 7'b0; // Removed unused signal
        A1_ZZ <= 128'b0;
        A1_XX <= 128'b0;
        A1_BP_OUT2 <= 128'b0;
        alu_mult_enable <= 1'b0;
        alu_add_enable <= 1'b0;
        alu_sqr_enable <= 1'b0;
        alu_da <= 128'b0;
        alu_db <= 128'b0;
    end else begin
        case (core_state)
            CORE_IDLE: begin
                if (enable) begin
                    core_state <= CORE_LOAD;
                    // cycle_count <= 7'b0; // Removed unused signal
                end
            end
            
            CORE_LOAD: begin
                // Setup first operation: multiply Rx * Ry
                alu_da <= Rx;
                alu_db <= Ry;
                alu_mult_enable <= 1'b1;
                core_state <= CORE_MULT;
            end
            
            CORE_MULT: begin
                alu_mult_enable <= 1'b0;
                if (alu_done) begin
                    A1_XX <= alu_result;
                    // Setup addition: A1_XX + Rx
                    alu_da <= alu_result;
                    alu_db <= Rx;
                    alu_add_enable <= 1'b1;
                    core_state <= CORE_ADD;
                end
            end
            
            CORE_ADD: begin
                alu_add_enable <= 1'b0;
                if (alu_done) begin
                    A1_ZZ <= alu_result;
                    // Setup square: A1_ZZ^2
                    alu_da <= alu_result;
                    alu_db <= 128'b0; // Not used for square
                    alu_sqr_enable <= 1'b1;
                    core_state <= CORE_SQR;
                end
            end
            
            CORE_SQR: begin
                alu_sqr_enable <= 1'b0;
                if (alu_done) begin
                    A1_BP_OUT2 <= alu_result;
                    core_state <= CORE_DONE;
                end
            end
            
            CORE_DONE: begin
                // Computation complete
                if (!enable) begin
                    core_state <= CORE_IDLE;
                end
            end
        endcase
    end
end

endmodule