// spi_ecc_128bit.v - SPI wrapper for 128-bit ECC implementation
// Balanced between functionality and resource usage

module spi_ecc_128bit(
    // Clock and Reset
    input clk,              // 50MHz main clock
    input rst_n,            // Active-low reset
    
    // SPI Interface (ESP32 as master)
    input spi_clk,          // SPI clock from ESP32
    input spi_mosi,         // SPI data from ESP32  
    output spi_miso,        // SPI data to ESP32
    input spi_cs_n,         // SPI chip select (active low)
    
    // GPIO Handshaking
    input enable_gpio,      // Start computation signal from ESP32
    output reg done_gpio,   // Computation done signal to ESP32
    
    // Debug LEDs (optional)
    output reg [3:0] debug_leds
);

// SPI State Machine Parameters
localparam SPI_IDLE = 3'b000;
localparam SPI_ADDR = 3'b001; 
localparam SPI_DATA = 3'b010;

// ECC State Machine Parameters
localparam ECC_IDLE = 2'b00;
localparam ECC_LOAD = 2'b01;
localparam ECC_COMPUTE = 2'b10;
localparam ECC_DONE = 2'b11;

// SPI signals
reg [2:0] spi_state;
reg [7:0] spi_addr;
reg [7:0] spi_bit_cnt;
reg [7:0] spi_rx_byte;
reg [7:0] spi_tx_byte;
reg spi_cs_sync, spi_cs_prev;

// Data Buffers for 128-bit values
reg [127:0] buffer_x;       // Point X coordinate  
reg [127:0] buffer_y;       // Point Y coordinate
// reg [127:0] buffer_k;       // Scalar k (unused for now)
// reg [127:0] buffer_b;       // Base point parameter (unused for now)
reg [127:0] result_dx;      // Result X coordinate
reg [127:0] result_dy;      // Result Y coordinate

// ECC Core Interface signals
reg ecc_enable;
wire [127:0] ecc_din;
wire [127:0] ecc_dx, ecc_dy;
wire ecc_done;

// ECC Control signals
reg [1:0] ecc_state;
reg [7:0] ecc_load_cnt;
reg computation_requested;

// Synchronize SPI CS to main clock domain
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        spi_cs_sync <= 1'b1;
        spi_cs_prev <= 1'b1;
    end else begin
        spi_cs_sync <= spi_cs_n;
        spi_cs_prev <= spi_cs_sync;
    end
end

wire spi_cs_rising = ~spi_cs_prev & spi_cs_sync;

// SPI State Machine (on SPI clock)
always @(posedge spi_clk or posedge spi_cs_n) begin
    if (spi_cs_n) begin
        spi_state <= SPI_IDLE;
        spi_bit_cnt <= 0;
    end else begin
        case (spi_state)
            SPI_IDLE: begin
                spi_bit_cnt <= 0;
                spi_state <= SPI_ADDR;
            end
            
            SPI_ADDR: begin
                spi_rx_byte <= {spi_rx_byte[6:0], spi_mosi};
                spi_bit_cnt <= spi_bit_cnt + 8'd1;
                if (spi_bit_cnt == 7) begin
                    spi_addr <= {spi_rx_byte[6:0], spi_mosi};
                    spi_bit_cnt <= 0;
                    spi_state <= SPI_DATA;
                end
            end
            
            SPI_DATA: begin
                spi_rx_byte <= {spi_rx_byte[6:0], spi_mosi};
                spi_bit_cnt <= spi_bit_cnt + 8'd1;
                if (spi_bit_cnt == 7) begin
                    spi_bit_cnt <= 0;
                end
            end
        endcase
    end
end

// Data storage (synchronized to main clock)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        buffer_x <= 128'b0;
        buffer_y <= 128'b0;
        // buffer_k <= 128'b0;
        // buffer_b <= 128'b0;
        computation_requested <= 1'b0;
    end else begin
        // Clear computation request after it's been processed
        if (ecc_state != ECC_IDLE)
            computation_requested <= 1'b0;
            
        // Capture data when SPI CS goes high (end of transaction)
        if (spi_cs_rising) begin
            case (spi_addr)
                // X coordinate bytes (0x10-0x1F) - 16 bytes for 128 bits
                8'h10: buffer_x[7:0] <= spi_rx_byte;
                8'h11: buffer_x[15:8] <= spi_rx_byte;
                8'h12: buffer_x[23:16] <= spi_rx_byte;
                8'h13: buffer_x[31:24] <= spi_rx_byte;
                8'h14: buffer_x[39:32] <= spi_rx_byte;
                8'h15: buffer_x[47:40] <= spi_rx_byte;
                8'h16: buffer_x[55:48] <= spi_rx_byte;
                8'h17: buffer_x[63:56] <= spi_rx_byte;
                8'h18: buffer_x[71:64] <= spi_rx_byte;
                8'h19: buffer_x[79:72] <= spi_rx_byte;
                8'h1A: buffer_x[87:80] <= spi_rx_byte;
                8'h1B: buffer_x[95:88] <= spi_rx_byte;
                8'h1C: buffer_x[103:96] <= spi_rx_byte;
                8'h1D: buffer_x[111:104] <= spi_rx_byte;
                8'h1E: buffer_x[119:112] <= spi_rx_byte;
                8'h1F: buffer_x[127:120] <= spi_rx_byte;
                
                // Y coordinate bytes (0x20-0x2F)
                8'h20: buffer_y[7:0] <= spi_rx_byte;
                8'h21: buffer_y[15:8] <= spi_rx_byte;
                8'h22: buffer_y[23:16] <= spi_rx_byte;
                8'h23: buffer_y[31:24] <= spi_rx_byte;
                8'h24: buffer_y[39:32] <= spi_rx_byte;
                8'h25: buffer_y[47:40] <= spi_rx_byte;
                8'h26: buffer_y[55:48] <= spi_rx_byte;
                8'h27: buffer_y[63:56] <= spi_rx_byte;
                8'h28: buffer_y[71:64] <= spi_rx_byte;
                8'h29: buffer_y[79:72] <= spi_rx_byte;
                8'h2A: buffer_y[87:80] <= spi_rx_byte;
                8'h2B: buffer_y[95:88] <= spi_rx_byte;
                8'h2C: buffer_y[103:96] <= spi_rx_byte;
                8'h2D: buffer_y[111:104] <= spi_rx_byte;
                8'h2E: buffer_y[119:112] <= spi_rx_byte;
                8'h2F: buffer_y[127:120] <= spi_rx_byte;
                
                // K and B parameters (simplified for now)
                // 8'h30-0x3F: buffer_k bytes
                // 8'h40-0x4F: buffer_b bytes
                
                // Start computation command (0xFF)
                8'hFF: computation_requested <= 1'b1;
            endcase
        end
    end
end

// SPI Transmitter for reading results
always @(negedge spi_clk or posedge spi_cs_n) begin
    if (spi_cs_n) begin
        spi_tx_byte <= 8'h00;
    end else begin
        case (spi_addr)
            // Read result X coordinate (0x80-0x8F)
            8'h80: spi_tx_byte <= result_dx[7:0];
            8'h81: spi_tx_byte <= result_dx[15:8];
            8'h82: spi_tx_byte <= result_dx[23:16];
            8'h83: spi_tx_byte <= result_dx[31:24];
            8'h84: spi_tx_byte <= result_dx[39:32];
            8'h85: spi_tx_byte <= result_dx[47:40];
            8'h86: spi_tx_byte <= result_dx[55:48];
            8'h87: spi_tx_byte <= result_dx[63:56];
            8'h88: spi_tx_byte <= result_dx[71:64];
            8'h89: spi_tx_byte <= result_dx[79:72];
            8'h8A: spi_tx_byte <= result_dx[87:80];
            8'h8B: spi_tx_byte <= result_dx[95:88];
            8'h8C: spi_tx_byte <= result_dx[103:96];
            8'h8D: spi_tx_byte <= result_dx[111:104];
            8'h8E: spi_tx_byte <= result_dx[119:112];
            8'h8F: spi_tx_byte <= result_dx[127:120];
            
            // Read result Y coordinate (0x90-0x9F)
            8'h90: spi_tx_byte <= result_dy[7:0];
            8'h91: spi_tx_byte <= result_dy[15:8];
            8'h92: spi_tx_byte <= result_dy[23:16];
            8'h93: spi_tx_byte <= result_dy[31:24];
            8'h94: spi_tx_byte <= result_dy[39:32];
            8'h95: spi_tx_byte <= result_dy[47:40];
            8'h96: spi_tx_byte <= result_dy[55:48];
            8'h97: spi_tx_byte <= result_dy[63:56];
            8'h98: spi_tx_byte <= result_dy[71:64];
            8'h99: spi_tx_byte <= result_dy[79:72];
            8'h9A: spi_tx_byte <= result_dy[87:80];
            8'h9B: spi_tx_byte <= result_dy[95:88];
            8'h9C: spi_tx_byte <= result_dy[103:96];
            8'h9D: spi_tx_byte <= result_dy[111:104];
            8'h9E: spi_tx_byte <= result_dy[119:112];
            8'h9F: spi_tx_byte <= result_dy[127:120];
            
            // Status register (0xF0)
            8'hF0: spi_tx_byte <= {7'b0, ecc_done};
            default: spi_tx_byte <= 8'h00;
        endcase
    end
end

assign spi_miso = spi_tx_byte[7 - spi_bit_cnt];

// ECC Control State Machine
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ecc_state <= ECC_IDLE;
        ecc_enable <= 1'b0;
        ecc_load_cnt <= 0;
        done_gpio <= 1'b0;
        debug_leds <= 4'h1;
        result_dx <= 128'b0;
        result_dy <= 128'b0;
    end else begin
        case (ecc_state)
            ECC_IDLE: begin
                ecc_enable <= 1'b0;
                done_gpio <= 1'b0;
                debug_leds <= 4'h1;  // Idle indicator
                
                if (enable_gpio && computation_requested) begin
                    ecc_state <= ECC_LOAD;
                    ecc_load_cnt <= 0;
                    debug_leds <= 4'h2; // Loading
                end
            end
            
            ECC_LOAD: begin
                ecc_enable <= 1'b1;
                ecc_load_cnt <= ecc_load_cnt + 8'd1;
                if (ecc_load_cnt >= 4) begin
                    ecc_state <= ECC_COMPUTE;
                    debug_leds <= 4'h4; // Computing
                end
            end
            
            ECC_COMPUTE: begin
                ecc_enable <= 1'b1; // Keep enabled during computation
                if (ecc_done) begin
                    result_dx <= ecc_dx;
                    result_dy <= ecc_dy;
                    ecc_state <= ECC_DONE;
                    debug_leds <= 4'h8; // Done
                end
            end
            
            ECC_DONE: begin
                ecc_enable <= 1'b0;
                done_gpio <= 1'b1;
                if (!enable_gpio) begin
                    ecc_state <= ECC_IDLE;
                end
            end
        endcase
    end
end

// Data input multiplexer for ECC core
assign ecc_din = (ecc_load_cnt == 1) ? buffer_x :
                 (ecc_load_cnt == 2) ? buffer_y :
                 buffer_x; // Simplified - use X for all inputs

// Instantiate 128-bit ECC core
ecc_top_128bit ecc_core (
    .clk(clk),
    .rst(rst_n), 
    .enable(ecc_enable),
    .din(ecc_din),
    .dx(ecc_dx),
    .dy(ecc_dy), 
    .reg_done(ecc_done)
);

endmodule