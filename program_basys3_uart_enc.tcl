open_hw_manager
connect_hw_server
open_hw_target
set dev [lindex [get_hw_devices xc7a35t*] 0]
if {$dev eq ""} {
    error "No xc7a35t hardware device found. Check Basys 3 USB/JTAG connection."
}
current_hw_device $dev
refresh_hw_device -update_hw_probes false $dev
set_property PROGRAM.FILE {AES128_ENCRYPT_UART_WRAPPER.bit} $dev
program_hw_devices $dev
close_hw_manager
