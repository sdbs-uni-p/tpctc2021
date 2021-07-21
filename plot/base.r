# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>
# SPDX-License-Identifier: GPL-2.0-only

library(ggplot2)
library(stringr)
library(plyr)
library(dplyr)
library(tidyr)
library(data.table)
library(reshape2)
library(caTools)
library(xtable)
library(scales)
library(ggrepel)
library(ggrastr)
# XML
library(xml2)
# Color palettes
library(ggsci)
# Reverse factor levels
library(forcats)
#library(tikzDevice)
#options("tikzLatex"='/usr/bin/latex')

options(scipen=5)

OUTDIR <- str_c("/home/repro/measure/plots/")
DATADIR.PREFIX <- str_c("/home/repro/measure/results/")
DATADIR.SUFFIX <- str_c("/results/")
#datadir <- str_c(DATADIR.PREFIX, EXPERIMENT, DATADIR.SUFFIX)

OPENJ9JVM <- "openj9"
HOTSPOTJVM <- "hotspot"
jvm.list <- c(HOTSPOTJVM, OPENJ9JVM) ##
gc.list  <- c("G1", "Z", "Shenandoah", "Epsilon", "gencon", "metronome") ## 

INCH.PER.CM <- 0.394
BASE.SIZE <- 9
LABEL.TEXT.SIZE <- 2.5
PLOT.LNCS.WIDTH <- 12.2

source("lib.r")
