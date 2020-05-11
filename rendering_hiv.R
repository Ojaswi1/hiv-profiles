library(tidyverse)
library(rmarkdown)

#To create a unique list of all unqiue iso3 countries
all_iso3 <- unique(hiv$iso3)

#Created a folder (directory) with the name reports
dir.create("reports")

#creating a data frame that has one row for each iso3 country, giving the filename of the report and the params
all_reports <- tibble(
  output_file = stringr::str_c(all_iso3, ".html"),
  params = map(all_iso3, ~list(my_iso3 = .))
)

#matching the column names to argument names of render(), and using purrr’s parallel walk to call render() once for each row:
all_reports %>%
  pwalk(rmarkdown::render, 
        input = "hiv-profile.Rmd",
        output_dir = "reports")