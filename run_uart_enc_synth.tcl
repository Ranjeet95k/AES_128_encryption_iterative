open_project AES128_iterative_encryption.xpr
update_compile_order -fileset sources_1
reset_run synth_1
launch_runs synth_1 -jobs 2
wait_on_run synth_1
open_run synth_1 -name synth_1
report_timing_summary -file synth_timing_summary.rpt
report_drc -file synth_drc.rpt
close_project
