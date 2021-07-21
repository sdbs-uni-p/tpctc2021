#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>

# Postgres
source ./benchmark-execution postgres postgres postgres-ycsb oltpbench-ycsb ycsb-1200_config_postgres.xml ycsb postgres-ycsb

# MariaDB
source ./benchmark-execution mariadb mariadb mariadb-ycsb oltpbench-ycsb ycsb-1200_config_mariadb.xml ycsb mariadb-ycsb
