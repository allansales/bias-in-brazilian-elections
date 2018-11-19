library(mongolite)
library(tm)
library(dplyr)
library(ggplot2)
library(stringr)
library(lubridate)
library(anytime)
library(RMongo)

get_collection <- function(colecao, query = "{}"){
  con <- mongo(db = "stocks", collection = colecao, url = "mongodb://localhost", verbose = FALSE, options = ssl_options())
  data <- con$find(query)
  rm(con)
  return(data)
}

get_docs_by_idNoticia <- function(vetor_ids, colecao){
  mongo = mongoDbConnect("stocks")
  idNoticias = paste(vetor_ids, collapse = "\",\"")
  query = sprintf('{"idNoticia": { "$in": ["%s"]} }', idNoticias)
  output = dbGetQuery(mongo, colecao, query, skip=0, limit=Inf)
  rm(mongo)
  return(output)
}

get_todas_noticias_originais <- function(){
  g1_noticias <- get_collection("g1Noticias")
  folha_noticias <- get_collection("folhaNoticias")
  estadao_noticias <- get_collection("estadaoNoticias")
  
  noticias <- bind_rows(g1_noticias, folha_noticias, estadao_noticias)
  anos_eleicao <- c(2010,2012,2014,2016)
  noticias <- noticias %>% mutate(data = utcdate(timestamp), repercussao = as.integer(repercussao), 
                                  ano = year(data), mes = month(data, label=T, abbr=T), dia = day(data), dia_do_ano = yday(data),
                                  is_ano_eleicao = if_else(ano %in% anos_eleicao, TRUE, FALSE))
  
  n_palavras <- noticias %>% select(conteudo) %>% 
    unlist() %>% as.vector() %>% 
    tolower() %>% str_count(" ")+1
  
  noticias <- cbind(noticias, n_palavras)
  
  return(noticias)  
}

get_todas_noticias_processadas <- function(){
  folha_noticias <- get_collection("folhaNoticiasProcessadas")
  estadao_noticias <- get_collection("estadaoNoticiasProcessadas")
  g1_noticias <- get_collection("g1NoticiasProcessadas")

  noticias <- bind_rows(folha_noticias, estadao_noticias, g1_noticias)
  
  return(noticias)
}

get_todos_comentarios <- function(){
  g1_comentarios <- get_collection("g1ComentariosProcessados")
  folha_comentarios <- get_collection("folhaComentariosProcessados")
  estadao_comentarios <- get_collection("estadaoComentariosProcessados")
  
  comentarios <- bind_rows(g1_comentarios, folha_comentarios, estadao_comentarios)
  
  return(comentarios)  
}

insert_in_database <- function(colecao, nome){
  con <- mongo(db = "stocks", collection = nome, url = "mongodb://localhost", verbose = FALSE, options = ssl_options())
  con$insert(colecao)
  rm(con)
}

get_comentarios_por_noticias = function(noticias, data_ini = NULL, data_fim = NULL, database = NULL){
  noticias = noticias_eleicao_folha
  database = "folhaComentariosProcessados"
  noticias = noticias %>% select(idNoticia, data, subFonte)
  
  get_comentarios = function(database){
    if(is.null(database)){
     return(get_todos_comentarios())
    }
    return(get_collection(database))
  }
  
  comentarios = get_comentarios(database)
  names(comentarios)[names(comentarios) == 'comentario'] <- 'conteudo'
  names(comentarios)[names(comentarios) == 'comentario_processado'] <- 'conteudo_processado'
  comentarios = comentarios %>% filter(idNoticia %in% noticias$idNoticia) 
  comentarios = comentarios %>% inner_join(noticias, by="idNoticia")
  comentarios = comentarios %>% mutate(subFonte = paste("Comentario",subFonte,sep="-"))
  return(comentarios)
}
