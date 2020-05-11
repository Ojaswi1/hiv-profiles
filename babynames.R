library(tidyverse)
library(babynames)
library(glue)

# plot total US births
applicants %>%
  mutate(
    sex = if_else(sex == "F", "Female", "Male"),
    n_all = n_all / 1e06
  ) %>%
  ggplot(mapping = aes(x = year, y = n_all, fill = sex)) +
  #I changed the plot to geom_area instead of geom_ribbon and filled the y-aesthetic as n_all
  geom_area(aes(y = n_all)) +
  scale_fill_brewer(type = "qual") +
  labs(
    title = "Total US births",
    x = "Year",
    y = "Millions",
    fill = NULL,
    caption = "Source: Social Security Administration"
  ) +
  theme_minimal()


# write function to show trends over time for specific name
name_trend <- function(person_name) {
  babynames %>%
    filter(name == person_name) %>%
    ggplot(mapping = aes(x = year, y = n, color = sex)) +
    geom_line() +
    scale_color_brewer(type = "qual") +
    labs(
      #Put quotations around the title string
      title = glue("Name: {person_name}"),
      x = "Year",
      y = "Number of births",
      color = NULL
    ) +
    theme_minimal()
}

name_trend("Benjamin")

# write function to show trends over time for top N names in a specific year
  
#To expand the color palette to have 20 colors and not 12 colors
nb.cols <- 20
mycolors <- colorRampPalette(RColorBrewer::brewer.pal(12, "Set3"))(nb.cols)

top_n_trend <- function(n_year, n_rank = 5) {
  # create lookup table
  top_names <- babynames %>%
    group_by(name, sex) %>%
    #Replaced sum(count) with sum(n) as the error was invalid type (closure) i.e. count was being called while summarising count itself
    summarize(count = as.numeric(sum(n))) %>%
    filter(count > 1000) %>%
    select(name, sex)
  
  # filter babynames for top_names
  filtered_names <- babynames %>%
    inner_join(top_names)
  
  # get the top N names from n_year
  top_names <- filtered_names %>%
    filter(year == n_year) %>%
    group_by(name, sex) %>%
    #Replaced sum(count) with sum(n)
    summarize(count = sum(n)) %>%
    group_by(sex) %>%
    mutate(rank = min_rank(desc(count))) %>%
    filter(rank < n_rank) %>%
    arrange(sex, rank) %>%
    select(name, sex, rank)
  
  # keep just the top N names over time and plot
  filtered_names %>%
    inner_join(select(top_names, sex, name)) %>%
    #Replaced y = count with y = n
    ggplot(mapping = aes(x = year, y = n, color = name)) +
    facet_wrap(~sex, ncol = 1) +
    geom_line() +
    #Used the mycolors defined before to have 20 colors and not the 12 that are included in Set3
    scale_color_manual(values = mycolors) +
    labs(
      title = glue("Most Popular Names of {n_year}"),
      x = "Year",
      y = "Number of births",
      color = "Name"
    ) +
    theme_minimal()
}

top_n_trend(n_year = 1986)
top_n_trend(n_year = 2014)
top_n_trend(n_year = 1986, n_rank = 10)

# compare naming trends to disney princess film releases
disney <- tribble(
  #Added "~" in front of the column names
  ~"princess",  ~"film", ~"release_year",
  "Snow White", "Snow White and the Seven Dwarfs", 1937,
  "Cinderella", "Cinderella", 1950,
  "Aurora", "Sleeping Beauty", 1959,
  "Ariel", "The Little Mermaid", 1989,
  "Belle", "Beauty and the Beast", 1991,
  "Jasmine", "Aladdin", 1992,
  "Pocahontas", "Pocahontas", 1995,
  "Mulan", "Mulan", 1998,
  "Tiana", "The Princess and the Frog", 2009,
  "Rapunzel", "Tangled", 2010,
  "Merida", "Brave", 2012,
  "Elsa", "Frozen", 2013,
  "Moana", "Moana", 2016
)

## join together the data frames
babynames %>%
  # ignore men named after princesses - is this fair?
  #hard to catch! - the "" around F was missing
  filter(sex == "F") %>%
  inner_join(disney, by = c("name" = "princess")) %>%
  mutate(name = fct_reorder(.f = name, .x = release_year)) %>%
  # plot the trends over time, indicating release year
  ggplot(mapping = aes(x = year, y = n)) +
  #I removed the () after label_both so it does not expect arguement "labels"
  facet_wrap(~ name + film, scales = "free_y", labeller = label_both) +
  geom_line() +
  geom_vline(mapping = aes(xintercept = release_year), linetype = 2, alpha = .5) +
  scale_x_continuous(breaks = c(1880, 1940, 2000)) +
  theme_minimal() +
  labs(title = "Popularity of Disney princess names",
       x = "Year",
       y = "Number of births")
