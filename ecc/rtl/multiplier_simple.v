// multiplier_simple.v - Resource optimized sequential multiplier
// Fixed version without variable array indexing

module multiplier_simple(
    input clk,
    input rst,
    input enable,
    input [40:0] A,
    input [162:0] B, 
    output reg [202:0] C,
    output reg done
);

// Sequential multiplier state
reg [5:0] bit_count;  // Count from 0 to 40
reg [202:0] partial_sum;
reg [162:0] shifted_B;
reg mult_active;
reg current_bit;

// Extract current bit from A using case statement
always @(*) begin
    case (bit_count)
        6'd0:  current_bit = A[0];
        6'd1:  current_bit = A[1];
        6'd2:  current_bit = A[2];
        6'd3:  current_bit = A[3];
        6'd4:  current_bit = A[4];
        6'd5:  current_bit = A[5];
        6'd6:  current_bit = A[6];
        6'd7:  current_bit = A[7];
        6'd8:  current_bit = A[8];
        6'd9:  current_bit = A[9];
        6'd10: current_bit = A[10];
        6'd11: current_bit = A[11];
        6'd12: current_bit = A[12];
        6'd13: current_bit = A[13];
        6'd14: current_bit = A[14];
        6'd15: current_bit = A[15];
        6'd16: current_bit = A[16];
        6'd17: current_bit = A[17];
        6'd18: current_bit = A[18];
        6'd19: current_bit = A[19];
        6'd20: current_bit = A[20];
        6'd21: current_bit = A[21];
        6'd22: current_bit = A[22];
        6'd23: current_bit = A[23];
        6'd24: current_bit = A[24];
        6'd25: current_bit = A[25];
        6'd26: current_bit = A[26];
        6'd27: current_bit = A[27];
        6'd28: current_bit = A[28];
        6'd29: current_bit = A[29];
        6'd30: current_bit = A[30];
        6'd31: current_bit = A[31];
        6'd32: current_bit = A[32];
        6'd33: current_bit = A[33];
        6'd34: current_bit = A[34];
        6'd35: current_bit = A[35];
        6'd36: current_bit = A[36];
        6'd37: current_bit = A[37];
        6'd38: current_bit = A[38];
        6'd39: current_bit = A[39];
        6'd40: current_bit = A[40];
        default: current_bit = 1'b0;
    endcase
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        C <= 203'b0;
        done <= 1'b0;
        bit_count <= 6'b0;
        partial_sum <= 203'b0;
        shifted_B <= 163'b0;
        mult_active <= 1'b0;
    end else begin
        if (enable && !mult_active) begin
            // Start multiplication
            mult_active <= 1'b1;
            bit_count <= 6'b0;
            partial_sum <= 203'b0;
            shifted_B <= B;
            done <= 1'b0;
        end else if (mult_active) begin
            // Perform one bit of multiplication per clock
            if (current_bit) begin
                // Shift B left by bit_count positions and XOR with partial sum
                case (bit_count)
                    6'd0:  partial_sum <= partial_sum ^ {40'b0, shifted_B};
                    6'd1:  partial_sum <= partial_sum ^ {39'b0, shifted_B, 1'b0};
                    6'd2:  partial_sum <= partial_sum ^ {38'b0, shifted_B, 2'b0};
                    6'd3:  partial_sum <= partial_sum ^ {37'b0, shifted_B, 3'b0};
                    6'd4:  partial_sum <= partial_sum ^ {36'b0, shifted_B, 4'b0};
                    6'd5:  partial_sum <= partial_sum ^ {35'b0, shifted_B, 5'b0};
                    6'd6:  partial_sum <= partial_sum ^ {34'b0, shifted_B, 6'b0};
                    6'd7:  partial_sum <= partial_sum ^ {33'b0, shifted_B, 7'b0};
                    6'd8:  partial_sum <= partial_sum ^ {32'b0, shifted_B, 8'b0};
                    6'd9:  partial_sum <= partial_sum ^ {31'b0, shifted_B, 9'b0};
                    6'd10: partial_sum <= partial_sum ^ {30'b0, shifted_B, 10'b0};
                    6'd11: partial_sum <= partial_sum ^ {29'b0, shifted_B, 11'b0};
                    6'd12: partial_sum <= partial_sum ^ {28'b0, shifted_B, 12'b0};
                    6'd13: partial_sum <= partial_sum ^ {27'b0, shifted_B, 13'b0};
                    6'd14: partial_sum <= partial_sum ^ {26'b0, shifted_B, 14'b0};
                    6'd15: partial_sum <= partial_sum ^ {25'b0, shifted_B, 15'b0};
                    6'd16: partial_sum <= partial_sum ^ {24'b0, shifted_B, 16'b0};
                    6'd17: partial_sum <= partial_sum ^ {23'b0, shifted_B, 17'b0};
                    6'd18: partial_sum <= partial_sum ^ {22'b0, shifted_B, 18'b0};
                    6'd19: partial_sum <= partial_sum ^ {21'b0, shifted_B, 19'b0};
                    6'd20: partial_sum <= partial_sum ^ {20'b0, shifted_B, 20'b0};
                    6'd21: partial_sum <= partial_sum ^ {19'b0, shifted_B, 21'b0};
                    6'd22: partial_sum <= partial_sum ^ {18'b0, shifted_B, 22'b0};
                    6'd23: partial_sum <= partial_sum ^ {17'b0, shifted_B, 23'b0};
                    6'd24: partial_sum <= partial_sum ^ {16'b0, shifted_B, 24'b0};
                    6'd25: partial_sum <= partial_sum ^ {15'b0, shifted_B, 25'b0};
                    6'd26: partial_sum <= partial_sum ^ {14'b0, shifted_B, 26'b0};
                    6'd27: partial_sum <= partial_sum ^ {13'b0, shifted_B, 27'b0};
                    6'd28: partial_sum <= partial_sum ^ {12'b0, shifted_B, 28'b0};
                    6'd29: partial_sum <= partial_sum ^ {11'b0, shifted_B, 29'b0};
                    6'd30: partial_sum <= partial_sum ^ {10'b0, shifted_B, 30'b0};
                    6'd31: partial_sum <= partial_sum ^ {9'b0, shifted_B, 31'b0};
                    6'd32: partial_sum <= partial_sum ^ {8'b0, shifted_B, 32'b0};
                    6'd33: partial_sum <= partial_sum ^ {7'b0, shifted_B, 33'b0};
                    6'd34: partial_sum <= partial_sum ^ {6'b0, shifted_B, 34'b0};
                    6'd35: partial_sum <= partial_sum ^ {5'b0, shifted_B, 35'b0};
                    6'd36: partial_sum <= partial_sum ^ {4'b0, shifted_B, 36'b0};
                    6'd37: partial_sum <= partial_sum ^ {3'b0, shifted_B, 37'b0};
                    6'd38: partial_sum <= partial_sum ^ {2'b0, shifted_B, 38'b0};
                    6'd39: partial_sum <= partial_sum ^ {1'b0, shifted_B, 39'b0};
                    6'd40: partial_sum <= partial_sum ^ {shifted_B, 40'b0};
                    default: partial_sum <= partial_sum;
                endcase
            end
            
            bit_count <= bit_count + 6'd1;
            
            if (bit_count == 6'd40) begin
                // Multiplication complete
                C <= partial_sum;
                done <= 1'b1;
                mult_active <= 1'b0;
            end
        end else begin
            done <= 1'b0;
        end
    end
end

endmodule