#!/bin/bash

myhosts=""
sharp_conf_dir="/hpc/scrap/users/sashakot"
sharp_dump_dir="/hpc/scrap/users/sashakot"

test="barrier"

function get_i_hosts()
{
	local list=$1
	local i=$2

	hostlist -e $list | head -$i | xargs echo | xargs hostlist -c
}

function run_test()
{
	local name=$1
	local list=$2
	local non_sharp=$3

	local trees_cfg="${sharp_dump_dir}/${name}_trees.cfg"
	#local list=$SLURM_NODELIST
	local n=$(hostlist -e $list | wc -l)

	echo "Test: $name"
	echo "Trees file: $trees_cfg"
	echo "Conf dir: $sharp_conf_dir"
	echo "Dump dir: $sharp_dump_dir"
	echo "n: $n"

	sudo pkill -9 sharp_am > /dev/null 2>&1
	sudo  SHARP_CONF=${sharp_conf_dir} sharp_am_dump_dir=${sharp_dump_dir} sharp_am_generate_dump_files=true sharp_am_trees_file=${trees_cfg} /hpc/scrap/users/sashakot/hpcx-gcc-redhat7.2/sharp/sbin/sharp_manager.sh start -p sharp_am
	for i in $( seq 2 $n); do
		myhosts=$(get_i_hosts  ${list} ${i})
		echo $myhosts
		sharp_hostlist=$(get_i_hosts  ${list} ${i}) sharp_ib_dev="mlx5_3:1" sharp_test_max_data=256 /hpc/scrap/users/sashakot/hpcx-gcc-redhat7.2/sharp/sbin/sharp_benchmark2.sh  -t sharp:${test} -f > "${sharp_dump_dir}/${name}_${i}.log"
		if [[ -z $non_sharp ]]; then
			sharp_hostlist=$(get_i_hosts  ${list} ${i}) sharp_ib_dev="mlx5_3:1" /hpc/scrap/users/sashakot/hpcx-gcc-redhat7.2/sharp/sbin/sharp_benchmark2.sh  -t ${test} -f > "${sharp_dump_dir}/no_sharp_${i}.log"
		fi
done
}

sudo  /hpc/scrap/users/sashakot/hpcx-gcc-redhat7.2/sharp/sbin/sharp_manager.sh stop
sudo  SHARP_CONF=${sharp_conf_dir} /hpc/scrap/users/sashakot/hpcx-gcc-redhat7.2/sharp/sbin/sharp_manager.sh start -p sharpd 

run_test "1_level" "$SLURM_NODELIST"
#run_test "move_host" "$SLURM_NODELIST"
run_test "2_level" "$SLURM_NODELIST" non-sharp
run_test "3_level" "$SLURM_NODELIST"
