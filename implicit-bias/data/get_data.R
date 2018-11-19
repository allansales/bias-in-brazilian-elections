library("readr")
library("dplyr")
library("tm")
library("stringr")

# Import data
data_folha_carta = read_csv("./../../lexicons-based-bias/data/raw_data/raw_noticias_carta_2010-2018_folha_2018.csv", col_names = T)
data_estadao = read_csv("./../../lexicons-based-bias/data/raw_data/raw_noticias_estadao_2018.csv", col_names = T) 

estadao_2018 = data_estadao %>% filter(subFonte == "ESTADAO", ano == 2018) %>% select(conteudo)
folha_2018 = data_folha_carta %>% filter(subFonte == "FOLHASP", ano == 2018) %>% select(conteudo)
carta_2018 = data_folha_carta %>% filter(subFonte == "CartaCapital", ano == 2018) %>% select(conteudo)

# Remove accents, punctuation and put it lower case
process_data = function(data){
  #data = folha_2018$conteudo
  processed_content = iconv(data, from="UTF-8", to="ASCII//TRANSLIT")
  processed_content = processed_content %>% tolower()
  processed_content = gsub("[^[:alnum:][:space:]]", "", processed_content)
  processed_content = removeWords(processed_content, stopwords("pt-br"))
  processed_content = str_squish(processed_content)
  processed_content = processed_content %>% as_data_frame() 
}

estadao_2018 = process_data(estadao_2018$conteudo)
carta_2018 = process_data(carta_2018$conteudo)
folha_2018 = process_data(folha_2018$conteudo)

write_csv(estadao_2018, "2018/noticias_estadao/noticias_eleicao_estadao.csv", col_names = F)
write_csv(carta_2018, "2018/noticias_carta/noticias_eleicao_carta.csv", col_names = F)
write_csv(folha_2018, "2018/noticias_folha/noticias_eleicao_folha.csv", col_names = F)