#!/bin/bash

BASE_NAME=$(basename $0)

function check_root_permission()
{
	if [ $(whoami) != "root" ]; then
		echo "Error: root permission required. Exit."
		echo ""
		usage
		exit 1
	fi
}

function start_service()
{
	local service=$1

	sudo systemctl start $service

	return $?
}

function start_services()
{
	for var in "$@"; do
		if ! start_service ${var}; then
		       echo "WARNING: Service ${var} is not started"
	       fi
	done
}

function usage()
{
	echo "Usage: ${BASE_NAME}"
	echo ""
	echo "${BASE_NAME} enables autofs"
	echo "The script needs root access"
}

check_root_permission
start_service rpcbind ypbind autofs
