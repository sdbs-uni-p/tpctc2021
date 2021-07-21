# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>
# SPDX-License-Identifier: GPL-2.0-only

load.experiment <- function(benchmark.order=c("NoOp", "YCSB", "TPC-C"), round=1) {
  dat <- data.frame()
  dat.safepoint <- data.frame()
  for (EXPERIMENT in EXPERIMENTS) {
    datadir <- str_c(DATADIR.PREFIX, EXPERIMENT, DATADIR.SUFFIX)
    
    dat.exp <- data.frame()
    dat.safepoint.exp <- data.frame()
    for (gc in gc.list) {
      dat.exp <- rbind(dat.exp, read.gc(datadir, jvm.list, gc, verbose=TRUE, round=round))
      dat.safepoint.exp <- rbind(dat.safepoint.exp, read.gc.safepoint(datadir, jvm.list, gc, round=round))
    }
    dat.exp$benchmark <- EXPERIMENTS.LABELS[EXPERIMENT]
    dat.safepoint.exp$benchmark <- EXPERIMENTS.LABELS[EXPERIMENT]
    
    dat <- rbind(dat, dat.exp)
    dat.safepoint <- rbind(dat.safepoint, dat.safepoint.exp)
  }
  
  # Factor GC to keep order
  dat$round <- factor(dat$round)
  dat$gc <- factor(dat$gc, levels = gc.list)
  dat$benchmark <- factor(dat$benchmark, levels = benchmark.order)
  
  dat.safepoint$round <- factor(dat.safepoint$round)
  dat.safepoint$gc <- factor(dat.safepoint$gc, levels = gc.list)
  dat.safepoint$benchmark <- factor(dat.safepoint$benchmark, levels = benchmark.order)
  
  return(list(data=dat, safepoint=dat.safepoint))
}


read.gc.safepoint.openj9 <- function(gclogfile, gc) {
  timestamp.format <- "%Y-%m-%dT%H:%M:%OS"
  
  # It might be the case that metronome crashed
  data <- tryCatch(read_xml(gclogfile), error = function(e) e)
  if (inherits(data, "error")) {
    cat(str_c("[ERROR] Could not process file ", gclogfile, "\n",
              "File contains errors... the VM might have been crashed.. \n"))
    print(data)
    return(NULL)
  }
  data <- read_xml(gclogfile)
  data %>% xml_ns_strip()
  
  start.time <- xml_find_all(data, ".//initialized") %>% xml_attr("timestamp")
  start.time <- strptime(start.time, timestamp.format)
  
  if (tolower(gc) == "gencon") {
    measurements <- xml_find_all(data, ".//exclusive-end")
    latency <- xml_attr(measurements, "durationms")
    latency <- as.numeric(latency) * 1000 #ms into us
    
    time <- xml_attr(measurements, "timestamp")
    
    tag <- "safepoint"
    operation <- "TODO"
  } else if(tolower(gc) == "metronome") {
    measurements <- xml_find_all(data, ".//quanta")
    latency <- xml_attr(measurements, "maxTimeMs")
    latency <- as.numeric(latency) * 1000 # ms into us
    
    # Get parents -> <gc-op ...>
    time <- xml_parent(measurements)
    time <- xml_attr(time, "timestamp")
    
    tag <- "safepoint"
    operation <- xml_attr(measurements, "quantumType")
  } else {
    stop(str_c("GC: ", gc, " not supported. File: ", gclogfile))
  }
  
  time <- strptime(time, timestamp.format)
  time <- as.numeric(difftime(time, start.time, units = "secs"))
  
  return(data.frame(start=time, latency=latency, 
                    tag=tag, operation=operation))
}

read.gc.safepoint.hotspot <- function(gclogfile) {
  con = file(gclogfile, "r")
  lines <- readLines(con)
  close(con)
  
  # Skip first line (contains GC value), e.g.: [0.015s][info][gc] Using G1
  lines <- lines[-1]
  
  dat <- data.frame(matrix(ncol=4, nrow=0))
  colnames(dat) <- c("start", "latency",
                     "tag", "operation")
  for (line in lines) {
    # Line: "[0.015s][info][gc             ] GC(1) Pause Young (Normal) (G1 Evacuation Pause) 126M->40M(2056M) 4.188ms"
    # Info: "[0.015s][info][gc             ]"
    line.info <- str_extract(line, "^\\[.*?\\]\\[.*?\\]\\[.*?\\]")
    # Message: "GC(1) Pause Young (Normal) (G1 Evacuation Pause) 126M->40M(2056M) 4.188ms"
    line.message <- str_trim(substr(line, nchar(line.info) + 1, nchar(line)))
    
    line.info.match <- str_match_all(line.info, "\\[.*?\\]")
    # "[0.015s]"
    line.info.time <- line.info.match[[1]][1,1]
    # "[info]"
    line.info.level <- line.info.match[[1]][2,1]
    # "[gc             ]"
    line.info.tag <- line.info.match[[1]][3,1]
    
    # Replace ALL [ and ]
    regex.replace.square.bracket <- "(\\[|\\])"
    line.info.time <- str_trim(gsub(regex.replace.square.bracket, "", line.info.time))
    line.info.time <- as.double(gsub("s", "", line.info.time)) # Time in seconds
    line.info.level <- str_trim(gsub(regex.replace.square.bracket, "", line.info.level))
    line.info.tag <- str_trim(gsub(regex.replace.square.bracket, "", line.info.tag))
    
    if (line.info.tag == "gc" && gc == "G1") {
      # Only G1 GC contains the time - the other GC's do not contain this..
      
      # [[1]]
      # [1] "GC(1)"            "Pause"            "Young"            "(Normal)"         "(G1"              "Evacuation"      
      # [7] "Pause)"           "126M->40M(2056M)" "4.188ms" 
      # Get last element, 4.188ms
      latency <- tail(str_split(line.message, " ")[[1]], n=1)
      if (!grepl("Pause", line.message, fixed = TRUE) | !str_detect(latency, "([0-9]+\\.)?[0-9]+ms")) {
        # E.g. Line can be: "[57.475s][info][gc             ] GC(40) Concurrent Mark Cycle"
        # or: [18.689s][info][gc             ] GC(28) Concurrent Mark Cycle 20.632ms
        # Skip this
        next
      }
      latency <- as.double(gsub("ms", "", latency))
      latency <- latency * 1000 # Convert MS to US
      operation <- "GC"
    } else if (line.info.tag == "safepoint,stats") {
      line.info.tag <- "safepoint"
      # "[0.546s][info][safepoint,stats] VM Operation                 [ threads: total initial_running ][ time:       sync    cleanup       vmop      total ] page_trap_count
      # "[90.264s][info][safepoint,stats] Cleanup                      [             15               3 ][            65644      40623       5770     112037 ]               0"
      
      # Match up to the first "["
      # "Cleanup                      ["
      line.message.info <- str_match(line.message, ".*?\\[")[1,1]
      if (is.na(line.message.info) | is.na(str_match(line.message, "^.*\\[.*\\]\\[.*\\].*[0-9]+$"))) {
        # First condition: Make sure that the line contains the pattern "... ["
        # Second condition: Make sure that the line contains the information we need/want: "... [...][...] ...."
        # E.g.:
        # Skip: "ICBufferFull                       148"
        # Skip: "Maximum vm operation time (except for Exit VM operation)  23627394 ns"
        # Keep: "ICBufferFull     [             15               3 ][            65644      40623       5770     112037 ]               0"
        
        next
      }
      
      # "Cleanup                      "
      line.message.info <- str_sub(line.message.info, 0, nchar(line.message.info) -1) # Remove last "["
      
      # Remove the line.message.info
      #[             15               3 ][            65644      40623       5770     112037 ]               0"
      line.message <- str_sub(line.message, nchar(line.message.info) + 1, nchar(line.message))
      
      # trim message info; DO NOT execute this BEFORE line.message was splitted.
      # "Cleanup"
      line.message.info <- str_trim(line.message.info)
      if (line.message.info == "VM Operation") {
        # This is just the summary line
        next
      }
      
      # Match all numbers: 15 3 65644 40623 5770 112037 0
      line.message.match <- str_match_all(line.message, "[0-9]+")[[1]]
      # [ threads: total initial_running ]
      line.message.threads.total <- as.double(line.message.match[1,1])
      line.message.threads.initial.running <- as.double(line.message.match[2,1])
      # [ time:       sync    cleanup       vmop      total ]
      line.message.time.sync <- as.double(line.message.match[3,1])
      line.message.time.cleanup <- as.double(line.message.match[4,1])
      line.message.time.vmop <- as.double(line.message.match[5,1])
      line.message.time.total <- as.double(line.message.match[6,1])
      # page_trap_count
      line.message.page.trap.count <- as.double(line.message.match[7,1])
      
      latency <- line.message.time.total / 1000 # Convert from NS to US
      operation <- line.message.info
    } else {
      next
    }
    
    dat <- rbind(dat, data.frame(start=line.info.time, latency=latency, 
                                 tag=line.info.tag, operation=operation))
  }
  return(dat)
}

read.gc.safepoint <- function(datadir, jvm.list, gc, round=1,
                              benchmark.warmup=10, benchmark.duration=60) {
  res <- rbindlist(lapply(jvm.list, function(jvm) {
    safepointfile <- str_c(datadir, "openjdk16-", jvm, "_", gc, "_", round, ".gc.log")
    if(!file.exists(safepointfile)) {
      cat("File does not exist: ", safepointfile, "\n")
      return(NULL)
    }
    
    if (tolower(jvm) == tolower(OPENJ9JVM)) {
      dat <- read.gc.safepoint.openj9(safepointfile, gc)
      if (tolower(gc) == "gencon") {
        benchmark.warmup <- benchmark.warmup + 2 # ~2 Seconds delay from JVM startup until benchmark
      } else if(tolower(gc) == "metronome") {
        benchmark.warmup <- benchmark.warmup + 4 # ~4 Seconds delay from JVM startup until benchmark
      }
    } else {
      # Hotspot etc.
      dat <- read.gc.safepoint.hotspot(safepointfile)
    }
    
    if (is.null(dat)) {
      return(NULL)
    }
    
    dat$gc <- gc
    dat$jvm <- jvm
    dat$round <- round
    
    dat <- dat[dat$start > benchmark.warmup & dat$start < benchmark.warmup + benchmark.duration,]
    dat$start <- dat$start - benchmark.warmup
    # Start = Seconds (s)
    # Latency = Microseconds (us)
    return(dat)
  }))
  return(res)
}

read.gc <- function(datadir, jvm.list, gc, verbose=FALSE, round=1, nrows=Inf,
                    sample.rate=0.001, sample.delta=0.001,
                    gc.read=FALSE, gc.warmup=10, gc.duration=60) {
  res <- rbindlist(lapply(jvm.list, function(jvm) {
    file <- str_c(datadir, "openjdk16-", jvm, "_", gc, "_", round, ".csv")
    
    if (verbose) {
      cat ("Processing ", file, " (limited to ", nrows, " entries)\n")
    }
    
    if (!file.exists(file)) {
      cat ("File ", file, " does not exist!\n")
    } else {
      res <- fread(file, header=TRUE, nrows=nrows)
      
      res.time <- res$'Start Time (microseconds)'
      dat <- data.table(idx=(res.time - min(res.time)), time=res$'Start Time (microseconds)', latency=res$'Latency (microseconds)',
                        jvm=jvm, query=res$'Transaction Name', gc=gc, round=round)
      
      return(dat)
    }
  }))
  
  return(res)
}
