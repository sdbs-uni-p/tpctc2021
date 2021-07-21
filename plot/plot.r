#!/usr/bin/env -S Rscript --vanilla
# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>
# SPDX-License-Identifier: GPL-2.0-only

renv::activate()

args = commandArgs(trailingOnly=TRUE)
source("base.r")
source("load_data.r")

plot.online.repository <- TRUE

# args <- c(1, "mariadb")
# args <- c(1, "postgres")

if (length(args) != 2) {
  stop("Not enough arguments. Please run: <round> <database>\n")
}

round <- strtoi(args[1])
database <- args[2]

if(!is.numeric(round) | is.na(round)) {
  stop(str_c("Round (<round>) '", args[1], "' must be a number!"))
}

EXPERIMENTS <- c(
  str_c(database, "-noop"),
  str_c(database, "-ycsb"),
  str_c(database, "-tpcc")
)
EXPERIMENTS.LABELS <- setNames(c("NoOp", "YCSB", "TPC-C"), EXPERIMENTS)

OUTDIR <- str_c(OUTDIR, database, "_")

exp <- load.experiment(round=round)
dat <- exp$data
dat.safepoint <- exp$safepoint
exp <- NULL

exp.summary <- experiment.summary(dat)
dat.summary <- exp.summary$summary
dat.summary.large <- exp.summary$summaryLarge
exp.summary <- NULL

dat.summary.large$metric <- factor(dat.summary.large$metric, levels=c("max", "p99", "p95", "min"))

divisor.y <- 1000

plot.rps(dat.summary)
plot.distribution(dat, dat.summary, dat.summary.large)

default.delta <- 0.001
paper.plot.dot(dat, dat.safepoint, "NoOp", sample.rate=0.00001, delta=0.0005)
paper.plot.dot(dat, dat.safepoint, "YCSB", sample.rate=0.0001, delta=0.0005)
paper.plot.dot(dat, dat.safepoint, "TPC-C", sample.rate=0.001, delta=0.005)

show.gcs <- c("G1", "Z", "Epsilon", "gencon")

show.ycsb.queries <- c("ReadRecord", "UpdateRecord")
sample.rate.per.query.ycsb <- c("ReadRecord" = 0.0005,
                                "UpdateRecord" = 0.001)
paper.plot.dot(dat, dat.safepoint, "YCSB", sample.rate=0.0001, delta=0.0005,
               sample.rate.per.query = sample.rate.per.query.ycsb,
               show.queries = show.ycsb.queries, show.gcs = show.gcs)

show.tpcc.queries <- c("NewOrder", "OrderStatus")
sample.rate.per.query.tpcc <- c("NewOrder" = 0.005,
                                "OrderStatus" = 0.05)
paper.plot.dot(dat, dat.safepoint, "TPC-C", sample.rate=0.001, delta=0.005,
               sample.rate.per.query = sample.rate.per.query.tpcc,
               show.queries = show.tpcc.queries, show.gcs = show.gcs)



if (plot.online.repository) {
  tmp <- PLOT.LNCS.WIDTH
  PLOT.LNCS.WIDTH <- 18
  show.gcs <- c("G1", "Z", "Shenandoah", "Epsilon", "gencon", "metronome")
  
  show.ycsb.queries <- c("ReadRecord", "InsertRecord", "ScanRecord", "UpdateRecord", "DeleteRecord", "ReadModifyWriteRecord")
  sample.rate.per.query.ycsb <- c("ReadRecord" = 0.0005,
                                  "InsertRecord" = 0.001,
                                  "ScanRecord" = 0.001,
                                  "UpdateRecord" = 0.001,
                                  "DeleteRecord" = 0.001,
                                  "ReadModifyWriteRecord" = 0.001)
  paper.plot.dot(dat, dat.safepoint, "YCSB", sample.rate=0.0001, delta=0.0005,
                 sample.rate.per.query = sample.rate.per.query.ycsb,
                 show.queries = show.ycsb.queries, show.gcs = show.gcs, plot.height = 16)
  
  # These are just for the online repository
  show.tpcc.queries <- c("NewOrder", "Payment", "OrderStatus", "Delivery", "StockLevel")
  sample.rate.per.query.tpcc <- c("NewOrder" = 0.005,
                                  "Payment" = 0.005,
                                  "OrderStatus" = 0.05,
                                  "Delivery" = 0.05,
                                  "StockLevel" = 0.05)
  paper.plot.dot(dat, dat.safepoint, "TPC-C", sample.rate=0.001, delta=0.005,
                 sample.rate.per.query = sample.rate.per.query.tpcc,
                 show.queries = show.tpcc.queries, show.gcs = show.gcs, plot.height = 14)
  PLOT.LNCS.WIDTH <- tmp
}
