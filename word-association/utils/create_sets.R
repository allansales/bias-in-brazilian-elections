library("udpipe")
library("wordVectors")
library("textstem")

filtra_palavras_por_morfologia = function(palavras_mais_similares, base_tema){
  get_uma_noticia <- function(word){
    noticia = base_tema %>% noticias_tema(word, "conteudo_processado") %>% slice(sample(1:n(), 1))
    if(nrow(noticia)==0){
      return("") #no caso de nao encontrar noticias com a palavra que esta sendo procurada
    }
    return(noticia$conteudo_processado)
  }
  
  noticias = palavras_mais_similares %>% rowwise() %>% mutate(noticia = get_uma_noticia(word))
  
  morfo_obj = c("NOUN","PROPN","ADJ")
  morfo = udpipe_annotate(ud_model, x = noticias$noticia) %>% 
    as.data.frame() %>% 
    filter(tolower(token) %in% noticias$word, upos %in% morfo_obj)
  
  palavras_filtradas = morfo$token %>% tolower() %>% unique()
  pmsf = palavras_mais_similares %>% filter(word %in% palavras_filtradas)
  return(pmsf)
}

load_we = function(base_tema, path_saida, analogias, respostas, tema = "", sufix = "", tema_out = F){
  if(tema_out!=F){
    base_tema = base_tema %>% noticias_tema(tema_out, campo, get_from_pattern = F)
  }
  
  cols = colnames(base_tema)
  if("subFonte" %in% cols){
    subFonte = base_tema$subFonte %>% unique()
  } else {
    subFonte = "comentario"
  }
  
  max_date = max(base_tema$data)
  min_date = min(base_tema$data)
  
  if(tema!=""){
    file_name = paste(tema,subFonte,max_date,min_date,sep="-")  
  } else {
    file_name = paste(subFonte,max_date,min_date,sep="-")  
  }
  
  if(sufix!=""){
    file_name = paste(file_name,sufix,sep="-")  
  } 
  
  f = paste0(path_saida,file_name,".bin")
#  if(file.exists(f)){
#    we = read.binary.vectors(f)
#  } else {
    we_base = cria_word_embedding(file_name, n_layers, analogias, respostas, base_tema, campo, path_saida)
#    we = we_base[[1]]
#  }

  return(we_base) 
}

get_words_tema <- function(we, tema, n_prox){
  
  palavras_similares = wordVectors::closest_to(we, we[[tema]], n=n_prox)
  colnames(palavras_similares) <- c("word", "similarity")
  return(palavras_similares)
}

filtra_palavras_por_distancia <- function(similaridade_palavras, min_palavras){
  sim = similaridade_palavras$similarity[min_palavras:nrow(similaridade_palavras)]
  sim_dif = sim[-length(sim)] - sim[-1]
  max_dif = max(sim_dif) #maior diferenca
  add_pos = which(sim_dif == max_dif)
  pos = min_palavras+(add_pos-1)
  palavras_filtradas = similaridade_palavras %>% slice(1:pos)
  return(palavras_filtradas)
}

cria_conjunto_de_entidade <- function(tema, base, campo, min_palavras, we, path_saida = "embeddings/", n_palavras_prox = 200){
  
  base_tema = base %>% noticias_tema(tema, campo)
 
  palavras_similares = get_words_tema(we, tema, n_palavras_prox)
  palavras_fil_morfo = filtra_palavras_por_morfologia(palavras_similares, base_tema)
  palavras_escolhidas = filtra_palavras_por_distancia(palavras_fil_morfo, min_palavras)
  
  return(palavras_escolhidas)
}

we_contem_palavra = function(tabela, we){
  palavras_we = attr(we@.Data, "dimnames")[[1]]
  palavras = tabela$word  
  palavras_contidas = palavras[palavras %in% palavras_we]
  tabela %>% filter(tabela$word %in% palavras_contidas)
}

conjuntos_mesmo_tamanho = function(list_of_vector_words){
  n = sapply(list_of_vector_words,length) %>% min()
  l = lapply(list_of_vector_words, function(x) x[1:n])
  return(l)
}

trata_palavras_em_comum = function(tabela_similaridade_a, tabela_similaridade_b){
  
  remove_palavras_conjunto = function(tabela_similaridade, palavras_em_comum, para_manter){
    palavras_remover = palavras_em_comum %>% filter(conjunto != para_manter)  
    tabela_similaridade = tabela_similaridade %>% filter(!(stemmed %in% palavras_remover$stemmed))
    return(tabela_similaridade)
  }

  tabela_similaridade_a$stemmed = stem_words(tabela_similaridade_a$word, language = "pt")
  tabela_similaridade_b$stemmed = stem_words(tabela_similaridade_b$word, language = "pt")
  
  palavras_em_comum = inner_join(tabela_similaridade_a, tabela_similaridade_b, by="stemmed")
  colnames(palavras_em_comum) = c("word_a", "a", "stemmed", "word_b", "b")
  
  #se o valor absoluto for menor que um parametro, exclui palavra dos dois conjuntos. se for maior, coloca no conjunto a ou b.
  palavras_em_comum = palavras_em_comum %>% mutate(dif = a - b, conjunto = if_else(abs(dif)<0.1, "exclude", if_else(dif > 0, "a", "b")))
  
  tabela_similaridade_a = remove_palavras_conjunto(tabela_similaridade_a, palavras_em_comum, "a")
  tabela_similaridade_b = remove_palavras_conjunto(tabela_similaridade_b, palavras_em_comum, "b")
  
  return(list(tabela_similaridade_a,tabela_similaridade_b))
}

conjuntos_genericos = function(we_fonte, we_alvo, palavra_1, palavra_2, n_palavras){
  
  palavras_contidas_a = closest_to(we_fonte, we_fonte[[palavra_1]], 200) %>% 
    we_contem_palavra(we_alvo)
  
  palavras_contidas_b = closest_to(we_fonte, we_fonte[[palavra_2]], 200) %>% 
    we_contem_palavra(we_alvo)
  
  palavras_conjuntos = trata_palavras_em_comum(palavras_contidas_a, palavras_contidas_b)
  palavras_a = palavras_conjuntos[[1]]
  palavras_b = palavras_conjuntos[[2]]
  
  palavras_a = filtra_palavras_por_distancia(palavras_a, n_palavras)
  palavras_b = filtra_palavras_por_distancia(palavras_b, n_palavras)
  
  palavras = conjuntos_mesmo_tamanho(list(palavras_a$word, palavras_b$word))
  
  return(list(a=palavras[[1]], b=palavras[[2]]))
}

palavras_em_comum_conjuntos_genericos <- function(we_fonte, documentos_alvo_1, documentos_alvo_2, palavra_1, palavra_2, min_atributos, sufix_1, sufix_2, path_saida = "embeddings/"){
  
  we_alvo_1 = load_we(documentos_alvo_1, path_saida, sufix = sufix_1)
  we_alvo_2 = load_we(documentos_alvo_2, path_saida, sufix = sufix_2)
  
  conjuntos_alvo_1 = cria_conjuntos_genericos(we_fonte, we_alvo_1, palavra_1, palavra_2, min_atributos)
  conjuntos_alvo_2 = cria_conjuntos_genericos(we_fonte, we_alvo_2, palavra_1, palavra_2, min_atributos)
  
  alvo_1_a = conjuntos_alvo_1$a
  alvo_1_b = conjuntos_alvo_1$b
  
  alvo_2_a = conjuntos_alvo_2$a
  alvo_2_b = conjuntos_alvo_2$b
  
  palavras_a = intersect(alvo_1_a, alvo_2_a)
  palavras_b = intersect(alvo_1_b, alvo_2_b)
  
  palavras = conjuntos_mesmo_tamanho(list(palavras_a, palavras_b))
  
  return(list(a=palavras[[1]], b=palavras[[2]]))
}
