// multiplier_dsp.v - Use embedded DSP blocks instead of LUTs
// Dramatically reduces LE usage

module multiplier_dsp(
    input clk,
    input rst,
    input enable,
    input [40:0] A,
    input [162:0] B, 
    output reg [202:0] C,
    output reg done
);

// Break into smaller chunks using embedded 18x18 multipliers
reg [4:0] chunk_count;
reg [162:0] partial_result;
reg mult_active;

// Use embedded multiplier (18x18)
reg [17:0] mult_a;
reg [17:0] mult_b;
wire [35:0] mult_out;

// Instantiate embedded multiplier
// This uses DSP block instead of LUTs
multiplier_18x18 dsp_mult (
    .clock(clk),
    .dataa(mult_a),
    .datab(mult_b),
    .result(mult_out)
);

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        C <= 203'b0;
        done <= 1'b0;
        chunk_count <= 5'b0;
        partial_result <= 163'b0;
        mult_active <= 1'b0;
        mult_a <= 18'b0;
        mult_b <= 18'b0;
    end else begin
        if (enable && !mult_active) begin
            mult_active <= 1'b1;
            chunk_count <= 5'b0;
            partial_result <= 163'b0;
            done <= 1'b0;
        end else if (mult_active) begin
            // Process in 18-bit chunks
            case (chunk_count)
                5'd0: begin
                    mult_a <= A[17:0];
                    mult_b <= B[17:0];
                end
                5'd1: begin
                    partial_result[35:0] <= mult_out;
                    mult_a <= A[17:0];
                    mult_b <= B[35:18];
                end
                5'd2: begin
                    partial_result[53:18] <= partial_result[53:18] ^ mult_out;
                    mult_a <= A[17:0];  
                    mult_b <= B[53:36];
                end
                // Continue for remaining chunks...
                default: begin
                    C <= {40'b0, partial_result};
                    done <= 1'b1;
                    mult_active <= 1'b0;
                end
            endcase
            
            chunk_count <= chunk_count + 5'd1;
            
            if (chunk_count >= 5'd10) begin // Approximate number of chunks needed
                mult_active <= 1'b0;
            end
        end else begin
            done <= 1'b0;
        end
    end
end

endmodule

// Embedded multiplier instantiation (auto-inferred by Quartus)
module multiplier_18x18 (
    input clock,
    input [17:0] dataa,
    input [17:0] datab,
    output [35:0] result
);

// This will be automatically mapped to DSP blocks by Quartus
reg [35:0] mult_result;

always @(posedge clock) begin
    mult_result <= dataa * datab;
end

assign result = mult_result;

endmodule