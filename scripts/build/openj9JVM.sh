#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>

set -e

cd /tmp
if [ "$SOURCE_FROM_ONLINE" = "1" ]; then
    wget -q -O openjdk16-openj9.tar.gz https://github.com/AdoptOpenJDK/openjdk16-binaries/releases/download/jdk-16.0.1%2B9_openj9-0.26.0/OpenJDK16U-jdk_x64_linux_openj9_16.0.1_9_openj9-0.26.0.tar.gz
else
    mv $HOME/sources/openjdk16-openj9.tar.gz /tmp
fi

mkdir $HOME/bin/openj9JVM
tar xf openjdk16-openj9.tar.gz -C $HOME/bin/openj9JVM --strip-components=1

###############################
# Cleanup - drop the sources
###############################
rm -rf /tmp/openjdk16-openj9.tar.gz
