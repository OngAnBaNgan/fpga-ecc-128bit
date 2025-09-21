// spi_ecc_wrapper.v - SPI Interface Wrapper for ECC Core + ESP32
// Fixed version without multiple drivers

module spi_ecc_wrapper(
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

// Data Buffers for 163-bit values
reg [162:0] buffer_x;       // Point X coordinate  
reg [162:0] buffer_y;       // Point Y coordinate
reg [162:0] buffer_k;       // Scalar k
reg [162:0] buffer_b;       // Base point parameter
reg [162:0] result_dx;      // Result X coordinate
reg [162:0] result_dy;      // Result Y coordinate

// ECC Core Interface signals
reg ecc_enable;
wire [162:0] ecc_din;
wire [162:0] ecc_dx, ecc_dy;
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
        buffer_x <= 163'b0;
        buffer_y <= 163'b0;
        buffer_k <= 163'b0;
        buffer_b <= 163'b0;
        computation_requested <= 1'b0;
    end else begin
        // Clear computation request after it's been processed
        if (ecc_state != ECC_IDLE)
            computation_requested <= 1'b0;
            
        // Capture data when SPI CS goes high (end of transaction)
        if (spi_cs_rising) begin
            case (spi_addr)
                // X coordinate bytes (0x10-0x24)
                8'h10: buffer_x[162:155] <= spi_rx_byte;
                8'h11: buffer_x[154:147] <= spi_rx_byte;
                8'h12: buffer_x[146:139] <= spi_rx_byte;
                8'h13: buffer_x[138:131] <= spi_rx_byte;
                8'h14: buffer_x[130:123] <= spi_rx_byte;
                8'h15: buffer_x[122:115] <= spi_rx_byte;
                8'h16: buffer_x[114:107] <= spi_rx_byte;
                8'h17: buffer_x[106:99] <= spi_rx_byte;
                8'h18: buffer_x[98:91] <= spi_rx_byte;
                8'h19: buffer_x[90:83] <= spi_rx_byte;
                8'h1A: buffer_x[82:75] <= spi_rx_byte;
                8'h1B: buffer_x[74:67] <= spi_rx_byte;
                8'h1C: buffer_x[66:59] <= spi_rx_byte;
                8'h1D: buffer_x[58:51] <= spi_rx_byte;
                8'h1E: buffer_x[50:43] <= spi_rx_byte;
                8'h1F: buffer_x[42:35] <= spi_rx_byte;
                8'h20: buffer_x[34:27] <= spi_rx_byte;
                8'h21: buffer_x[26:19] <= spi_rx_byte;
                8'h22: buffer_x[18:11] <= spi_rx_byte;
                8'h23: buffer_x[10:3] <= spi_rx_byte;
                8'h24: buffer_x[2:0] <= spi_rx_byte[2:0];
                
                // Y coordinate bytes (0x30-0x44)
                8'h30: buffer_y[162:155] <= spi_rx_byte;
                8'h31: buffer_y[154:147] <= spi_rx_byte;
                8'h32: buffer_y[146:139] <= spi_rx_byte;
                8'h33: buffer_y[138:131] <= spi_rx_byte;
                8'h34: buffer_y[130:123] <= spi_rx_byte;
                8'h35: buffer_y[122:115] <= spi_rx_byte;
                8'h36: buffer_y[114:107] <= spi_rx_byte;
                8'h37: buffer_y[106:99] <= spi_rx_byte;
                8'h38: buffer_y[98:91] <= spi_rx_byte;
                8'h39: buffer_y[90:83] <= spi_rx_byte;
                8'h3A: buffer_y[82:75] <= spi_rx_byte;
                8'h3B: buffer_y[74:67] <= spi_rx_byte;
                8'h3C: buffer_y[66:59] <= spi_rx_byte;
                8'h3D: buffer_y[58:51] <= spi_rx_byte;
                8'h3E: buffer_y[50:43] <= spi_rx_byte;
                8'h3F: buffer_y[42:35] <= spi_rx_byte;
                8'h40: buffer_y[34:27] <= spi_rx_byte;
                8'h41: buffer_y[26:19] <= spi_rx_byte;
                8'h42: buffer_y[18:11] <= spi_rx_byte;
                8'h43: buffer_y[10:3] <= spi_rx_byte;
                8'h44: buffer_y[2:0] <= spi_rx_byte[2:0];
                
                // Scalar k bytes (0x50-0x64)
                8'h50: buffer_k[162:155] <= spi_rx_byte;
                8'h51: buffer_k[154:147] <= spi_rx_byte;
                8'h52: buffer_k[146:139] <= spi_rx_byte;
                8'h53: buffer_k[138:131] <= spi_rx_byte;
                8'h54: buffer_k[130:123] <= spi_rx_byte;
                8'h55: buffer_k[122:115] <= spi_rx_byte;
                8'h56: buffer_k[114:107] <= spi_rx_byte;
                8'h57: buffer_k[106:99] <= spi_rx_byte;
                8'h58: buffer_k[98:91] <= spi_rx_byte;
                8'h59: buffer_k[90:83] <= spi_rx_byte;
                8'h5A: buffer_k[82:75] <= spi_rx_byte;
                8'h5B: buffer_k[74:67] <= spi_rx_byte;
                8'h5C: buffer_k[66:59] <= spi_rx_byte;
                8'h5D: buffer_k[58:51] <= spi_rx_byte;
                8'h5E: buffer_k[50:43] <= spi_rx_byte;
                8'h5F: buffer_k[42:35] <= spi_rx_byte;
                8'h60: buffer_k[34:27] <= spi_rx_byte;
                8'h61: buffer_k[26:19] <= spi_rx_byte;
                8'h62: buffer_k[18:11] <= spi_rx_byte;
                8'h63: buffer_k[10:3] <= spi_rx_byte;
                8'h64: buffer_k[2:0] <= spi_rx_byte[2:0];
                
                // Base point b bytes (0x70-0x84)
                8'h70: buffer_b[162:155] <= spi_rx_byte;
                8'h71: buffer_b[154:147] <= spi_rx_byte;
                8'h72: buffer_b[146:139] <= spi_rx_byte;
                8'h73: buffer_b[138:131] <= spi_rx_byte;
                8'h74: buffer_b[130:123] <= spi_rx_byte;
                8'h75: buffer_b[122:115] <= spi_rx_byte;
                8'h76: buffer_b[114:107] <= spi_rx_byte;
                8'h77: buffer_b[106:99] <= spi_rx_byte;
                8'h78: buffer_b[98:91] <= spi_rx_byte;
                8'h79: buffer_b[90:83] <= spi_rx_byte;
                8'h7A: buffer_b[82:75] <= spi_rx_byte;
                8'h7B: buffer_b[74:67] <= spi_rx_byte;
                8'h7C: buffer_b[66:59] <= spi_rx_byte;
                8'h7D: buffer_b[58:51] <= spi_rx_byte;
                8'h7E: buffer_b[50:43] <= spi_rx_byte;
                8'h7F: buffer_b[42:35] <= spi_rx_byte;
                8'h80: buffer_b[34:27] <= spi_rx_byte;
                8'h81: buffer_b[26:19] <= spi_rx_byte;
                8'h82: buffer_b[18:11] <= spi_rx_byte;
                8'h83: buffer_b[10:3] <= spi_rx_byte;
                8'h84: buffer_b[2:0] <= spi_rx_byte[2:0];
                
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
            // Read result X coordinate (0x90-0xA4)
            8'h90: spi_tx_byte <= result_dx[162:155];
            8'h91: spi_tx_byte <= result_dx[154:147];
            8'h92: spi_tx_byte <= result_dx[146:139];
            8'h93: spi_tx_byte <= result_dx[138:131];
            8'h94: spi_tx_byte <= result_dx[130:123];
            8'h95: spi_tx_byte <= result_dx[122:115];
            8'h96: spi_tx_byte <= result_dx[114:107];
            8'h97: spi_tx_byte <= result_dx[106:99];
            8'h98: spi_tx_byte <= result_dx[98:91];
            8'h99: spi_tx_byte <= result_dx[90:83];
            8'h9A: spi_tx_byte <= result_dx[82:75];
            8'h9B: spi_tx_byte <= result_dx[74:67];
            8'h9C: spi_tx_byte <= result_dx[66:59];
            8'h9D: spi_tx_byte <= result_dx[58:51];
            8'h9E: spi_tx_byte <= result_dx[50:43];
            8'h9F: spi_tx_byte <= result_dx[42:35];
            8'hA0: spi_tx_byte <= result_dx[34:27];
            8'hA1: spi_tx_byte <= result_dx[26:19];
            8'hA2: spi_tx_byte <= result_dx[18:11];
            8'hA3: spi_tx_byte <= result_dx[10:3];
            8'hA4: spi_tx_byte <= {5'b0, result_dx[2:0]};
            
            // Read result Y coordinate (0xB0-0xC4)
            8'hB0: spi_tx_byte <= result_dy[162:155];
            8'hB1: spi_tx_byte <= result_dy[154:147];
            8'hB2: spi_tx_byte <= result_dy[146:139];
            8'hB3: spi_tx_byte <= result_dy[138:131];
            8'hB4: spi_tx_byte <= result_dy[130:123];
            8'hB5: spi_tx_byte <= result_dy[122:115];
            8'hB6: spi_tx_byte <= result_dy[114:107];
            8'hB7: spi_tx_byte <= result_dy[106:99];
            8'hB8: spi_tx_byte <= result_dy[98:91];
            8'hB9: spi_tx_byte <= result_dy[90:83];
            8'hBA: spi_tx_byte <= result_dy[82:75];
            8'hBB: spi_tx_byte <= result_dy[74:67];
            8'hBC: spi_tx_byte <= result_dy[66:59];
            8'hBD: spi_tx_byte <= result_dy[58:51];
            8'hBE: spi_tx_byte <= result_dy[50:43];
            8'hBF: spi_tx_byte <= result_dy[42:35];
            8'hC0: spi_tx_byte <= result_dy[34:27];
            8'hC1: spi_tx_byte <= result_dy[26:19];
            8'hC2: spi_tx_byte <= result_dy[18:11];
            8'hC3: spi_tx_byte <= result_dy[10:3];
            8'hC4: spi_tx_byte <= {5'b0, result_dy[2:0]};
            
            // Status register (0xF0)
            8'hF0: spi_tx_byte <= {7'b0, ecc_done};
            default: spi_tx_byte <= 8'h00;
        endcase
    end
end

assign spi_miso = spi_tx_byte[7 - spi_bit_cnt];

// ECC Control State Machine (SINGLE driver for all ECC control signals)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ecc_state <= ECC_IDLE;
        ecc_enable <= 1'b0;
        ecc_load_cnt <= 0;
        done_gpio <= 1'b0;
        debug_leds <= 4'h1;  // Idle state
        result_dx <= 163'b0;
        result_dy <= 163'b0;
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
                 (ecc_load_cnt == 3) ? buffer_k :
                 buffer_b;

// Instantiate single-core ECC (resource optimized version)
ecc_top_simple ecc_core (
    .clk(clk),
    .rst(rst_n), 
    .enable(ecc_enable),
    .din(ecc_din),
    .dx(ecc_dx),
    .dy(ecc_dy), 
    .reg_done(ecc_done)
);

endmodule