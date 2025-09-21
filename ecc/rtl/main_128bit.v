// main_128bit.v - Simplified main controller for 128-bit ECC
// Fixed version with proper signal types

`timescale 1ns / 1ps

module main_128bit(
    // Input
    input clk, 
    input rst, 
    input data_en,
    input [127:0]din,
    // Output
    output reg [127:0]opt_Rx,    // Changed to reg
    output reg [127:0]opt_Ry,    // Changed to reg
    output reg [127:0]opt_Rb,    // Changed to reg
    output reg reg_swap1,
    output reg reg_swap2,
    output reg cores_en
);

// Internal registers
reg [127:0]Rx;
reg [127:0]Ry;
reg [127:0]Rb;
reg [127:0]k;
reg [4:0]state;
reg [4:0]next_state;
reg [6:0]cnt128;

// Control signals
reg cnt128_set;
reg cnt128_dec;
reg [2:0]cnt8;
reg flag1;
reg flag2;
reg Ry_en;
reg Ry_set_clr;
reg cnt8_clr;
reg Rx_rst;

// Simplified data storage
reg [127:0]reg_Ry;
reg [127:0]reg_Rx;
reg [127:0]reg_Rb;

// State parameters (simplified)
parameter IDLE     = 5'b00001,
          DATAIN   = 5'b00010,
          CYCLE1   = 5'b00100,
          COMPUTE  = 5'b01000,
          DONE     = 5'b10000;

// Output assignments
always@(posedge clk) begin
    opt_Rx <= Rx;
    opt_Ry <= Ry;
    opt_Rb <= reg_Rb;  // Use reg_Rb instead of Rb
end

// Counter logic (simplified)
always@(posedge clk) begin
    if(~rst)
        cnt128 <= 7'd0;
    else if(cnt128_set)
        cnt128 <= 7'd127;
    else if(cnt128_dec)
        cnt128 <= cnt128 - 7'd1;
end

always@(posedge clk) begin
    if(~rst | cnt8_clr)
        cnt8 <= 3'd0;
    else 
        cnt8 <= cnt8 + 3'd1;
end

// Data storage registers (simplified shift)
always@(posedge clk) begin
    if(data_en) begin
        reg_Rb <= din;
        k <= reg_Rb;
        reg_Ry <= k;
        reg_Rx <= reg_Ry;
    end
end

// Core interface registers
always@(posedge clk) begin
    if(Ry_en)
        Ry <= reg_Ry;
    else if(Ry_set_clr)
        Ry <= 128'd1;
    else    
        Ry <= 128'd0;
end

always@(posedge clk) begin
    if(Rx_rst)
        Rx <= 128'd0;
    else
        Rx <= reg_Rx;
end

// Simplified swap logic
always@(posedge clk) begin
    if(~rst) begin
        reg_swap1 <= 1'b0;
        reg_swap2 <= 1'b0;
    end else begin
        if(flag1)
            reg_swap1 <= k[126]; // Use bit 126 instead of 161
        else
            reg_swap1 <= 1'b0;
            
        if(flag2)    
            reg_swap2 <= k[125] ^ k[126]; // Simple XOR logic
        else
            reg_swap2 <= 1'b0;
    end
end

// State machine (greatly simplified)
always@(posedge clk) begin
    if(~rst)
        state <= IDLE;
    else
        state <= next_state;
end

always@(*) begin
    // Default assignments
    Ry_en = 1'b0;
    Ry_set_clr = 1'b0;
    flag1 = 1'b0;
    flag2 = 1'b0;
    cnt128_dec = 1'b0;    
    cnt8_clr = 1'b0;
    cnt128_set = 1'b0;
    next_state = state;
    cores_en = 1'b0;
    Rx_rst = 1'b0;
    
    case(state)
        IDLE: begin
            if(data_en) begin
                next_state = DATAIN;    
            end
            Ry_en = 1'b1;    
        end        
        
        DATAIN: begin
            if(~data_en) begin
                next_state = CYCLE1;
                cores_en = 1'b1;
            end    
        end
        
        CYCLE1: begin
            next_state = COMPUTE;
            Ry_set_clr = 1'b1;
            Rx_rst = 1'b1;
            cnt128_set = 1'b1;
        end
        
        COMPUTE: begin
            cores_en = 1'b1;
            flag1 = 1'b1;
            flag2 = 1'b1;
            cnt128_dec = 1'b1;
            
            if(cnt128 == 7'd0) begin
                next_state = DONE;
            end
        end
        
        DONE: begin
            Ry_en = 1'b1;
            if(~data_en) begin
                next_state = IDLE;
            end
        end
    endcase
end

endmodule