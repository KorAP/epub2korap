library(RKorAPClient)
library(tidyverse)
library(idsThemeR) # install with devtools::install_git("https://korap.ids-mannheim.de/gerrit/IDS-Mannheim/idsThemeR")
library(scales)
library(patchwork)

# Configuration and Constants
KORAP_URL <- "https://korap.dnb.de"
YEARS <- seq(1980, year(Sys.Date()))
SUMMARIZE_UP_TO <- 1000

GENRES_REGEX <- c(
  "Krimi" = "crime",
  "(Erotik|Gay)" = "erotic",
  "Western" = "western",
  "Arzt" = "doctor novel",
  "Liebes" = "romance",
  "Heimat" = "homeland",
  "(Horror|Grusel|Vampir)" = "horror",
  "Historisch" = "historic",
  "Fantasy" = "fantasy",
  "Science" = "science fiction",
  "Jugend" = "young adult",
  "Mystery" = "mystery"
)

establish_korap_connection <- function(url = KORAP_URL) {
  new("KorAPConnection", KorAPUrl = url, verbose = TRUE)
}

prepare_publication_year_statistics <- function(kco, years = YEARS, corpus = "") {
  # Expand grid of corpus and years
  df <- expand_grid(corpus = corpus, year = years) %>%
    mutate(vc = sprintf("%spubDate in %d", corpus, year)) %>%
    bind_cols(corpusStats(kco, .$vc) %>% select(-vc))

  # Handle early years consolidation
  min_year <- min((df %>% filter(tokens > 0))$year)
  summarize_up_to_year <- max((df %>% filter(documents < SUMMARIZE_UP_TO & year < 2015))$year)

  sdf <- df %>%
    filter(year <= summarize_up_to_year) %>%
    summarise(
      year = summarize_up_to_year,
      documents = sum(documents, na.rm = TRUE),
      tokens = sum(tokens, na.rm = TRUE),
      sentences = sum(sentences, na.rm = TRUE),
      paragraphs = sum(paragraphs, na.rm = TRUE)
    )

  # Combine and process dataframe
  df <- df %>%
    filter(year > summarize_up_to_year) %>%
    bind_rows(sdf) %>%
    mutate(year = ifelse(year == summarize_up_to_year, paste0(min_year, "–", summarize_up_to_year), as.character(year)))

  return(df)
}

create_publication_year_plots <- function(df, years) {
  p1 <- ggplot(df, aes(x = year, y = documents)) +
    geom_bar(stat = "identity") +
    scale_y_continuous(labels = label_number(scale_cut = cut_short_scale())) +
    labs(x = "year of publication", y = NULL) +
    coord_flip() +
    theme_ids(base_size = 14)

  p2 <- ggplot(df, aes(x = year, y = tokens)) +
    geom_bar(stat = "identity") +
    scale_y_continuous(labels = label_number(scale_cut = cut_short_scale())) +
    labs(x = NULL, y = NULL) +
    coord_flip() +
    theme_ids(base_size = 14)

  return(list(p1 = p1, p2 = p2))
}

# Prepare Genre Statistics
prepare_genre_statistics <- function(kco, genres_regex = GENRES_REGEX) {
  # Prepare genre statistics
  df <- expand_grid(corpus = "", genre = names(genres_regex)) %>%
    mutate(vc = sprintf("textType=/.*%s.*/", genre)) %>%
    bind_cols(corpusStats(kco, .$vc) %>% select(-vc))

  # Add total corpus statistics
  all_tokens <- corpusStats(kco, as.df = TRUE)$tokens
  all_documents <- corpusStats(kco, as.df = TRUE)$documents
  df <- df %>%
    add_row(genre = "other", documents = all_documents, tokens = all_tokens)

  # Prepare genre factors with English translations
  df <- df %>%
    mutate(genre_display = genres_regex[match(genre, names(genres_regex))]) %>%
    mutate(genre_display = ifelse(is.na(genre_display), "other", genre_display))

  return(df)
}

# Create Genre Plots
create_genre_plots <- function(df) {
  # Sort genres in a specific order with other at the bottom
  standard_genres <- setdiff(unique(df$genre_display), "other")
  genre_order <- c(standard_genres, "other")

  df$genre_display <- factor(
    df$genre_display,
    levels = rev(genre_order)
  )

  p3 <- ggplot(df, aes(x = genre_display, y = documents)) +
    geom_bar(stat = "identity") +
    scale_y_log10(labels = label_number(scale_cut = cut_short_scale())) +
    labs(x = "genre", y = "books") +
    coord_flip() +
    theme_ids(base_size = 14)

  p4 <- ggplot(df, aes(x = genre_display, y = tokens)) +
    geom_bar(stat = "identity") +
    coord_flip() +
    scale_y_log10(labels = label_number(scale_cut = cut_short_scale())) +
    labs(x = NULL, y = "words") +
    theme_ids(base_size = 14)

  return(list(p3 = p3, p4 = p4))
}

# Main Execution Function
generate_delico_composition_chart <- function() {
  # Establish connection
  kco <- establish_korap_connection()

  # Prepare data
  corpus_data <- prepare_publication_year_statistics(kco)
  publication_plots <- create_publication_year_plots(corpus_data, unique(corpus_data$year))

  genre_data <<- prepare_genre_statistics(kco)
  genre_plots <- create_genre_plots(genre_data)

  # Combine plots
  combined_plot <- publication_plots$p1 + publication_plots$p2 +
    genre_plots$p3 + genre_plots$p4 +
    plot_layout(ncol = 2, nrow = 2)

  # Save outputs
  ggsave("DeLiCoComposition.png", combined_plot, width = 2800, height = 2000, units = "px")
  ggsave("DeLiCoComposition.svg", combined_plot, width = 2800, height = 2000, units = "px")

  return(combined_plot)
}

# Run the script
print(generate_delico_composition_chart())
