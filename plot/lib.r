# Copyright 2021, Michael Fruth <michael.fruth@uni-passau.de>
# SPDX-License-Identifier: GPL-2.0-only

dat.queries.all <- function(dat) {
  tmp <- dat
  tmp$query <- "all queries"
  dat.plot <- rbind(dat, tmp)
  return(dat.plot)
}

paper.plot.dot <- function(dat, dat.safepoint, benchmark, 
                           sample.rate, delta,
                           sample.rate.per.query = NULL,
                           divisor.x = 1, divisor.y = 1000,
                           show.queries = NULL, show.gcs = NULL,
                           plot.height = NULL) {
  
  dat.plot <- dat %>% filter(benchmark == !!benchmark)
  dat.safepoint.plot <- dat.safepoint %>% filter(tag == "safepoint" & benchmark == !!benchmark)
  
  plot.query <- FALSE
  if (!is.null(show.queries) & !is.null(show.gcs)) {
    plot.query <- TRUE
    
    dat.plot <- dat.plot %>% filter(gc %in% show.gcs & query %in% show.queries)
    dat.plot$gc <- factor(dat.plot$gc, levels = show.gcs)
    dat.plot$query <- factor(dat.plot$query, levels = show.queries)
    
    dat.safepoint.plot <- dat.safepoint.plot %>% filter(gc %in% show.gcs)
    dat.safepoint.plot$gc <- factor(dat.safepoint.plot$gc, levels = show.gcs)
  } else {
    dat.plot$query <- str_c(benchmark, " (All)")
  }
  p <- gen.latency.plot.by.experiment(dat.plot, dat.safepoint.plot,
                                      sample.rate=sample.rate,
                                      sample.rate.per.query = sample.rate.per.query,
                                      delta=delta,
                                      divisor.x=divisor.x, divisor.y=divisor.y,
                                      plot.query=plot.query) +
    xlab("Time [s]") +
    scale_x_continuous(breaks=seq(0, 60, 15)) +
    ylab("Latency [ms]") +
    scale_y_log10() +
    annotation_logticks(sides='l', size=0.2, 
                        long=unit(1.2, "mm"), 
                        mid=unit(0.8, "mm"),
                        short=unit(0.4, "mm"),
                        outside = TRUE) +
    coord_cartesian(clip = "off")
  
  file_suffix <- ""
  file_height <- 11.5
  if (plot.query) {
    file_suffix <- str_c("_queries_", length(show.queries))  
    file_height <- 9.5
  }
  if(!is.null(plot.height)) {
    file_height <- plot.height
  }
  
  filename <- str_c(OUTDIR, "latencies_", benchmark, file_suffix, ".")
  
  ggsave(str_c(filename, "pdf"), p,
         width=PLOT.LNCS.WIDTH, 
         height=file_height,
         dpi=360, units="cm")
  #tikz(file=str_c(filename, "tex"), 
  #     width=PLOT.LNCS.WIDTH*INCH.PER.CM, 
  #     height=file_height*INCH.PER.CM)
  #print(p)
  #dev.off()
}

sample.plot <- function(dat, gc, query, sample.rate, delta) {
  dat.sub <- dat %>% filter(gc == !!gc & query == !!query)

  dat.sub$type="Extreme Value"
  dat.sub$rmean <- runmean(dat.sub$latency, 1000)
  
  bound.upper <- quantile(dat.sub$latency, 1-delta/2)
  bound.lower <- quantile(dat.sub$latency, delta/2)
  
  dat.sub.upper <- dat.sub %>% filter(latency >= bound.upper)
  dat.sub.lower <- dat.sub %>% filter(latency < bound.lower)
  
  # Sample everything without the quantiles which will be displayed for sure.
  dat.samp <- dat.sub %>% filter(latency < bound.upper & latency >= bound.lower)
  dat.samp  <- sample_frac(dat.samp, sample.rate)
  dat.samp$type <- "Standard Value"
  dat.plot <- rbind(dat.samp, dat.sub.upper, dat.sub.lower)
  
  return(dat.plot)
}

gen.latency.plot.by.experiment <- function(dat, dat.safepoint,
                                           sample.rate=0.001, delta=0.001,
                                           sample.rate.per.query=NULL,
                                           alpha.line=0.5, 
                                           divisor.x=1, divisor.y=1000, ncol=3,
                                           plot.query=FALSE) {
  
  dat.plot  <- rbindlist(lapply(unique(dat$gc), function(gc) {
    rbindlist(lapply(unique(dat$query), function(query) {
      query.sample.rate <- sample.rate
      
      if (!is.null(sample.rate.per.query)) {
        if(is.factor(dat$query)) {
          query.name <- levels(dat$query)[query]
          query.sample.rate <- sample.rate.per.query[query.name]
        } else {
          # Query contains the query name because no factor is used
          query.sample.rate <- sample.rate.per.query[query]
        }
      }
      if (is.na(query.sample.rate) | is.null(query.sample.rate)) {
        stop("Query Sample Rate is NA or NULL!")
      }
      
      sample.plot(dat, gc, query, query.sample.rate, delta)
    }))  
  }))  
  
  dat.safepoint.plot <- dat.safepoint
  
  dat.max  <- dat.plot %>% group_by(gc,query) %>% summarise(max=max(latency))
  dat.min  <- dat.plot %>% group_by(gc,query) %>% summarise(min=min(latency))
  dat.max  <- left_join(dat.plot, dat.max) %>% mutate(select = latency==max) %>% filter(select==TRUE) %>%
    select(idx, time, latency, query, type, gc, round)
  dat.min  <- left_join(dat.plot, dat.min) %>% mutate(select = latency==min) %>% filter(select==TRUE) %>%
    select(idx, time, latency, query, type, gc, round)
  
  g  <- ggplot(dat.plot, aes(x=idx/divisor.x, y=latency/divisor.y, colour=type))
  g <- g + geom_point_rast(size=0.25, shape=20)
  
  dat.safepoint.plot$type <- "GC Latency"
  dat.safepoint.plot$idx <- dat.safepoint.plot$start
  g <- g + geom_point(data=dat.safepoint.plot,
                      inherit.aes = TRUE,
                      size=0.6, shape=20)
  if (plot.query) {
    g <- g + facet_grid(query~gc)
  } else {
    g <- g + facet_wrap(gc~., ncol=2)
  }
  
  g  <- g + 
    scale_colour_manual("Observation", 
                        breaks = c("Standard Value", "Extreme Value", "GC Latency"),
                        values=c("#E69F00", "#999999", "#000000"),
                        guide=guide_legend(keywidth=2, 
                                           keyheight=2,
                                           default.unit="mm",
                                           override.aes = list(size=1))) +
    theme_paper() + theme(legend.position="top", 
          legend.box.margin = margin(-0.2, 0, -0.25, 0, "cm")) +
    geom_line(aes(x=idx/divisor.x, y=rmean/divisor.y), 
              size=0.2, 
              colour="red",
              alpha=alpha.line)
  
  g  <- g + 
    geom_point(data=dat.max, inherit.aes=TRUE, colour="red", shape=2, size=0.5) +
    geom_label_repel(data=dat.max, 
                     inherit.aes=TRUE, 
                     show.legend=FALSE,
                     size=LABEL.TEXT.SIZE,
                     aes(label=signif(latency/divisor.y,digits=3), hjust=0, vjust=0.5, alpha=0),
                     nudge_x=0.1,
                     label.padding=unit(0.25, "mm"), 
                     colour="black")
  
  g  <- g +
    geom_point(data=dat.min, inherit.aes=TRUE, colour="red", shape=2, size=0.5) +
    geom_label_repel(data=dat.min, 
                     inherit.aes=TRUE,
                     show.legend=FALSE,
                     size=LABEL.TEXT.SIZE,
                     aes(label=signif(latency/divisor.y,digits=3), hjust=1, vjust=0.5, alpha=0),
                     nudge_x=-0.1, 
                     label.padding=unit(0.25, "mm"),
                     colour="black")
  
  return(g)
}

theme_paper <- function() {
  return(theme_bw(base_size=BASE.SIZE) +
           theme(axis.title.x = element_text(size = BASE.SIZE),
                 axis.title.y = element_text(size = BASE.SIZE),
                 legend.title = element_text(size = BASE.SIZE)))
}


experiment.summary <- function(dat) {
  dat.summary <- dat %>% 
    group_by(gc, benchmark) %>% 
    summarise(
      rps=length(idx)/max(idx),
      min = min(latency),
      max = max(latency),
      p95 = quantile(latency, probs = 0.95),
      p99 = quantile(latency, probs = 0.99))
  
  dat.summary.larger <- pivot_longer(dat.summary, cols=c(min, max, p95, p99), 
                                     names_to = "metric", values_to = "value")
  
  return(list(summary=dat.summary, summaryLarge=dat.summary.larger))
}


plot.rps <- function(dat.summary) {
  p.bar <- ggplot(data = dat.summary, aes(x=gc, y = rps/1000)) +
    geom_bar(stat="identity", fill="#000000", width=0.6) +
    xlab("Garbage Collector") +
    ylab("kRequests / Second") +
    scale_y_log10(breaks=c(1, 3, 10, 100, 500)) +
    annotation_logticks(sides = "l",
                        size= 0.5,
                        long=unit(1.1, "mm"), 
                        mid=unit(0.8, "mm"),
                        short=unit(0.4, "mm"),
                        outside = TRUE) +
    coord_cartesian(clip = "off")
  
  p.bar <- p.bar + facet_wrap(benchmark~.)
  p.bar <- p.bar + theme_paper() + theme(legend.position="top",
                                         axis.text.x = element_text(angle = 35, hjust = 1),
                                         panel.border = element_rect(colour = "black", fill = NA))
  
  
  filename <- str_c(OUTDIR, "rps.")
  ggsave(str_c(filename, "pdf"), p.bar,
         width=PLOT.LNCS.WIDTH,
         height=5,
         dpi=360, units="cm")
  #tikz(file=str_c(filename, "tex"), 
  #     width=PLOT.LNCS.WIDTH*INCH.PER.CM, 
  #     height=5*INCH.PER.CM)
  #print(p.bar)
  #dev.off()
}

plot.distribution <- function(dat, dat.summary, dat.summary.large) {
  p.box <- ggplot(data = dat,
                  aes(x = fct_rev(benchmark), y = latency/divisor.y, 
                      color=fct_rev(gc))) +
    geom_boxplot(outlier.shape = NA) +
    xlab("Benchmark") +
    ylab("Latency [ms]") +
    scale_y_log10(labels = label_number(drop0trailing = TRUE)) +
    labs(color="Garbage Collector")
  
  p.box <- p.box + 
    geom_point(data=dat.summary.large, 
               aes(y = value/divisor.y, 
                   shape=fct_rev(metric), group=fct_rev(gc)),
               position=position_dodge(width=0.75)) +
    scale_shape_manual("Percentile",
                       labels = c("0th", "95th", "99th", "100th"),
                       values = c(2, 0, 1, 6))
  p.box <- p.box + 
    geom_label_repel(data=dat.summary,
                     aes(y=max/divisor.y, 
                         group=fct_rev(gc), fill=fct_rev(gc), 
                         label=signif(max/divisor.y,digits=3),
                         hjust=0, vjust=0.5),
                     position=position_dodge(width=0.75),
                     size=LABEL.TEXT.SIZE,
                     show.legend = FALSE,
                     inherit.aes = TRUE,
                     label.padding=unit(0.25, "mm"),
                     #Do not show the border because the border is white for a white color
                     label.size = NA, 
                     # Set segment color (the line pointing to a value) to black
                     segment.color = "black",
                     # Set colors manually for the contrast
                     color=c("white", "black", "black",
                             "black", "black", "white",
                             "white", "black", "black",
                             "black", "black", "white",
                             "white", "black", "black",
                             "black", "black", "white")) 
  
  p.box <- p.box + theme_paper() + theme(legend.position="top", 
                                         legend.direction = "horizontal",
                                         legend.box = "vertical", 
                                         legend.margin = margin(t=-0.2, b=-0.2, l=-1, unit="cm"),
                                         plot.margin = margin(0.2, 0.3, 0.1, 0.1, unit="cm"),
                                         # Remove grid
                                         panel.grid.major.y = element_blank(),
                                         panel.grid.minor.y = element_blank(),
                                         # Remove x axis labels (facet wrap shows the label)
                                         axis.text.y=element_blank(),
                                         axis.ticks.y=element_blank()
  )
  
  p.box <- p.box + guides(fill=guide_legend(nrow=1, byrow=TRUE))
  p.box <- p.box + coord_flip()
  # Define color palette on its own because we flip everything and everything should be reversed again.
  colors <- c("#000000", "#d8b365", "#E69F00", "#c7eae5", "#5ab4ac", "#01665e")
  p.box <- p.box +
    scale_color_manual(values = rev(colors), breaks=rev) +
    scale_fill_manual(values = rev(colors), breaks=rev)
  
  p.box <- p.box + facet_grid(benchmark~., scales="free", switch="both")
  filename <- str_c(OUTDIR, "percentiles.")
  ggsave(str_c(filename, "pdf"), p.box,
         width=PLOT.LNCS.WIDTH, 
         height=12, 
         dpi=360, units="cm")
  #tikz(file=str_c(filename, "tex"), 
  #     width=PLOT.LNCS.WIDTH*INCH.PER.CM, 
  #     height=12*INCH.PER.CM)
  #print(p.box)
  #dev.off()
}
