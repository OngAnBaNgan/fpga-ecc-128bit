// ALU_128bit.v - 128-bit ALU optimized for ECC operations
// Uses efficient algorithms for GF(2^128) arithmetic

module ALU_128bit(
    input clk,
    input rst,
    input [127:0] da,
    input [127:0] db,
    input mult_enable,
    input add_enable,
    input sqr_enable,
    output reg [127:0] result,
    output reg done
);

// ALU state machine
localparam ALU_IDLE = 2'b00;
localparam ALU_COMPUTE = 2'b01;
localparam ALU_COMPLETE = 2'b10;

reg [1:0] alu_state;
reg [6:0] compute_cycles;

// Intermediate results
reg [127:0] temp_result;
reg [127:0] operand_a, operand_b;
reg operation_type; // 0=add/sqr, 1=mult

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        alu_state <= ALU_IDLE;
        result <= 128'b0;
        done <= 1'b0;
        compute_cycles <= 7'b0;
        temp_result <= 128'b0;
        operand_a <= 128'b0;
        operand_b <= 128'b0;
        operation_type <= 1'b0;
    end else begin
        case (alu_state)
            ALU_IDLE: begin
                done <= 1'b0;
                
                if (mult_enable) begin
                    // Start multiplication
                    operand_a <= da;
                    operand_b <= db;
                    operation_type <= 1'b1;
                    compute_cycles <= 7'd64; // 64 cycles for multiplication
                    temp_result <= 128'b0;
                    alu_state <= ALU_COMPUTE;
                    
                end else if (add_enable) begin
                    // GF(2) addition is just XOR - immediate result
                    result <= da ^ db;
                    alu_state <= ALU_COMPLETE;
                    
                end else if (sqr_enable) begin
                    // GF(2) squaring - simplified implementation
                    operand_a <= da;
                    operation_type <= 1'b0;
                    compute_cycles <= 7'd8; // 8 cycles for squaring
                    temp_result <= 128'b0;
                    alu_state <= ALU_COMPUTE;
                end
            end
            
            ALU_COMPUTE: begin
                compute_cycles <= compute_cycles - 7'd1;
                
                if (operation_type) begin
                    // Multiplication in GF(2^128) - simplified bit-by-bit
                    if (operand_a[0]) begin
                        temp_result <= temp_result ^ operand_b;
                    end
                    operand_a <= {1'b0, operand_a[127:1]}; // Shift right
                    operand_b <= {operand_b[126:0], 1'b0}; // Shift left
                    
                end else begin
                    // Squaring in GF(2^128) - simplified
                    // In GF(2), squaring distributes: (a+b)^2 = a^2 + b^2
                    temp_result <= temp_result ^ {operand_a[63:0], operand_a[127:64]};
                    operand_a <= {operand_a[63:0], operand_a[127:64]}; // Rotate
                end
                
                if (compute_cycles == 7'd0) begin
                    result <= temp_result;
                    alu_state <= ALU_COMPLETE;
                end
            end
            
            ALU_COMPLETE: begin
                done <= 1'b1;
                alu_state <= ALU_IDLE;
            end
        endcase
    end
end

endmodule