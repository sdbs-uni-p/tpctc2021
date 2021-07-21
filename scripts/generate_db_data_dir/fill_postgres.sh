#! /usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>

set -e

postgres_dir=$1
postgres_data_dir=$2
oltpbench_dir=$3
oltpbench_benchmark=$4
oltpbench_config=$5

if [ ! -d "$postgres_dir" ]; then
        echo "PostgreSQL build directory '$postgres_dir' is not set or does not exist!"
        exit 1
fi

if [ ! -d "$postgres_data_dir" ]; then
        echo "PostgreSQL data directory '$postgres_data_dir' is not set or does not exist!"
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
$postgres_dir/bin/postgres -D "$postgres_data_dir" &
sleep 2

# Fill DB
cd "$oltpbench_dir"
./oltpbenchmark -b $oltpbench_benchmark -c "$oltpbench_config" --create=true --load=true

# Stop DB
killall postgres
sleep 2
