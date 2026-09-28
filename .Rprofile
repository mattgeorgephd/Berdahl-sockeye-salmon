source("renv/activate.R")

# renv/activate.R restores the repositories recorded in renv.lock, so this must
# come *after* it -- and it must amend the CRAN entry rather than replace the
# whole vector, which would drop the Bioconductor 3.18 repositories.
#
# CRAN is pinned to a dated Posit Package Manager snapshot contemporary with
# Bioconductor 3.18, the release matching this project's R 4.3.2. Without the
# date, renv resolves "cran/latest", whose sources increasingly require
# R >= 4.5 and fail to compile here (Deriv 4.3.0 was the first to break).
#
# Pinning the date is the point of the exercise: it makes "which CRAN" a
# recorded fact rather than "whatever was current the day you ran it". If you
# deliberately move this project to a newer R, change this date and the
# Bioconductor version together, then re-snapshot.
local({
  repos <- getOption("repos")
  repos["CRAN"] <- "https://packagemanager.posit.co/cran/2024-04-24"
  options(repos = repos)
})
