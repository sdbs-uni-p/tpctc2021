#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>

set -e

if [ "$SOURCE_FROM_ONLINE" = "1" ]; then
    cd $HOME/git-repos
    git clone https://github.com/postgres/postgres.git
else
    cd $HOME/sources
    tar xf postgres.tar.bz2 --use-compress-program=pbzip2
    mv postgres $HOME/git-repos
fi

cd $HOME/git-repos/postgres
git checkout 272d82ec6febb97ab25fd7c67e9c84f4660b16ac # Tag: REL_13_3

###############################
# Default
###############################
./configure --prefix="$HOME/bin/postgres"
make -j $(nproc)
make install

###############################
# Cleanup - drop the sources
###############################
rm -rf $HOME/git-repos/postgres
