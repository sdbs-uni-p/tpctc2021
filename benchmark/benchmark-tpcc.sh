#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>

# Postgres
source ./benchmark-execution postgres postgres postgres-tpcc oltpbench tpcc-10_config_postgres.xml tpcc postgres-tpcc

# MariaDB
source ./benchmark-execution mariadb mariadb mariadb-tpcc oltpbench tpcc-10_config_mariadb.xml tpcc mariadb-tpcc
