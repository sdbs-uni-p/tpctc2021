#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>

set -e

if [ "$SOURCE_FROM_ONLINE" = "1" ]; then
    cd $HOME/git-repos
    git clone https://github.com/MariaDB/server.git mariadb
else
    cd $HOME/sources
    tar xf mariadb.tar.bz2 --use-compress-program=pbzip2
    mv mariadb $HOME/git-repos
fi

cd $HOME/git-repos/mariadb
git checkout 609e8e38bb0e5c80a80c77c451b6e519f9aeb386 # Branch: 10.6 

###############################
# Default
###############################
cmake -DCMAKE_INSTALL_PREFIX=/home/repro/bin/mariadb
make -j $(nproc)
make install

###############################
# NoOp Patched
###############################
git apply /tmp/patches/mariadb/0001-Transform-semicolon-into-comment.patch

# Build patched MariaDB (10.6)
cmake -DCMAKE_INSTALL_PREFIX=/home/repro/bin/mariadb-patched
make -j $(nproc)
make install

###############################
# Cleanup - drop the sources
###############################
rm -rf $HOME/git-repos/mariadb
