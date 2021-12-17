[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.5112729.svg)](https://doi.org/10.5281/zenodo.5112729)

# Replication Package


This site provides the replication package for the TPCTC 2021 paper *Tell-Tale Tail Latencies: Pitfalls and Perils in Database Benchmarking*

[supplementary_material](supplementary_material) contains the figures for the experiments conducted with PostgreSQL as well as the time series plots with all queries.

*NOTE*: An archival version of the pre-built docker image, together with a copy of the git repository and the measured data, are available at the DOI [10.5281/zenodo.5112729](https://doi.org/10.5281/zenodo.5112729).

## Building the Docker image
- Clone the repository
```
git clone https://github.com/sdbs-uni-p/tpctc2021.git
```

- Build the Docker image from scratch
```
cd tpctc2021
docker build -t tpctc2021:latest .
```

## Performing measurements
- Create a new container
```
docker run -t -d --tmpfs /tmp --name tpctc2021 tpctc2021:latest
```

- Attach to the container
```
docker exec -it tpctc2021 /bin/bash
```

- Generate the database data directories used for benchmarking. The database data directories are stored in `$HOME/db_data_dir`.
```
cd $HOME/measure
./generate_db_data_dir.sh
```

- Execute benchmark(s). The benchmark data is stored in `$HOME/measure/results`.
```
cd $HOME/measure/benchmark
./benchmark-noop.sh
./benchmark-ycsb.sh
./benchmark-tpcc.sh
```

- Create plots based on the results stored in `$HOME/measure/results`. The plots are stored in `$HOME/measure/plots`.
```
cd $HOME/measure/plot
./plot_all.sh
```

## System setup
Our experiments were performed **without** Docker. Still, we got the same results when we ran the experiments in Docker (on a Linux host) by using this image.

### Main Memory
We assume that sufficient main memory is available. Epsilon GC reserves 180 GiB of main memory while 160 GiB are pre-allocated. This can be adjusted in [benchmark/benchmark-execution](benchmark/benchmark-execution).

### CPU
We assume NUMA-awareness with non-overlapping cores. The database process is pinned to cores 2-22:2 (2, 4, 6, ..., 22) and OLTPBench is pinned to cores 24-44:2 (24, 26, 28, ..., 44). All of these cores should reside on *one* CPU (NUMA node). For measurements, disable simultaneous multithreading (SMT), Turbo Boost and all cores should operate in the performance P-State with a constant maximum CPU frequency.

The pinned cores can be configured in [benchmark/execution-helper](benchmark/execution-helper) (variables `taskset_db` and `taskset_oltpbench`).

### Disk
We assume that `/tmp` is mounted as *tmpfs*.

## Docker image
See [Dockerfile](Dockerfile) for all details about the image.

The environment variable `SOURCE_FROM_ONLINE` ([Dockerfile](Dockerfile)) controls whether to download the sources (e.g. MariaDB, PostgreSQL, ...) from the internet (`SOURCE_FROM_ONLINE=1`) or get them from a directory residing on disk (`SOURCE_FROM_ONLINE=0`). 

If `SOURCE_FROM_ONLINE` is set to `0`, the location of the expected directory (and its sources) can be adjusted in the scripts in [scripts/build](scripts/build). The default is a directory `sources` relative to this directory containing the following files:

- `mariadb.tar.bz2`
  - MariaDB source code (git).
- `postgres.tar.bz2`
  - PostgreSQL source code (git).
- `oltpbench.tar.bz2`
  - OLTPBenchmark source code (git).
- `openjdk16-hotspot.tar.gz`
  - HotSpot JVM downloaded from [AdoptOpenJDK.net](https://adoptopenjdk.net).
- `openjdk16-hotspot.tar.gz`
  - OpenJ9 JVM downloaded from [AdoptOpenJDK.net](https://adoptopenjdk.net).

### Restrictions
While benchmarking, before a database process is started, the file system buffer is flushed (`sync`) and the cache is cleared (`echo 3 > /proc/sys/vm/drop_caches`). As /proc is mounted as read-only file system and we execute inside a docker container, these commands have been commented out. To enable them, modify [benchmark/execution-helper](benchmark/execution-helper) (function `start_db`).

