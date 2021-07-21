#! /usr/bin/env -S Rscript --vanilla

# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>
# SPDX-License-Identifier: GPL-2.0-only

options(install.packages.compile.from.source = "always")

renv::init(force = TRUE)
renv::update()
renv::snapshot()
