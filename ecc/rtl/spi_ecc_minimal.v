// spi_ecc_minimal.v - SPI wrapper for 64-bit ECC version
// Dramatically reduced resource usage

module spi_ecc_minimal(
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
localparam SPI_IDLE = 2'b00;
localparam SPI_DATA = 2'b01;

// ECC State Machine Parameters
localparam ECC_IDLE = 2'b00;
localparam ECC_COMPUTE = 2'b01;
localparam ECC_DONE = 2'b10;

// SPI signals
reg [1:0] spi_state;
reg [7:0] spi_bit_cnt;
reg [7:0] spi_rx_byte;
reg [7:0] spi_tx_byte;

// Data Buffers for 64-bit values (much smaller)
reg [63:0] buffer_input;    // Input data
reg [63:0] result_dx;       // Result X coordinate
reg [63:0] result_dy;       // Result Y coordinate

// ECC Core Interface signals
reg ecc_enable;
wire [63:0] ecc_din;
wire [63:0] ecc_dx, ecc_dy;
wire ecc_done;

// ECC Control signals
reg [1:0] ecc_state;

// Simple SPI receiver
always @(posedge spi_clk or posedge spi_cs_n) begin
    if (spi_cs_n) begin
        spi_bit_cnt <= 0;
    end else begin
        spi_rx_byte <= {spi_rx_byte[6:0], spi_mosi};
        spi_bit_cnt <= spi_bit_cnt + 8'd1;
        
        if (spi_bit_cnt == 8'd7) begin
            // Store received byte (simplified addressing)
            case (spi_bit_cnt[5:3]) // Use upper bits as simple address
                3'b000: buffer_input[7:0] <= spi_rx_byte;
                3'b001: buffer_input[15:8] <= spi_rx_byte;
                3'b010: buffer_input[23:16] <= spi_rx_byte;
                3'b011: buffer_input[31:24] <= spi_rx_byte;
                3'b100: buffer_input[39:32] <= spi_rx_byte;
                3'b101: buffer_input[47:40] <= spi_rx_byte;
                3'b110: buffer_input[55:48] <= spi_rx_byte;
                3'b111: buffer_input[63:56] <= spi_rx_byte;
            endcase
        end
    end
end

// Simple SPI transmitter
always @(negedge spi_clk or posedge spi_cs_n) begin
    if (spi_cs_n) begin
        spi_tx_byte <= 8'h00;
    end else begin
        // Send result data
        case (spi_bit_cnt[5:3])
            3'b000: spi_tx_byte <= result_dx[7:0];
            3'b001: spi_tx_byte <= result_dx[15:8];
            3'b010: spi_tx_byte <= result_dx[23:16];
            3'b011: spi_tx_byte <= result_dx[31:24];
            3'b100: spi_tx_byte <= result_dx[39:32];
            3'b101: spi_tx_byte <= result_dx[47:40];
            3'b110: spi_tx_byte <= result_dx[55:48];
            3'b111: spi_tx_byte <= result_dx[63:56];
        endcase
    end
end

assign spi_miso = spi_tx_byte[7 - spi_bit_cnt[2:0]];

// ECC Control State Machine (simplified)
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ecc_state <= ECC_IDLE;
        ecc_enable <= 1'b0;
        done_gpio <= 1'b0;
        debug_leds <= 4'h1;
        result_dx <= 64'b0;
        result_dy <= 64'b0;
    end else begin
        case (ecc_state)
            ECC_IDLE: begin
                ecc_enable <= 1'b0;
                done_gpio <= 1'b0;
                debug_leds <= 4'h1;  // Idle indicator
                
                if (enable_gpio) begin
                    ecc_state <= ECC_COMPUTE;
                    ecc_enable <= 1'b1;
                    debug_leds <= 4'h4; // Computing
                end
            end
            
            ECC_COMPUTE: begin
                ecc_enable <= 1'b1;
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

// Data input for ECC core
assign ecc_din = buffer_input;

// Instantiate minimal ECC core
ecc_top_minimal ecc_core (
    .clk(clk),
    .rst(rst_n), 
    .enable(ecc_enable),
    .din(ecc_din),
    .dx(ecc_dx),
    .dy(ecc_dy), 
    .reg_done(ecc_done)
);

endmodule