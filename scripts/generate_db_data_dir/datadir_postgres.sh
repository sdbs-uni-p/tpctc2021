#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>

set -e

# Creates and initializes a new database directory for PostgreSQL.
## Arguments: <mariadb_dir> <db_dir> <db_name>
## postgres_dir:    The build directory of PostgreSQL containing all
##                  executables.
## db_dir:          The database directory that will be created (on
##                  disk).
## db_name:         The name of the database to create.

postgres_dir=$1
db_dir=$2
db_name=$3

if [ ! -d "$postgres_dir" ]; then
    echo "Postgres build directory '$postgres_dir' is not set or does not exist!"
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

initdb="${postgres_dir}/bin/initdb"
psql="${postgres_dir}/bin/psql"

# Ceate database dir
mkdir "$db_dir"

# Init database dir
eval $initdb -D "$db_dir"

# Start DB
$postgres_dir/bin/postgres -D "$db_dir" &
sleep 2

# Create user
$psql -d postgres -c "CREATE USER root SUPERUSER"
# Create database
$psql -d postgres -c "CREATE DATABASE $db_name"

# Stop DB
killall postgres
sleep 2
