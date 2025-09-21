# ecc.sdc - Timing Constraints for EP4CE6E22C8
# Target: 50MHz main clock

# Main clock constraint
create_clock -name "clk_50" -period 20.000 [get_ports {clk}]

# SPI clock constraint (slower, async with main clock)
create_clock -name "spi_clk" -period 100.000 [get_ports {spi_clk}]

# Clock groups (asynchronous)
set_clock_groups -asynchronous -group [get_clocks {clk_50}] -group [get_clocks {spi_clk}]

# Input delays for SPI (relative to spi_clk)
set_input_delay -clock [get_clocks {spi_clk}] -min 2.0 [get_ports {spi_mosi spi_cs_n}]
set_input_delay -clock [get_clocks {spi_clk}] -max 8.0 [get_ports {spi_mosi spi_cs_n}]

# Output delays for SPI
set_output_delay -clock [get_clocks {spi_clk}] -min 2.0 [get_ports {spi_miso}]
set_output_delay -clock [get_clocks {spi_clk}] -max 8.0 [get_ports {spi_miso}]

# GPIO timing
set_input_delay -clock [get_clocks {clk_50}] -min 1.0 [get_ports {enable_gpio rst_n}]
set_input_delay -clock [get_clocks {clk_50}] -max 5.0 [get_ports {enable_gpio rst_n}]
set_output_delay -clock [get_clocks {clk_50}] -min 1.0 [get_ports {done_gpio}]
set_output_delay -clock [get_clocks {clk_50}] -max 5.0 [get_ports {done_gpio}]

# False paths for reset
set_false_path -from [get_ports {rst_n}] -to [all_registers]

# Multicycle paths for ECC computation (relaxing timing for long paths)
set_multicycle_path -setup -to [get_registers {*ecc_core*core*}] 2
set_multicycle_path -hold -to [get_registers {*ecc_core*core*}] 1