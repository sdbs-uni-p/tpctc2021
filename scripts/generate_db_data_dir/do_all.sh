#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>

set -e

# Each database gets for each benchmark its own data directory.
# This script creates and initializes for all benchmarks (NoOp,
# YCSB, TPC-C) and for each database (MariaDB, PostgreSQL) a 
# own database directory and pre-populates it with data.

base_dir=`dirname $(readlink -f "$0")`

# MariaDB
## NoOp
### Create
"$base_dir"/datadir_mariadb.sh \
    /home/repro/bin/mariadb \
    /home/repro/db_data_dir/mariadb-noop \
    noop

### Fill
# No data to fill for NoOp.

## YCSB
### Create
"$base_dir"/datadir_mariadb.sh \
    /home/repro/bin/mariadb \
    /home/repro/db_data_dir/mariadb-ycsb \
    ycsb

### Fill
"$base_dir"/fill_mariadb.sh \
    /home/repro/bin/mariadb \
    /home/repro/db_data_dir/mariadb-ycsb \
    /home/repro/bin/oltpbench-ycsb \
    ycsb \
    /home/repro/oltpbench-configs/ycsb-1200_config_mariadb.xml

## TPC-C
### Create
"$base_dir"/datadir_mariadb.sh \
    /home/repro/bin/mariadb \
    /home/repro/db_data_dir/mariadb-tpcc \
    tpcc

### Fill
"$base_dir"/fill_mariadb.sh \
    /home/repro/bin/mariadb \
    /home/repro/db_data_dir/mariadb-tpcc \
    /home/repro/bin/oltpbench \
    tpcc \
    /home/repro/oltpbench-configs/tpcc-10_config_mariadb.xml

# PostgreSQL
## NoOp
### Create
"$base_dir"/datadir_postgres.sh \
    /home/repro/bin/postgres \
    /home/repro/db_data_dir/postgres-noop \
    noop

### Fill
# No data to fill for NoOp.

## YCSB
### Create
"$base_dir"/datadir_postgres.sh \
    /home/repro/bin/postgres \
    /home/repro/db_data_dir/postgres-ycsb \
    ycsb

### Fill
"$base_dir"/fill_postgres.sh \
    /home/repro/bin/postgres \
    /home/repro/db_data_dir/postgres-ycsb \
    /home/repro/bin/oltpbench-ycsb \
    ycsb \
    /home/repro/oltpbench-configs/ycsb-1200_config_postgres.xml

## TPC-C
### Create
"$base_dir"/datadir_postgres.sh \
    /home/repro/bin/postgres \
    /home/repro/db_data_dir/postgres-tpcc \
    tpcc

### Fill
"$base_dir"/fill_postgres.sh \
    /home/repro/bin/postgres \
    /home/repro/db_data_dir/postgres-tpcc \
    /home/repro/bin/oltpbench \
    tpcc \
    /home/repro/oltpbench-configs/tpcc-10_config_postgres.xml
