#!/bin/bash

function get_latency()
{
	local name=$1
	local iteration=$2
	
	local log="./${name}_${i}.log"
	local latency=$(tail -2 $log | head -1 | awk '{print $1}')

	latency="${latency//[[:space:]]/}"

	echo $latency
}

declare -a arr=("no_sharp" "1_level" "2_level" "3_level")
header="#n"
n="64"

for t in "${arr[@]}"; do
	header="${header},${t}"
done

echo "$header"

for i in $(seq 2 $n) ; do
	
	row="$i"
	for t in "${arr[@]}"; do
		latency=$(get_latency $t $i)
		row="${row},${latency}"
	done

	echo ${row}
done
