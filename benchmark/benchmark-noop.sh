#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>

# Postgres
source ./benchmark-execution postgres postgres postgres-noop oltpbench-noop noop_config_postgres.xml noop postgres-noop

# MariaDB
source ./benchmark-execution mariadb mariadb-patched mariadb-noop oltpbench-noop noop_config_mariadb.xml noop mariadb-noop
