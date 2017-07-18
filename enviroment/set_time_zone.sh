#!/bin/bash

TIME_ZONE=${1:-"Asia/Jerusalem"}

date
date -u

echo "Time zone: $TIME_ZONE"

sudo unlink /etc/localtime
sudo ln -s /usr/share/zoneinfo/$TIME_ZONE /etc/localtime

date
date -u
