set SRC C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL
set SRC121 C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS121IP-VHDL
set GRLIB C:/Users/yinrui/Desktop/SHyLoc_ip/grlib-gpl-2020.1-b4251
proc pause {{message "Hit Enter to continue ==> "}} {
puts -nonewline $message
flush stdout
gets stdin
}
proc eval_result {SRC fp test_id} {
set result_test [examine sim:/ccsds_shyloc_tb/sim_successful]
if $result_test==TRUE {echo "Simulation finished, test $test_id PASSED"; puts $fp "$test_id passed";
coverage report -file C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL/modelsim/tb_stimuli/$test_id/report_coverage.txt -byfile -assert -directive -cvg -codeAll;
coverage report -file C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL/modelsim/tb_stimuli/$test_id/report_coverage_details.txt -byfile -detail -assert -directive -cvg -codeAll;
set file /../cover/$test_id;
append file _cover.ucdb;
coverage save -assert -directive -cvg -codeAll -instance /ccsds_shyloc_tb/gen_beh/shyloc C:\Users\yinrui\Desktop\SHyLoc_ip\shyloc_ip-main\CCSDS123IP-VHDL\modelsim\cover$file; return false}
if $result_test==FALSE {echo "Simulation finished, test FAILED"; puts $fp "$test_id failed"; return true}}
set fp [open "$SRC/modelsim/tb_scripts/verification_report.txt" w+]
set quit_flag false
set num_tests 0
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/20_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 20_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/20a_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 20a_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/20b_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 20b_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/24_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 24_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/24a_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 24a_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/28a_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 28a_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/29_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 29_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/29a_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 29a_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/30_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 30_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/30a_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 30a_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/40_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 40_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/41_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 41_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/43_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 43_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/44_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 44_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/44a_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 44a_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/45_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 45_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/45a_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 45a_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/46_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 46_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/46a_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 46a_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/46b_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 46b_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/56_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 56_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/59_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 59_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/59a_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 59a_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/61_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 61_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/62_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 62_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/63_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 63_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/63b_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 63b_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/64_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 64_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/64b_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 64b_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/67_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 67_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/67b_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 67b_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/68_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 68_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/68b_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 68b_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/72_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 72_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/73_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 73_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/80_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 80_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/80a_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 80a_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/81_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 81_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/81a_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 81a_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/82_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 82_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/83_Test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 83_Test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
if $quit_flag!=true {
 do $SRC/modelsim/tb_scripts/84_test.do
 onbreak resume
 set quit_flag [eval_result $SRC $fp 84_test]
}
incr num_tests
puts "End of Tests	Total Tests: $num_tests"
quit -sim
close $fp
vcover merge C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL/modelsim/cover/*.ucdb -out C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL/modelsim/cover/merged_result.ucdb
vcover report C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL/modelsim/cover/merged_result.ucdb -file C:/Users/yinrui/Desktop/SHyLoc_ip/shyloc_ip-main/CCSDS123IP-VHDL/modelsim/cover/merged_result.txt