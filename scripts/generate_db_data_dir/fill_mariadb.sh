#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>

set -e

mariadb_dir=$1
mariadb_data_dir=$2
oltpbench_dir=$3
oltpbench_benchmark=$4
oltpbench_config=$5

if [ ! -d "$mariadb_dir" ]; then
        echo "MariaDB build directory '$mariadb_dir' is not set or does not exist!"
        exit 1
fi

if [ ! -d "$mariadb_data_dir" ]; then
        echo "MariaDB data directory '$mariadb_data_dir' is not set or does not exist!"
        exit 1
fi

if [ ! -d "$oltpbench_dir" ]; then
    echo "OLTPBench directory '$oltpbench_dir' does not exist!"
    exit 1
fi

if [ -z "$oltpbench_benchmark" ]; then
    echo "No benchmark specified for OLTPBench!"
    exit 1
fi

if [ ! -f "$oltpbench_config" ]; then
    echo "Configuration file for oltpbench '$oltpbench_config' not found!"
    exit 1
fi

# Start DB
$mariadb_dir/bin/mysqld --no-defaults --skip-grant-tables --datadir="$mariadb_data_dir" &
sleep 2

# Fill DB
cd "$oltpbench_dir"
./oltpbenchmark -b $oltpbench_benchmark -c "$oltpbench_config" --create=true --load=true

# Stop DB
killall mysqld
sleep 2
