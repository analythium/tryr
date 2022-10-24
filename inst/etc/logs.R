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
