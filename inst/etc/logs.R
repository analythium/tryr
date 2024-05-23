# after https://cran.r-project.org/web/packages/log4r/vignettes/performance.html

# install.packages(c("log4r", "futile.logger", "logging", "logger", "lgr", "loggit", "rlog"))

requireNamespace("tryr")
tryr_debug <- function() {
  tryr::msg("Debug message.", level = "DEBUG")
}
tryr_info <- function()  {
  tryr::msg("Info message.", level = "INFO")
}

cat_debug <- function() {
  if (isTRUE(FALSE)) {
    cat(
      "INFO  [", format(Sys.time(), "%Y-%m-%d %H:%M:%S", usetz = FALSE),
      "] Info message.", sep = "")
  } else {
    cat() # Print nothing.
  }
}
cat_info <- function() {
  if (isTRUE(TRUE)) {
    cat(
      "INFO  [", format(Sys.time(), "%Y-%m-%d %H:%M:%S", usetz = FALSE),
      "] Info message.", sep = "")
  } else {
    cat() # Print nothing.
  }
}
cat_debug <- compiler::cmpfun(cat_debug)
cat_info <- compiler::cmpfun(cat_info)

log4r_logger <- log4r::logger(threshold = "INFO")
log4r_info <- function() {
  log4r::info(log4r_logger, "Info message.")
}
log4r_debug <- function() {
  log4r::debug(log4r_logger, "Debug message.")
}

requireNamespace("futile.logger")
futile.logger::flog.logger()
fl_info <- function() {
  futile.logger::flog.info("Info message.")
}
fl_debug <- function() {
  futile.logger::flog.debug("Debug message.")
}

requireNamespace("logging")
logging::basicConfig()
logging_info <- function() {
  logging::loginfo("Info message.")
}
logging_debug <- function() {
  logging::logdebug("Debug message.")
}

requireNamespace("logger")
logger::log_appender(logger::appender_stdout)
logger_info <- function() {
  logger::log_info("Info message.")
}
logger_debug <- function() {
  logger::log_debug("Debug message.")
}

requireNamespace("lgr")
lgr_logger <- lgr::get_logger("perf-test")
lgr_logger$set_appenders(list(cons = lgr::AppenderConsole$new()))
lgr_logger$set_propagate(FALSE)
lgr_info <- function() {
  lgr_logger$info("Info message.")
}
lgr_debug <- function() {
  lgr_logger$debug("Debug message.")
}

requireNamespace("loggit")
if (.Platform$OS.type == "unix") {
  loggit::set_logfile("/dev/null")
} else {
  loggit::set_logfile("nul")
}
loggit_info <- function() {
  loggit::loggit("INFO", "Info message.")
}

requireNamespace("rlog")
rlog_info <- function() {
  rlog::log_info("Info message.")
}
rlog_debug <- function() {
  rlog::log_debug("Debug message.")
}

tryr_debug()
log4r_debug()
cat_debug()
logging_debug()
fl_debug()
logger_debug()
lgr_debug()
rlog_debug()

tryr_info()
log4r_info()
cat_info()
logging_info()
fl_info()
logger_info()
lgr_info()
loggit_info()
rlog_info()

info_bench <- microbenchmark::microbenchmark(
  cat = cat_info(),
  tryr = tryr_info(),
  log4r = log4r_info(),
  futile.logger = fl_info(),
  logging = logging_info(),
  logger = logger_info(),
  lgr = lgr_info(),
  loggit = loggit_info(),
  rlog = rlog_info(),
  times = 1000,
  control = list(warmups = 10)
)

debug_bench <- microbenchmark::microbenchmark(
  cat = cat_debug(),
  tryr = tryr_debug(),
  log4r = log4r_debug(),
  futile.logger = fl_debug(),
  logging = logging_debug(),
  logger = logger_debug(),
  lgr = lgr_debug(),
  rlog = rlog_debug(),
  times = 1000,
  control = list(warmups = 10)
)

print(info_bench, order = "median")

print(debug_bench, order = "median")

d <- data.frame(
  time = c(info_bench$time, debug_bench$time),
  expr = c(info_bench$expr, debug_bench$expr),
  level = factor(c(rep("INFO", length(info_bench[[1]])), rep("DEBUG", length(debug_bench[[1]])))))
op <- par(las = 1, mar = c(4, 10, 1, 1))
boxplot(log(time) ~ expr + level, d, horizontal = TRUE, col = rep(c(2, 4), c(9, 9)), ylab = "")
# boxplot(log(time) ~ level + expr, d, horizontal = TRUE, col = rep(c(2, 4), 9), ylab = "")
par(op)

## profile

Rprof(interval = 0.01)
replicate(1000, tryr_debug())
Rprof(NULL)
summaryRprof()

Rprof()
replicate(1000, tryr_info())
Rprof(NULL)
summaryRprof()


# r$> print(info_bench, order = "median")
# Unit: microseconds
#           expr     min       lq      mean   median       uq      max neval
#          log4r  14.350  19.3110  24.27548  22.5090  28.7615   95.161  1000
#            cat  31.447  36.2850  38.56173  38.2530  40.1390   72.242  1000
#           rlog  37.720  46.9655  55.23856  50.9220  55.3500 3377.908  1000
#           tryr  43.050  55.4730  65.53415  60.8235  67.8960 3457.735  1000 <===
#         logger  97.621 123.4715 147.47282 139.4410 159.8180 3494.963  1000
#        logging 227.140 259.3045 308.85329 281.0755 305.4500 5578.173  1000
#         loggit 310.739 354.9575 425.12859 384.2930 421.8900 4192.168  1000
#            lgr 597.206 664.0155 767.45079 699.9110 746.8765 5158.005  1000
#  futile.logger 627.095 697.4100 789.06894 738.9020 782.7515 4517.216  1000

# r$> print(debug_bench, order = "median")
# Unit: microseconds
#           expr     min       lq       mean   median       uq      max neval
#          log4r   1.312   1.7630   2.427651   1.9270   2.1730  425.826  1000
#            cat   1.353   1.7630   2.006950   2.0090   2.1525   24.190  1000
#           rlog   3.075   3.7310   4.668137   4.1820   4.6740  390.976  1000
#           tryr   3.403   4.0590   5.032627   4.5715   5.0840  377.364  1000 <===
#            lgr   7.462   8.6305  12.944848   9.2660   9.9220 2999.929  1000
#        logging   8.815  10.3730  12.209554  11.3980  12.5870  417.339  1000
#         logger   8.938  10.5780  12.133376  11.5210  12.5460  399.094  1000
#  futile.logger 187.124 195.7340 216.986145 200.0185 207.1935 3619.234  1000
