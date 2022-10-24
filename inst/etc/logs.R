# after https://cran.r-project.org/web/packages/log4r/vignettes/performance.html

# install.packages(c("log4r", "futile.logger","logging","logger","lgr","loggit","rlog"))

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
#           expr     min       lq      mean   median       uq      max neval
#          log4r  14.883  19.5365  24.19861  22.0170  27.6135   96.760   500
#            cat  32.308  36.6540  39.05324  38.3965  40.6720   69.782   500
#           rlog  28.577  35.2190  39.60756  38.7655  42.4760   92.660   500
#       *** tryr  46.658  57.2155  64.04569  62.0330  68.4905  136.161   500 ***
#         logger  91.102 113.7750 153.05021 123.6560 149.5270 3649.328   500
#        logging 206.804 238.1485 276.37854 252.9700 279.5380 3374.956   500
#         loggit 313.650 352.5385 416.03889 371.5420 419.9835 4192.865   500
#            lgr 591.220 641.8140 745.39255 673.9580 722.1535 4755.385   500
#  futile.logger 629.555 690.9320 783.79208 721.9075 786.7900 5028.568   500

# r$> print(debug_bench, order = "median")
# Unit: microseconds
#           expr     min       lq       mean  median       uq      max neval
#            cat   1.025   1.3530   1.542420   1.517   1.6400    9.471   500
#          log4r   1.312   1.8040   2.059184   2.009   2.2345   12.956   500
#           rlog   3.116   3.8130   4.445138   4.264   4.7970   15.375   500
#       *** tryr   4.920   5.8220   6.525806   6.355   6.9700   17.630   500 ***
#            lgr   7.175   8.3230   9.255832   9.020   9.6760   25.010   500
#        logging   8.610  10.2090  11.661876  11.316  12.3410   48.421   500
#         logger   9.512  11.0290  19.199234  11.972  12.9765 3466.099   500
#  futile.logger 188.846 199.1165 222.960870 203.196 214.1225 3406.772   500
