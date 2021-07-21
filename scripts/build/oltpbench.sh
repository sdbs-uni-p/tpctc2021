#! /usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>

if [ "$SOURCE_FROM_ONLINE" = "1" ]; then
    cd $HOME/git-repos
    git clone https://github.com/oltpbenchmark/oltpbench.git
else
    cd $HOME/sources
    tar xf oltpbench.tar.bz2 --use-compress-program=pbzip2
    mv oltpbench $HOME/git-repos
fi

cd $HOME/git-repos/oltpbench
git checkout 6e8c04f3a2e672fb8ffe54a1acc6bcb9a59acf38

# Get ivy
ant bootstrap

###############################
# Default
###############################
# Build
ant clean resolve build

mkdir $HOME/bin/oltpbench
cp -R $HOME/git-repos/oltpbench/. $HOME/bin/oltpbench

###############################
# YCSB Patch
###############################
git reset --hard && git clean -xffd
git apply /tmp/patches/oltpbench/0001-Upgrade-XML-library.patch

# Build
ant clean resolve build
mkdir $HOME/bin/oltpbench-ycsb
cp -R $HOME/git-repos/oltpbench/. $HOME/bin/oltpbench-ycsb


###############################
# NoOp Patch
###############################
git reset --hard && git clean -xffd
git apply /tmp/patches/oltpbench/0001-Fix-NoOp-and-disable-commit.patch

# Build
ant clean resolve build
mkdir $HOME/bin/oltpbench-noop
cp -R $HOME/git-repos/oltpbench/. $HOME/bin/oltpbench-noop

###############################
# Cleanup - drop the sources
###############################
rm -rf $HOME/git-repos/oltpbench
