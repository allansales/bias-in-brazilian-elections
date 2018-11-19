library(mongolite)
library(tm)
library(dplyr)
library(ggplot2)
library(stringr)
library(lubridate)
library(anytime)
library(RMongo)

get_collection <- function(colecao, query = "{}", db = "stocks"){
  con <- mongo(db, collection = colecao, url = "mongodb://localhost", verbose = FALSE, options = ssl_options())
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

get_todas_noticias_originais <- function(db){
  g1_noticias <- get_collection("g1Noticias", db = db)
  folha_noticias <- get_collection("folhaNoticias", db = db)
  estadao_noticias <- get_collection("estadaoNoticias", db = db)
  
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

get_todas_noticias_processadas <- function(db){
  folha_noticias <- get_collection("folhaNoticiasProcessadas", db = db)
  estadao_noticias <- get_collection("estadaoNoticiasProcessadas", db = db)
  g1_noticias <- get_collection("g1NoticiasProcessadas", db = db)

  noticias <- bind_rows(folha_noticias, estadao_noticias, g1_noticias)
  
  return(noticias)
}

get_todos_comentarios <- function(db){
  g1_comentarios <- get_collection("g1ComentariosProcessados", db = db)
  folha_comentarios <- get_collection("folhaComentariosProcessados", db = db)
  estadao_comentarios <- get_collection("estadaoComentariosProcessados", db = db)
  
  comentarios <- bind_rows(g1_comentarios, folha_comentarios, estadao_comentarios)
  
  return(comentarios)  
}

insert_in_database <- function(colecao, nome, db = "stocks"){
  con <- mongo(db, collection = nome, url = "mongodb://localhost", verbose = FALSE, options = ssl_options())
  con$insert(colecao)
  rm(con)
}

get_comentarios_por_noticias = function(noticias, data_ini = NULL, data_fim = NULL, database = NULL){
  noticias = noticias %>% select(idNoticia, data, subFonte)
  
  get_comentarios = function(database){
    if(is.null(database)){
     return(get_todos_comentarios())
    }
    return(get_collection(database))
  }
  
  comentarios = get_comentarios(database)
  comentarios = comentarios %>% filter(idNoticia %in% noticias$idNoticia) %>% rename(conteudo = comentario)
  if("comentario_processado" %in% colnames(comentarios)){
    comentarios = comentarios %>% rename(conteudo_processado = comentario_processado)  
  }
  comentarios = comentarios %>% inner_join(noticias, by="idNoticia")
  comentarios = comentarios %>% mutate(subFonte = paste("Comentario",subFonte,sep="-"))
  return(comentarios)
}
