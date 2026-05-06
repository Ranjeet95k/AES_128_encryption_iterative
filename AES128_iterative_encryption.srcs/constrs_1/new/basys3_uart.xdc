## Basys 3 Artix-7
## Top ports: clk_fpga, reset, rx, tx, leds[7:0], done_led

## 100 MHz onboard clock
set_property PACKAGE_PIN W5 [get_ports clk_fpga]
set_property IOSTANDARD LVCMOS33 [get_ports clk_fpga]
create_clock -name sys_clk -period 10.000 [get_ports clk_fpga]

## CPU reset pushbutton
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

## USB-UART bridge
## PC TX -> FPGA RX
set_property PACKAGE_PIN B18 [get_ports rx]
set_property IOSTANDARD LVCMOS33 [get_ports rx]

## FPGA TX -> PC RX
set_property PACKAGE_PIN A18 [get_ports tx]
set_property IOSTANDARD LVCMOS33 [get_ports tx]

## User LEDs LD0-LD7 show latest received/transmitted byte
set_property PACKAGE_PIN U16 [get_ports {leds[0]}]
set_property PACKAGE_PIN E19 [get_ports {leds[1]}]
set_property PACKAGE_PIN U19 [get_ports {leds[2]}]
set_property PACKAGE_PIN V19 [get_ports {leds[3]}]
set_property PACKAGE_PIN W18 [get_ports {leds[4]}]
set_property PACKAGE_PIN U15 [get_ports {leds[5]}]
set_property PACKAGE_PIN U14 [get_ports {leds[6]}]
set_property PACKAGE_PIN V14 [get_ports {leds[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {leds[*]}]

## LD15 indicates ciphertext match
set_property PACKAGE_PIN L1 [get_ports done_led]
set_property IOSTANDARD LVCMOS33 [get_ports done_led]

## Basys 3 configuration
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
