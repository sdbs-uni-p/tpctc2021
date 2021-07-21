#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>

set -e

# Creates and initializes a new database directory for MariaDB.
## Arguments: <mariadb_bin_dir> <db_dir> <db_name>
## mariadb_bin_dir: The binary directory of MariaDB containing all 
##                  executables.
## db_dir:          The database directory that will be created (on
##                  disk).
## db_name:         The name of the database to create.

mariadb_bin_dir=$1
db_dir=$2
db_name=$3

if [ ! -d "$mariadb_bin_dir" ]; then
    echo "MariaDB build directory '$mariadb_bin_dir' is not set or does not exist!"
    exit 1
fi

if [ -d "$db_dir" ]; then
    echo "Database directory '$db_dir' already exists or is not set!"
    exit 1
fi

if [ -z "$db_name" ]; then
    echo "Name of database is not set!"
    exit 1
fi

initdb="$mariadb_bin_dir/scripts/mysql_install_db"
client="$mariadb_bin_dir/bin/mysql"

# Ceate database dir
mkdir "$db_dir"

# Init database dir
$initdb --datadir="$db_dir"
# Start DB
$mariadb_bin_dir/bin/mysqld --no-defaults --skip-grant-tables --datadir="$db_dir" &
sleep 2

# Create database
$client -e "CREATE DATABASE $db_name"

# Stop DB
killall mysqld
sleep 2
