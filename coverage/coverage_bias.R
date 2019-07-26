source("utils.R")
library("dplyr")
library("readr")
library("anytime")
library("stringr")
library("ggpubr")
library("gridExtra")
library("grid")
library("exactRankTests")

interest_data = read_csv("news_data.csv")

#news_veja %>% filter(ano %in% c("2010","2014","2018"), caderno %in% c("politica","economia")) %>% group_by(ano) %>% summarise(n = n())

# Coverage Bias
get_actual_value = function(search_word, year, include_month){
  
  interest_data_year = interest_data %>% filter(ano %in% c(year))
  news_of_entity = interest_data_year %>% noticias_tema(search_word, "titulo")
  
  if(!include_month){
    total_news = interest_data_year %>% group_by(subFonte) %>% summarise(total = n())  
    n_news_of_entity = news_of_entity %>% group_by(subFonte) %>% summarise(n_of_entity = n())
  } else {
    total_news = interest_data_year %>% group_by(subFonte, mes) %>% summarise(total = n())
    n_news_of_entity = news_of_entity %>% group_by(subFonte, mes) %>% summarise(n_of_entity = n())
    
    seq_min = n_news_of_entity$mes %>% min()
    seq_max = n_news_of_entity$mes %>% max()
    
    month_reference = expand.grid(c("FOLHASP","ESTADAO","CartaCapital"), seq(seq_min, seq_max), stringsAsFactors = F)
    colnames(month_reference) = c("subFonte", "mes")
    month_reference$mes = month_reference$mes %>% as.double()
    
    miss_months = anti_join(month_reference, n_news_of_entity)
    miss_months = miss_months %>% mutate(n_of_entity = 0)
    n_news_of_entity = miss_months %>% bind_rows(n_news_of_entity)
  }
  
  news = n_news_of_entity %>% inner_join(total_news)
  news = news %>% mutate(actual = n_of_entity/total)# %>% select(subFonte, actual)
  
  return(news)
}

get_coverage_bias = function(year, search_words, include_month){
  coverage_bias = data_frame()
  for(search_word in search_words){
    actual = get_actual_value(search_word, year, include_month)
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

coverage_bias_2010 = get_coverage_bias(year, search_words_2010, include_month = F)
coverage_bias_2010$entity_type = with(coverage_bias_2010, if_else(str_detect(entity,"p+") | entity == "rede", "party", "candidate"))

coverage_bias_2010_by_month = get_coverage_bias(year, search_words_2010, include_month = T)
coverage_bias_2010_by_month$entity_type = with(coverage_bias_2010_by_month, if_else(str_detect(entity,"p+") | entity == "rede", "party", "candidate"))

#2014
year = "2014"
search_words_2014 = c("pt","dilma","psdb","aécio","psb","marina")
coverage_bias_2014 = get_coverage_bias(year, search_words_2014, include_month = F)
coverage_bias_2014$entity_type = with(coverage_bias_2014, if_else(str_detect(entity,"p+") | entity == "rede", "party", "candidate"))

coverage_bias_2014_by_month = get_coverage_bias(year, search_words_2014, include_month = T)
coverage_bias_2014_by_month$entity_type = with(coverage_bias_2014_by_month, if_else(str_detect(entity,"p+") | entity == "rede", "party", "candidate"))

#2018
year = "2018"
search_words_2018 = c("pt","haddad","bolsonaro","rede","psl","marina","pdt","ciro")
coverage_bias_2018 = get_coverage_bias(year, search_words_2018, include_month = F)
coverage_bias_2018$entity_type = with(coverage_bias_2018, if_else(str_detect(entity,"p+") | entity == "rede", "party", "candidate"))

coverage_bias_2018_by_month = get_coverage_bias(year, search_words_2018, include_month = T)
coverage_bias_2018_by_month$entity_type = with(coverage_bias_2018_by_month, if_else(str_detect(entity,"p+") | entity == "rede", "party", "candidate"))

coverage_bias = bind_rows(coverage_bias_2010, coverage_bias_2014, coverage_bias_2018)

# ## significance test
# get_p_value = function(x){
#   x$p.value
# }
# 
# significant_difference_inside_outlet = function(outlet){
#   
#   get_significance = function(ent_type, outlet){
#     ent = outlet %>% filter(entity_type == ent_type) %>% select(entity) %>% unique() %>% as_vector()
#     comb = combinat::combn(ent, 2) %>% as_data_frame() %>% t()
#     colnames(comb) = c("entity_1","entity_2")
#     sign = apply(comb, 1, FUN = function(x){
#       cb1 = outlet %>% filter(entity == x[1]) %>% select(cb) %>% as_vector()
#       cb2 = outlet %>% filter(entity == x[2]) %>% select(cb) %>% as_vector()
#       return(wilcox.exact(cb1, cb2, paired = T, alternative = "two.sided"))
#     })  
#     p_values = sapply(sign, get_p_value)
#     comb %>% cbind(p.value = p_values)
#   }
#   
#   sign_can = get_significance("candidate", outlet)
#   sign_par = get_significance("party", outlet)
#   rbind(sign_par, sign_can)
# }
# 
# significant_difference_across_outlets = function(cb_frame){
#   entities = cb_frame$entity %>% unique()
#   outlets = cb_frame$subFonte %>% unique()
#   comb = combinat::combn(outlets, 2) %>% as_data_frame() %>% t()
#   
#   sign_across_outlets_by_entity = function(entity_name, cb_frame){
#     entity_name = entity_name %>% as.character()
#     entity_cb = cb_frame %>% filter(entity == entity_name)
#     sign = apply(comb, 1, FUN = function(x){
#       cb1 = entity_cb %>% filter(subFonte == x[1]) %>% select(cb) %>% as_vector()
#       cb2 = entity_cb %>% filter(subFonte == x[2]) %>% select(cb) %>% as_vector()
#       return(wilcox.exact(cb1, cb2, paired = T, alternative = "two.sided"))
#     })
#     p_values = sapply(sign, get_p_value)
#     comb %>% cbind(p.value = p_values, entity = entity_name)
#   }
#   
#   signs = lapply(entities, sign_across_outlets_by_entity, cb_frame) %>% do.call(what = rbind)
# }
# 
# # 2018
# coverage_bias_2018_by_month$entity = as.factor(coverage_bias_2018_by_month$entity)
# coverage_bias_2018_by_month$subFonte = as.factor(coverage_bias_2018_by_month$subFonte)
# 
# estadao = coverage_bias_2018_by_month %>% filter(subFonte == "ESTADAO")
# estadao_in_18 = significant_difference_inside_outlet(estadao)
# 
# folhasp = coverage_bias_2018_by_month %>% filter(subFonte == "FOLHASP")
# folhasp_in_18 = significant_difference_inside_outlet(folhasp)
# 
# carta = coverage_bias_2018_by_month %>% filter(subFonte == "CartaCapital")
# carta_in_18 = significant_difference_inside_outlet(carta)
# 
# veja = coverage_bias_2018_by_month %>% filter(subFonte == "VEJA")
# veja_in_18 = significant_difference_inside_outlet(veja)
# 
# across_18 = significant_difference_across_outlets(coverage_bias_2018_by_month)
# 
# # 2014
# coverage_bias_2014_by_month$entity = as.factor(coverage_bias_2014_by_month$entity)
# coverage_bias_2014_by_month$subFonte = as.factor(coverage_bias_2014_by_month$subFonte)
# 
# estadao = coverage_bias_2014_by_month %>% filter(subFonte == "ESTADAO")
# estadao_in_14 = significant_difference_inside_outlet(estadao)
# 
# folhasp = coverage_bias_2014_by_month %>% filter(subFonte == "FOLHASP")
# folhasp_in_14 = significant_difference_inside_outlet(folhasp)
# 
# carta = coverage_bias_2014_by_month %>% filter(subFonte == "CartaCapital")
# carta_in_14 = significant_difference_inside_outlet(carta)
# 
# veja = coverage_bias_2014_by_month %>% filter(subFonte == "VEJA")
# veja_in_14 = significant_difference_inside_outlet(veja)
# 
# 
# across_14 = significant_difference_across_outlets(coverage_bias_2014_by_month)
# 
# # 2010
# coverage_bias_2010_by_month$entity = as.factor(coverage_bias_2010_by_month$entity)
# coverage_bias_2010_by_month$subFonte = as.factor(coverage_bias_2010_by_month$subFonte)
# 
# estadao = coverage_bias_2010_by_month %>% filter(subFonte == "ESTADAO")
# estadao_in_10 = significant_difference_inside_outlet(estadao)
# 
# folhasp = coverage_bias_2010_by_month %>% filter(subFonte == "FOLHASP")
# folhasp_in_10 = significant_difference_inside_outlet(folhasp)
# 
# carta = coverage_bias_2010_by_month %>% filter(subFonte == "CartaCapital")
# carta_in_10 = significant_difference_inside_outlet(carta)
# 
# veja = coverage_bias_2010_by_month %>% filter(subFonte == "VEJA")
# veja_in_10 = significant_difference_inside_outlet(veja)
# 
# across_10 = significant_difference_across_outlets(coverage_bias_2010_by_month)
# 
# # Correlation between coverage across outlets
# library(reshape2)
# library(corrr)
# 
# coverage_bias_by_month = bind_rows(coverage_bias_2010_by_month, coverage_bias_2014_by_month, coverage_bias_2018_by_month)
# coverage_bias_by_month_cast = coverage_bias_by_month %>% select(-n_of_entity, -actual, -total) %>% dcast(mes + year + entity + entity_type ~ subFonte, value.var = "cb")
# 
# coverage_bias_by_month_cast_party = coverage_bias_by_month_cast %>% filter(entity_type == "party") %>% select(-mes, -entity, -entity_type)
# coverage_bias_by_month_cast_candidate = coverage_bias_by_month_cast %>% filter(entity_type == "candidate") %>% select(-mes, -entity, -entity_type)
# 
# cor_candidates_2018 = coverage_bias_by_month_cast_candidate %>% filter(year == 2018) %>% select(-year) %>% correlate(method = "spearman") %>% melt(na.rm = T) %>% mutate(entidade = "candidato", ano = 2018)
# cor_candidates_2014 = coverage_bias_by_month_cast_candidate %>% filter(year == 2014) %>% select(-year) %>% correlate(method = "spearman") %>% melt(na.rm = T) %>% mutate(entidade = "candidato", ano = 2014)
# cor_candidates_2010 = coverage_bias_by_month_cast_candidate %>% filter(year == 2010) %>% select(-year) %>% correlate(method = "spearman") %>% melt(na.rm = T) %>% mutate(entidade = "candidato", ano = 2010)
# 
# cor_parties_2018 = coverage_bias_by_month_cast_party %>% filter(year == 2018) %>% select(-year) %>% correlate(method = "spearman") %>% melt(na.rm = T) %>% mutate(entidade = "partido", ano = 2018)
# cor_parties_2014 = coverage_bias_by_month_cast_party %>% filter(year == 2014) %>% select(-year) %>% correlate(method = "spearman") %>% melt(na.rm = T) %>% mutate(entidade = "partido", ano = 2014)
# cor_parties_2010 = coverage_bias_by_month_cast_party %>% filter(year == 2010) %>% select(-year) %>% correlate(method = "spearman") %>% melt(na.rm = T) %>% mutate(entidade = "partido", ano = 2010)
