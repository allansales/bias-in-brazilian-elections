source("utils.R")
library("dplyr")
library("readr")
library("stringr")
library("ggplot2")
library("gridExtra")
library("grid")

interest_data = read_csv("news_data.csv")

# Coverage Bias
get_actual_value = function(search_word, year){
  interest_data_year = interest_data %>% filter(ano %in% c(year))
  total_news = interest_data_year %>% group_by(subFonte) %>% summarise(total = n())
  
  news_of_entity = interest_data_year %>% noticias_tema(search_word, "titulo")
  n_news_of_entity = news_of_entity %>% group_by(subFonte) %>% summarise(n_of_entity = n())
  
  news = n_news_of_entity %>% inner_join(total_news)
  news = news %>% mutate(actual = n_of_entity/total) %>% select(subFonte, actual)
  return(news)
}

get_coverage_bias = function(year, search_words){
  coverage_bias = data_frame()
  for(search_word in search_words){
    actual = get_actual_value(search_word, year)
    expected_mean = actual$actual %>% mean()
    expected_sd = actual$actual %>% sd()
    coverage_bias_entity = actual %>% mutate(cb = (actual - expected_mean)/expected_sd, entity = search_word, year = year)
    coverage_bias = coverage_bias %>% bind_rows(coverage_bias_entity)
  }
  return(coverage_bias)
}

#2010
year = "2010"
search_words_2010 = c("pt","psdb","pv","dilma","serra","marina")
coverage_bias_2010 = get_coverage_bias(year, search_words_2010)
coverage_bias_2010$entity_type = with(coverage_bias_2010, if_else(str_detect(entity,"p+") | entity == "rede", "party", "candidate"))
#write_csv(coverage_bias_2010, "coverage_bias_2010.csv")

#2014
year = "2014"
search_words_2014 = c("pt","dilma","psdb","aécio","psb","marina")
coverage_bias_2014 = get_coverage_bias(year, search_words_2014)
coverage_bias_2014$entity_type = with(coverage_bias_2014, if_else(str_detect(entity,"p+") | entity == "rede", "party", "candidate"))
#write_csv(coverage_bias_2014, "coverage_bias_2014.csv")

#2018
year = "2018"
search_words_2018 = c("pt","haddad","bolsonaro","rede","psl","marina","pdt","ciro")
coverage_bias_2018 = get_coverage_bias(year, search_words_2018)
coverage_bias_2018$entity_type = with(coverage_bias_2018, if_else(str_detect(entity,"p+") | entity == "rede", "party", "candidate"))
#write_csv(coverage_bias_2018, "coverage_bias_2018.csv")

grid_arrange_shared_legend <- function(...) {
  plots <- list(...)
  g <- ggplotGrob(plots[[1]] + theme(legend.position="bottom"))$grobs
  legend <- g[[which(sapply(g, function(x) x$name) == "guide-box")]]
  lheight <- sum(legend$height)
  grid.arrange(
    do.call(arrangeGrob, lapply(plots, function(x)
      x + theme(legend.position="none"))),
    legend,
    ncol = 1,
    heights = unit.c(unit(1, "npc") - lheight, lheight))
}

# plotting
p1 <- ggplot(coverage_bias_2010, aes(x = entity, weight = cb, color = entity_type)) +
  geom_bar(width = 0.5) + facet_wrap(~subFonte) + labs(x = "Entity", y = "Coverage Bias", 
                                                                    title = coverage_bias_2010$year %>% unique()) + theme(axis.text.x = element_text(angle = 90, hjust = 1)) + labs(colour= "Type")

p2 <- ggplot(coverage_bias_2014, aes(x = entity, weight = cb, color = entity_type)) +
  geom_bar(width = 0.5) + facet_wrap(~subFonte) + labs(x = "Entity", y = "Coverage Bias", 
                                                                    title = coverage_bias_2014$year %>% unique()) + theme(axis.text.x = element_text(angle = 90, hjust = 1)) + labs(colour= "Type")

p3 <- ggplot(coverage_bias_2018, aes(x = entity, weight = cb, color = entity_type)) +
  geom_bar(width = 0.5) + facet_wrap(~subFonte) + labs(x = "Entity", y = "Coverage Bias", 
                                                                   title = coverage_bias_2018$year %>% unique()) + theme(axis.text.x = element_text(angle = 90, hjust = 1)) + labs(colour= "ype")

#ggarrange(p1, p2, p3, ncol = 1, nrow = 3)

p = grid_arrange_shared_legend(p1, p2, p3)
ggsave("coverage_bias.pdf", plot = p, device = "pdf", width = 4, height = 8)
