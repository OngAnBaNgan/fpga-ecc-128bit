// core1_simple.v - Simplified core using sequential ALU

module core1_simple(
    // Input
    input clk,
    input rst,
    input enable,
    input swap1,
    input swap2,
    input [162:0] A2_S,
    input [162:0] A2_BP_OUT1,
    input [162:0] A3_BP_OUT2,
    input [162:0] A3_ZZ,
    input [162:0] A3_XX,
    input [162:0] Rx,
    input [162:0] Ry,
    // Output
    output reg [162:0] A1_BP_OUT2,
    output reg [162:0] A1_ZZ,
    output reg [162:0] A1_XX
);

// Simplified state machine
localparam CORE_IDLE = 3'b000;
localparam CORE_LOAD = 3'b001;
localparam CORE_COMPUTE1 = 3'b010;
localparam CORE_COMPUTE2 = 3'b011;
localparam CORE_COMPUTE3 = 3'b100;
localparam CORE_DONE = 3'b101;

reg [2:0] core_state;
// reg [7:0] compute_count; // Removed unused signal

// Simple ALU interface
reg [162:0] alu_da, alu_db;
reg alu_mul_enable, alu_sqa_opt;
wire [162:0] alu_bp_out1, alu_bp_out2, alu_ss_out;
wire alu_done;

// Instantiate simplified ALU
ALU_simple alu_inst(
    .clk(clk),
    .rst(rst),
    .DA(alu_da),
    .DB(alu_db),
    .Mul_enable(alu_mul_enable),
    .SQA_opt(alu_sqa_opt),
    .BP_OUT1(alu_bp_out1),
    .BP_OUT2(alu_bp_out2),
    .SS_OUT(alu_ss_out),
    .alu_done(alu_done)
);

// Core state machine
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        core_state <= CORE_IDLE;
        // compute_count <= 8'b0; // Removed unused signal
        A1_ZZ <= 163'b0;
        A1_XX <= 163'b0;
        A1_BP_OUT2 <= 163'b0;
        alu_mul_enable <= 1'b0;
        alu_sqa_opt <= 1'b0;
        alu_da <= 163'b0;
        alu_db <= 163'b0;
    end else begin
        case (core_state)
            CORE_IDLE: begin
                if (enable) begin
                    core_state <= CORE_LOAD;
                    // compute_count <= 8'b0; // Removed unused signal
                end
            end
            
            CORE_LOAD: begin
                // Setup first computation
                alu_da <= Rx;
                alu_db <= Ry;
                alu_mul_enable <= 1'b1;
                core_state <= CORE_COMPUTE1;
            end
            
            CORE_COMPUTE1: begin
                alu_mul_enable <= 1'b0;
                if (alu_done) begin
                    A1_XX <= alu_bp_out1;
                    // Setup second computation
                    alu_da <= A1_XX;
                    alu_db <= Rx;
                    alu_sqa_opt <= 1'b1;
                    core_state <= CORE_COMPUTE2;
                end
            end
            
            CORE_COMPUTE2: begin
                alu_sqa_opt <= 1'b0;
                if (alu_done) begin
                    A1_ZZ <= alu_bp_out2;
                    A1_BP_OUT2 <= alu_ss_out;
                    // Setup third computation
                    alu_da <= A1_ZZ;
                    alu_db <= A1_XX;
                    alu_mul_enable <= 1'b1;
                    core_state <= CORE_COMPUTE3;
                end
            end
            
            CORE_COMPUTE3: begin
                alu_mul_enable <= 1'b0;
                if (alu_done) begin
                    A1_BP_OUT2 <= alu_bp_out1;
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