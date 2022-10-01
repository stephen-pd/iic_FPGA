vsim -t 1ps -c -voptargs="+acc=npr"  work.tb_top  -wav ./wave/tb.wlf

add wave -r sim:/tb_top/*
run 20ms -all