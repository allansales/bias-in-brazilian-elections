library(stringr)
library(purrr)

padroniza_emissor <- function(col){
  tolower(col) %>% 
    str_split("[*,/-]") %>%
    map(1) %>% 
    unlist()
}

noticias_tema <- function(data, pattern, secao, get_from_pattern = T){
  true_false_vector <- data %>% select(secao) %>% 
    unlist() %>% as.vector() %>% 
    tolower() %>% str_detect(pattern)
  
  if(get_from_pattern){
    noticias <- data %>% filter(true_false_vector == TRUE)
  } else {
    noticias <- data %>% filter(true_false_vector == FALSE)
  }
  
  return(noticias)
}

# cria arquivo com todas as noticias
build_corpus <- function(conteudo){
  texto <- Corpus(VectorSource(conteudo))
  texto <- tm_map(texto, tolower)
  #texto <- tm_map(texto, stemDocument, language="pt")
  texto <- tm_map(texto, removePunctuation, preserve_intra_word_dashes = TRUE)
  texto <- tm_map(texto, removeWords, stopwords("pt"))
  texto <- tm_map(texto, removeNumbers)
  texto <- tm_map(texto, stripWhitespace)
  texto <- tm_map(texto, PlainTextDocument)
  texto <- paste(strwrap(texto[[1]]), collapse = " ")
  return(texto)
}

gera_tabela_frequencias <- function(texto){
  
  texto <- Corpus(VectorSource(texto))
  texto <- tm_map(texto, tolower)
  texto <- tm_map(texto, removePunctuation, preserve_intra_word_dashes = TRUE)
  texto <- tm_map(texto, removeWords, stopwords("pt"))
  texto <- tm_map(texto, removeNumbers)
  texto <- tm_map(texto, stripWhitespace)
  texto <- tm_map(texto, stemDocument)
  texto <- tm_map(texto, PlainTextDocument)
  
  
  dtm <- TermDocumentMatrix(texto)
  matriz <- as.matrix(dtm)
  vector <- sort(rowSums(matriz),decreasing=TRUE)
  data <- data.frame(word = names(vector),freq=vector)
  
  return(data)
}