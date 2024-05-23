# after https://cran.r-project.org/web/packages/log4r/vignettes/performance.html

# install.packages(c("log4r", "futile.logger", "logging", "logger", "lgr", "loggit", "rlog"))

requireNamespace("tryr")
tryr_debug <- function() {
  tryr::msg(level = "DEBUG")
}
tryr_info <- function()  {
  tryr::msg("Info message.")
}

cat_debug <- function() {
  cat() # Print nothing.
}
cat_info <- function() {
    cat(
    "INFO  [", format(Sys.time(), "%Y-%m-%d %H:%M:%S", usetz = FALSE),
    "] Info message.", sep = "")
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
  times = 500,
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
  times = 500,
  control = list(warmups = 10)
)

print(info_bench, order = "median")

print(debug_bench, order = "median")

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
#           expr     min       lq      mean   median       uq       max neval
#       *** tryr   5.207   8.6510  12.52525  11.0290  14.3910   487.326   500 ***
#          log4r  15.047  20.7460  28.76232  25.6250  33.8865   515.411   500
#            cat  31.242  37.1050  41.84042  39.8725  43.2550   131.405   500
#           rlog  38.048  50.7170  60.31559  56.6415  65.7435   493.230   500
#         logger  99.876 131.5895 162.17673 154.3445 188.9895   694.171   500
#        logging 220.785 268.7345 352.64002 303.8715 340.7305  3993.318   500
#         loggit 311.067 367.1550 462.18308 416.1090 473.0375  4403.031   500
#            lgr 609.465 678.5910 843.33482 746.9995 826.5395 16420.828   500
#  futile.logger 647.431 716.7210 852.82673 782.8745 859.5855  6665.042   500

# r$> print(debug_bench, order = "median")
# Unit: microseconds
#           expr     min       lq       mean   median       uq      max neval
#            cat   1.107   1.4555   1.583010   1.5990   1.6810    4.551   500
#          log4r   1.312   1.7630   2.860980   1.9270   2.1320  437.675   500
#           rlog   2.993   3.6490   4.870800   4.1000   4.5920  349.525   500
#       *** tryr   4.838   5.5760   6.961308   6.0680   6.6830  390.115   500 ***
#            lgr   7.503   8.4460   9.994242   9.0610   9.6965  394.420   500
#        logging   8.856  10.2090  12.272202  11.0700  12.3820  413.608   500
#         logger   8.774  10.2090  12.287618  11.1520  12.2795  430.008   500
#  futile.logger 187.083 193.6020 219.642248 197.1485 201.6175 3496.603   500
