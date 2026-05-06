open_project AES128_iterative_encryption.xpr
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
set_property top tb_AES128_ENCRYPT_ITERATIVE [get_filesets sim_1]
launch_simulation -simset sim_1 -mode behavioral -runall
close_sim
close_project
