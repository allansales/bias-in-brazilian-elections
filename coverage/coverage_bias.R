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

#2014
year = "2014"
search_words_2014 = c("pt","dilma","psdb","aécio","psb","marina")
coverage_bias_2014 = get_coverage_bias(year, search_words_2014)
coverage_bias_2014$entity_type = with(coverage_bias_2014, if_else(str_detect(entity,"p+") | entity == "rede", "party", "candidate"))

#2018
year = "2018"
search_words_2018 = c("pt","haddad","bolsonaro","rede","psl","marina","pdt","ciro")
coverage_bias_2018 = get_coverage_bias(year, search_words_2018)
coverage_bias_2018$entity_type = with(coverage_bias_2018, if_else(str_detect(entity,"p+") | entity == "rede", "party", "candidate"))

## HEATMAP PLOT
heatmap_plot = function(coverage_bias){
  
  ordered_coverage_bias = coverage_bias %>% select(entity, entity_type) %>% 
    distinct() %>% arrange(entity_type, entity) %>% 
    mutate(color = if_else(entity_type == "party", "red", "blue"))
  
  coverage_bias$entity <- factor(coverage_bias$entity, levels = ordered_coverage_bias$entity)
  
  hm <- ggplot(data = coverage_bias, aes(x = subFonte, y = entity, fill = cb)) + geom_tile() + 
    scale_fill_distiller(name = "Coverage", palette = "Reds", direction = 1, na.value = "transparent") +
    theme_bw() +
    theme(legend.position = "bottom", legend.direction = "horizontal",
          text = element_text(size = 15),
          axis.text.y = element_text(colour = ordered_coverage_bias$color),
          axis.text.x = element_text(angle = 15, hjust = 1)) +
    guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5)) + 
    labs(x = "", y = "", title = coverage_bias$year %>% unique())
  return(hm)
}

p1 <- heatmap_plot(coverage_bias_2010)
p2 <- heatmap_plot(coverage_bias_2014)
p3 <- heatmap_plot(coverage_bias_2018)

p = ggarrange(p1, p2, p3, ncol=2, nrow=2, common.legend = TRUE, legend="bottom")
ggsave("coverage_bias_heatmap.pdf", plot = p, device = "pdf", width = 6, height = 6)

## DOTPLOT PLOT
distributed_dot_plot = function(coverage_bias){
  ordered_coverage_bias = coverage_bias %>% select(entity, entity_type) %>% 
    distinct() %>% arrange(entity_type, entity)
  
  coverage_bias$entity <- factor(coverage_bias$entity, levels = ordered_coverage_bias$entity)
  
  ddp = ggplot(coverage_bias, aes(entity, cb)) + 
    geom_point(aes(color = subFonte, shape = coverage_bias$entity_type), size = 5) + 
    theme_bw() + 
    theme(
      text = element_text(size = 25),
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.title = element_text(size = 20),
      legend.text = element_text(size = 20)) +
    guides(fill = guide_colorbar(title.position = "top", title.hjust = 0.5)) + 
    labs(x = "", 
         y = "", 
         title = coverage_bias$year %>% unique(),
         shape = "Type",
         color = "Portal")
  
  return(ddp)
}

p1 <- distributed_dot_plot(coverage_bias_2010)
p2 <- distributed_dot_plot(coverage_bias_2014)
p3 <- distributed_dot_plot(coverage_bias_2018)

p = ggarrange(p1, p2, p3, ncol=3, nrow=1, common.legend = TRUE, legend="bottom")
p

ggsave("coverage_bias_dot_plot_wide.pdf", plot = p, device = "pdf", width = 18, height = 6)
