setwd("/tmp")
install.packages(c("dplyr", "tidyr", "foreach", "RPostgres", "magrittr", "futile.logger", "stringr", "readr", "DBI", "doParallel", "keyring", "checkmate", "rlang"), repos = "https://cran.rstudio.com/", Ncpus = 4)
system("R CMD INSTALL --build sdft")
install.packages(list.files(path = "/tmp", pattern="sdft_"), repos = NULL)