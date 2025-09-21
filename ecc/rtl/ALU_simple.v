// ALU_simple.v - Resource optimized ALU using sequential multiplier

module ALU_simple(
    input clk,
    input rst,
    input [162:0] DA,
    input [162:0] DB,
    input Mul_enable,
    input SQA_opt,
    output reg [162:0] BP_OUT1,
    output reg [162:0] BP_OUT2,
    output reg [162:0] SS_OUT,
    output reg alu_done
);

// Sequential multiplier instance
reg mult_enable;
reg [40:0] mult_A;
reg [162:0] mult_B;
wire [202:0] mult_C;
wire mult_done;

multiplier_simple mult_inst(
    .clk(clk),
    .rst(rst),
    .enable(mult_enable),
    .A(mult_A),
    .B(mult_B),
    .C(mult_C),
    .done(mult_done)
);

// ALU state machine
localparam ALU_IDLE = 2'b00;
localparam ALU_MUL = 2'b01;
localparam ALU_ADD = 2'b10;
localparam ALU_DONE = 2'b11;

reg [1:0] alu_state;

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        alu_state <= ALU_IDLE;
        BP_OUT1 <= 163'b0;
        BP_OUT2 <= 163'b0;
        SS_OUT <= 163'b0;
        alu_done <= 1'b0;
        mult_enable <= 1'b0;
        mult_A <= 41'b0;
        mult_B <= 163'b0;
    end else begin
        case (alu_state)
            ALU_IDLE: begin
                alu_done <= 1'b0;
                if (Mul_enable) begin
                    // Start multiplication
                    mult_A <= DA[40:0];  // Take lower 41 bits
                    mult_B <= DB;
                    mult_enable <= 1'b1;
                    alu_state <= ALU_MUL;
                end else if (SQA_opt) begin
                    // Simple add/square operation (combinational)
                    BP_OUT2 <= DA ^ DB;  // GF(2) addition
                    SS_OUT <= DA;        // Simplified square
                    alu_state <= ALU_DONE;
                end else begin
                    // Simple addition
                    BP_OUT1 <= DA ^ DB;  // GF(2) addition
                    alu_state <= ALU_DONE;
                end
            end
            
            ALU_MUL: begin
                mult_enable <= 1'b0;
                if (mult_done) begin
                    BP_OUT1 <= mult_C[162:0];  // Take lower 163 bits
                    alu_state <= ALU_DONE;
                end
            end
            
            ALU_ADD: begin
                // Addition complete
                alu_state <= ALU_DONE;
            end
            
            ALU_DONE: begin
                alu_done <= 1'b1;
                alu_state <= ALU_IDLE;
            end
        endcase
    end
end

endmodule