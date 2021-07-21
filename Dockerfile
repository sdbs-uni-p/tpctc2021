# SPDX-License-Identifier: GPL-2.0-only
#
# Replication package for TPCTC 2021
# Tell-Tale Tail Latencies: Pitfalls and Perils in Database Benchmarking
#
# Authors:
#   Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>
#   Copyright 2021, Stefanie Scherzinger <stefanie.scherzinger@uni-passau.de>
#   Copyright 2021, Wolfgang Mauerer <wolfgang.mauerer@othr.de>
#   Copyright 2021, Ralf Ramsauer <ralf.ramsauer@othr.de>

FROM ubuntu:20.04

MAINTAINER Michael Fruth <michael.fruth@uni-passau.de>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG="C"
ENV LC_ALL="C"

########################
# Installation
########################
RUN apt-get update -qq
RUN apt-get install -y --no-install-recommends \
        ant \
        bison \
        build-essential \
        ca-certificates \
        cmake \
        flex \
        git \
        gnutls-dev \
        libcairo2-dev \
        libfreetype6-dev \
        libfribidi-dev \
        libharfbuzz-dev \
        libjpeg-dev \
        libncurses-dev \
        libpng-dev \
        libreadline-dev \
        libtiff5-dev \
        libxt-dev \
        libxml2-dev \
        pbzip2 \
        psmisc \
        r-base \
        r-base-dev \
        sudo \
        wget \
        zlib1g-dev

RUN Rscript -e "install.packages('renv')"
########################
# Infrastructure
########################
RUN useradd -m -G sudo -s /bin/bash repro && echo "repro:repro" | chpasswd
USER repro
WORKDIR /home/repro

# Final directory structure
## bin/                 - for generated binary executables 
## db_data_dir/         - for generated database directories (pre-populated databases).
##                        This directory is empty and can be filled afterwards inside a
##                        running container.
## plot/                - for plotting the benchmark data.
## measure/             - for executing the benchmark and plotting the data. Contains
##                        all functionality for reproduction.
## oltpbench-configs/   - for oltpbench configuration files
## scripts/             - for supporting scripts
RUN mkdir -p $HOME/git-repos $HOME/bin $HOME/db_data_dir

COPY --chown=repro:repro patches /tmp/patches
COPY --chown=repro:repro oltpbench-configs /home/repro/oltpbench-configs
COPY --chown=repro:repro scripts /home/repro/scripts
COPY --chown=repro:repro plot /home/repro/plot

WORKDIR /home/repro/plot
RUN ./setup_renv.r

########################
# User configuration
########################
ENV SOURCE_FROM_ONLINE=1 

#ENV SOURCE_FROM_ONLINE=0
#COPY --chown=repro:repro sources /home/repro/sources

##################################################################
######################## Compile Sources #########################
##################################################################

########################
# Java
########################
# HotSpot JVM from AdoptOpenJDK.net (Java Version 16)
RUN /home/repro/scripts/build/hotspotJVM.sh

# OpenJ9 JVM from AdoptOpenJDK.net (Java Version 16)
RUN /home/repro/scripts/build/openj9JVM.sh

########################
# MariaDB
########################
# Build MariaDB
## /home/repro/bin/mariadb (Version 10.6)
## /home/repro/bin/mariadb-patch (Version 10.6 patched for NoOp benchmark)
RUN /home/repro/scripts/build/mariadb.sh

########################
# PostgreSQL
########################
# Build PostgreSQL
## /home/repro/bin/postgres (Version REL_13_3)
RUN /home/repro/scripts/build/postgres.sh

########################
# OLTPBench
########################
# Build OLTPBench
##  /home/repro/bin/oltpbench (default)
##  /home/repro/bin/oltpbench-ycsb (patched for YCSB benchmark)
##  /home/repro/bin/oltpbench-noop (patched for NoOp benchmark)
ENV JAVA_HOME=/home/repro/bin/hotspotJVM
ENV PATH="${JAVA_HOME}/bin:${PATH}"

RUN /home/repro/scripts/build/oltpbench.sh

#########################
# Prepare directory used for benchmarking
#########################
RUN mkdir $HOME/measure

COPY --chown=repro:repro benchmark /home/repro/measure/benchmark

WORKDIR /home/repro/measure/benchmark
RUN ln -s /home/repro/bin
RUN ln -s /home/repro/oltpbench-configs
RUN ln -s /home/repro/db_data_dir

WORKDIR /home/repro/measure

RUN mkdir -p results plots
RUN ln -s /home/repro/plot
RUN ln -s /home/repro/scripts/generate_db_data_dir/do_all.sh generate_db_data_dir.sh

#########################
## Finish
#########################
# Cleanup
RUN rm -rf $HOME/git-repos
WORKDIR /home/repro
